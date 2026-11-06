#!/usr/bin/env bash
# Release: point GENERATED_URL (sources.env) at the new tag's GitHub release, commit, tag
# vX.Y.Z (annotated) and push to GitLab. Then publish it to the public GitHub repository as
# one snapshot commit, tagged vX.Y.Z there too (scripts/publish.sh); GitHub Actions builds
# workshop-generated.tar.gz and the release. NO_GITHUB=1 skips GitHub.
#
#   scripts/release.sh patch    0.1.1 → 0.1.2
#   scripts/release.sh minor    0.1.1 → 0.2.0
#   scripts/release.sh major    0.1.1 → 1.0.0
#
# The current version is the highest vX.Y.Z tag (tags like v0.0.1-test don't count; none:
# 0.0.0). Refuses unless on main, with a clean tree, level with origin/main, and the tag
# doesn't exist yet, and — before anything changes — unless the snapshot for GitHub passes
# publish.sh's checks. Asks once before committing and pushing.
set -euo pipefail

PUBLIC_REPO=https://github.com/ediarum/ediarum.workshop

bump="${1:-}"
case "$bump" in
  patch|minor|major) ;;
  *) echo "usage: $0 patch|minor|major" >&2; exit 2 ;;
esac

die() { echo "release: $*" >&2; exit 1; }

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

[ "$(git symbolic-ref --short HEAD)" = main ] || die "not on main"
[ -z "$(git status --porcelain)" ] || die "uncommitted changes"
git fetch -q origin main --tags
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || die "main differs from origin/main (pull or push first)"

current="$(git tag -l 'v*' | { grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' || true; } | sed 's/^v//' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
current="${current:-0.0.0}"
IFS=. read -r major minor patch <<< "$current"
case "$bump" in
  patch) patch=$((patch + 1)) ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  major) major=$((major + 1)); minor=0; patch=0 ;;
esac
next="$major.$minor.$patch"
tag="v$next"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag exists already"
url="$PUBLIC_REPO/releases/download/$tag/workshop-generated.tar.gz"

echo "$(basename "$PWD"): $current → $next, tag $tag"

# GENERATED_URL changes in the release commit: check a throwaway commit (HEAD with the new
# sources.env, on no branch) so publish.sh sees what will be released.
check_commit() {
  local index blob tree
  index="$(mktemp)"
  blob="$(git show HEAD:sources.env | sed "s#^GENERATED_URL=.*#GENERATED_URL=$url#" | git hash-object -w --stdin)"
  GIT_INDEX_FILE="$index" git read-tree HEAD
  GIT_INDEX_FILE="$index" git update-index --cacheinfo "100644,$blob,sources.env"
  tree="$(GIT_INDEX_FILE="$index" git write-tree)"
  rm -f "$index"
  git commit-tree "$tree" -p HEAD -m "release check"
}
where=" to GitLab"
if [ -z "${NO_GITHUB:-}" ]; then
  scripts/publish.sh --check "$next" "$(check_commit)" || die "not publishable to GitHub (NO_GITHUB=1 skips GitHub)"
  where=" to GitLab, then GitHub"
fi
echo "Is the pipeline for main green?"
read -r -p "Commit, tag and push$where? [y/N] " answer
[ "$answer" = y ] || [ "$answer" = Y ] || die "aborted, nothing changed"

sed -i "s#^GENERATED_URL=.*#GENERATED_URL=$url#" sources.env
git add sources.env
git commit -q -m "release $tag"
git tag -a "$tag" -m "$tag"
git push -q --follow-tags origin main

echo "pushed $tag to GitLab"

[ -z "${NO_GITHUB:-}" ] || exit 0
scripts/publish.sh --yes "$next" \
  || die "$tag is released on GitLab, but not on GitHub; retry with: scripts/publish.sh $next"
