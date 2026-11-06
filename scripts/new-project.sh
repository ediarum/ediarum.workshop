#!/usr/bin/env bash
# Add an extra, empty project to the running workshop stack: the terminal steps before and after
# creating it in the WebDAV app. See NEW-PROJECT.md. Linux, macOS; Windows: in Git Bash.
#
#   scripts/new-project.sh <slug> <id-prefix> ["Project name"] [--repo URL [--user NAME]] [--branch BRANCH]
#
#   scripts/new-project.sh demo D "Demo edition"
#       a repository on the workshop's own git server, git://gitserver/demo.git
#   scripts/new-project.sh demo D "Demo edition" --repo https://gitlab.com/me/demo.git
#       your own repository (GitLab, GitHub, …); asks for an access token (or takes $GIT_TOKEN)
#
# 1. the repository: created on the workshop's git server, or your own one checked (a branch with a
#    data/ folder; offers to push them if missing), its token stored for fileservice
# 2. the project's id prefix in config/id/projects.toml (ediarum.id serves no project without)
# 3. waits while you create the project in the WebDAV app
# 4. restarts fileservice (clones the new project), ediarum.id and ediarum.index (pick it up)
# Safe to run again for the same project.
set -euo pipefail
cd "$(dirname "$0")/.."

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[31m%s\033[0m\n' "$*" >&2; exit 1; }
setting() { sed -n "s/^$1=//p" workshop.env | head -1; }
# MSYS_NO_PATHCONV: Git Bash would turn container paths (/data/xml/…) into C:/Program Files/Git/…
compose() { MSYS_NO_PATHCONV=1 docker compose --env-file workshop.env --env-file sources.env "$@"; }
usage="usage: scripts/new-project.sh <slug> <id-prefix> [\"Project name\"] [--repo https://… [--user NAME]] [--branch BRANCH]"

# --- arguments -------------------------------------------------------------------------------------
args=(); repo=""; user="oauth2"; branch="main"
while [ $# -gt 0 ]; do
    case "$1" in
        --repo)   repo="${2:?$usage}"; shift 2 ;;
        --user)   user="${2:?$usage}"; shift 2 ;;
        --branch) branch="${2:?$usage}"; shift 2 ;;
        -h|--help) echo "$usage"; exit 0 ;;
        -*) fail "unknown option $1. $usage" ;;
        *) args+=("$1"); shift ;;
    esac
done
slug="${args[0]:-}"; prefix="${args[1]:-}"; name="${args[2]:-$slug}"
[ -n "$slug" ] && [ -n "$prefix" ] || fail "$usage"
[[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] \
    || fail "'$slug': the slug takes lowercase letters and digits, words joined by '-' (as webdav requires)."
[[ "$prefix" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]] || fail "'$prefix': the id prefix must start with a letter."
[ "$slug" != "$(setting PROJECT)" ] || fail "'$slug' is the workshop project itself."
if [ -n "$repo" ]; then
    # webdav adds the token to https:// URLs only
    [[ "$repo" =~ ^https://[^/@]+/.+ ]] \
        || fail "'$repo': give the repository's https:// address, without user name or token in it."
else
    repo="git://gitserver/$slug.git"
    [ "$branch" = main ] || fail "--branch goes with --repo (the workshop's git server uses main)."
fi

PORT="$(setting PORT)"
TOKEN="$(setting PLATFORM_SERVICE_TOKEN)"
compose ps --status running --services 2>/dev/null | grep -qx proxy || fail "The stack isn't running: ./start.sh first."

# --- 1. the repository -------------------------------------------------------------------------------
if [[ "$repo" == git://gitserver/* ]]; then
    say "1. Git repository $repo …"
    compose exec -T gitserver new-repo "$slug"
    form_user="workshop"
    form_token="workshop   (required by the form, not used)"
else
    say "1. Your repository $repo …"
    command -v git >/dev/null || fail "git is needed to check the repository."
    git_token="${GIT_TOKEN:-}"
    if [ -z "$git_token" ]; then
        read -r -s -p "  Access token for $repo (user '$user'): " git_token; echo
    fi
    [ -n "$git_token" ] || fail "No token given."

    # git asks GIT_ASKPASS for the user name and the password: the token stays out of URLs and files
    # as C:/… in Git Bash (pwd -W): git runs the askpass helper from there
    tmp="$(cd "$(mktemp -d)" && { pwd -W 2>/dev/null || pwd; })"; trap 'rm -rf "$tmp"' EXIT
    cat > "$tmp/askpass" <<'SH'
#!/bin/sh
case "$1" in Username*) printf '%s\n' "$NP_GIT_USER" ;; *) printf '%s\n' "$NP_GIT_TOKEN" ;; esac
SH
    chmod 700 "$tmp/askpass"
    rgit() {
        NP_GIT_USER="$user" NP_GIT_TOKEN="$git_token" GIT_ASKPASS="$tmp/askpass" GIT_TERMINAL_PROMPT=0 \
            git -c credential.helper= -c user.name=ediarum.workshop -c user.email=workshop@example.org "$@"
    }

    heads="$(rgit ls-remote --heads "$repo" 2>"$tmp/err")" || {
        sed 's/^/  /' "$tmp/err" >&2
        fail "Can't read $repo with that token. Check the address, the user name (--user; GitHub and GitLab deploy tokens need theirs) and the token's rights: GitLab read_repository + write_repository, GitHub Contents read and write."
    }
    has_branch=0; has_data=0
    if grep -q "[[:space:]]refs/heads/$branch\$" <<< "$heads"; then
        has_branch=1
        rgit clone -q --depth 1 --branch "$branch" --no-checkout "$repo" "$tmp/repo"
        [ -n "$(git -C "$tmp/repo" ls-tree HEAD data)" ] && has_data=1
    fi
    if [ "$has_branch" = 1 ] && [ "$has_data" = 1 ]; then
        echo "  branch $branch with a data/ folder: fine"
    else
        what="$([ "$has_branch" = 1 ] && echo "a data/ folder on branch $branch" || echo "branch $branch with an empty data/ folder")"
        echo "  webdav needs the branch $branch with a top-level data/ folder; the repository has none."
        read -r -p "  Push $what to $repo now? [y/N] " answer
        [[ "$answer" =~ ^[yYjJ] ]] || fail "Nothing pushed. Add $what to the repository, then run this script again."
        if [ "$has_branch" = 0 ]; then
            git init -q -b "$branch" "$tmp/repo"
        else
            git -C "$tmp/repo" checkout -q "$branch"
        fi
        mkdir -p "$tmp/repo/data" && : > "$tmp/repo/data/.gitkeep"
        git -C "$tmp/repo" add data/.gitkeep
        rgit -C "$tmp/repo" commit -q -m "Add the data folder for ediarum.webdav"
        rgit -C "$tmp/repo" push -q "$repo" "HEAD:refs/heads/$branch" \
            || fail "The push failed: the token needs write access (GitLab write_repository, GitHub Contents write); a protected branch may refuse it."
        echo "  pushed"
    fi

    # fileservice clones with these (its git credential helper reads secrets/git_token)
    if [ -s secrets/git_token ] && [ "$(cat secrets/git_token)" != "$git_token" ]; then
        echo "  Note: replacing the token in secrets/git_token. fileservice has one token for every"
        echo "  repository: a project added earlier with another token can't be read with this one."
    fi
    (umask 077; printf '%s' "$git_token" > secrets/git_token; printf 'GIT_TOKEN_USER=%s\n' "$user" > secrets/git.env)
    echo "  token stored for fileservice in secrets/ (git-ignored)"
    form_user="$user"
    form_token="the same token"
fi

# --- 2. id prefix ------------------------------------------------------------------------------------
say "2. Id prefix in config/id/projects.toml …"
if grep -q "^\[$slug\]" config/id/projects.toml; then
    echo "  [$slug] is there already"
else
    printf '\n[%s]\nlabel = "%s"\nprefix = "%s"\n' "$slug" "${name//\"/\\\"}" "$prefix" >> config/id/projects.toml
    echo "  added [$slug] prefix = \"$prefix\""
fi

# --- 3. the WebDAV app -------------------------------------------------------------------------------
say "3. Now create the project in the WebDAV app"
cat <<TEXT
  http://localhost:$PORT/ → WebDAV → Manage Projects → Create New Project:
    Project Name                  $name
    Slug                          $slug
    Git Remote URL                $repo
    Git Username                  $form_user
    Git Personal Access Token     $form_token
    Tracked Git Branch            $branch
  → Initialize Project, wait until the log says it's done, OK.
  Then, on the project's page:
    Edit → tick "Push to ediarum services?" and "Index app is the source of truth?" → save
    Users → choose Workshop → Add User
TEXT
read -r -p $'\nPress Enter when that is done … '

# Laravel writes "/" as "\/" in JSON
entry="$(curl -fsS -H "Authorization: Bearer $TOKEN" "http://localhost:$PORT/api/auth/service/projects" \
    | sed 's#\\/#/#g' | grep -o "{[^}]*\"slug\":\"$slug\"[^}]*}" || true)"
[ -n "$entry" ] || fail "webdav doesn't list a project '$slug'. Check the slug in the WebDAV app, then run this script again."
grep -qF "\"repo_url\":\"$repo\"" <<< "$entry" \
    || fail "'$slug' has another Git Remote URL in the WebDAV app than $repo. Correct it (Edit), then run this script again."
grep -q '"index_source_of_truth":"app"' <<< "$entry" \
    || fail "'$slug' isn't app-led yet: Edit → \"Index app is the source of truth?\", then run this script again."

# --- 4. the services pick the project up ------------------------------------------------------------
say "4. Restarting fileservice (clones $slug), ediarum.id and ediarum.index …"
# recreated if secrets/git.env changed, restarted otherwise
compose up -d --no-deps --force-recreate --wait fileservice
for _ in $(seq 60); do
    compose exec -T fileservice test -d "/data/xml/$slug/.git" && break
    sleep 2
done
compose exec -T fileservice test -d "/data/xml/$slug/.git" \
    || fail "fileservice didn't clone $slug: compose logs fileservice (was the project initialized? can the token read it?)."
# id-api reads projects.toml on start; the watcher and index-api read the projects on start
compose restart id-api
compose up -d --wait id-api
compose restart id-watcher index-api
compose up -d --wait id-watcher index-api

curl -fsS "http://localhost:$PORT/api/id/projects" | grep -q "\"name\":\"$slug\"" \
    || fail "ediarum.id doesn't serve $slug: compose logs id-api."

say "Project $slug is ready."
cat <<TEXT

  Index app             http://localhost:$PORT/ → Index → $name
  WebDAV for oXygen     http://localhost:$PORT/webdav/connection/$slug/
  oXygen                Options → Preferences → Editor Variables (Project Options):
                          ediarum_project_name   $(setting PROJECT) → $slug
                          ediarum_id             /api/id/$(setting PROJECT)/ → /api/id/$slug/
TEXT
