#!/bin/sh
# Create the bare repository /srv/git/<slug>.git with a single commit on `main`.
#
#   new-repo <slug> [DIR]
#
# With DIR, the commit holds a copy of DIR (the entrypoint passes the dataset). Without, it holds
# an empty `data/` folder only (data/.gitkeep): the least webdav's "Initialize" accepts (it needs
# the branch and a top-level data/ folder). Does nothing if the repository exists already.
set -eu
slug="${1:?usage: new-repo <slug> [DIR]}"
src="${2:-}"
repo="/srv/git/${slug}.git"

if [ -d "$repo" ]; then
    echo "gitserver: $repo exists already"
    exit 0
fi

echo "gitserver: creating $repo${src:+ from $src}"
work=$(mktemp -d)
if [ -n "$src" ]; then
    # not -a: the files would keep the host's owner, which git (root here) refuses
    cp -R "$src/." "$work/"
else
    mkdir "$work/data"
    : > "$work/data/.gitkeep"
fi
git -C "$work" init -q -b main
git -C "$work" add -A
git -C "$work" -c user.name=workshop -c user.email=workshop@example.org \
    commit -q -m "$([ -n "$src" ] && echo 'Workshop dataset' || echo 'Empty project')"
git clone -q --bare "$work" "$repo"
rm -rf "$work"
# fileservice clones partially (--filter=blob:none) and fetches blobs on demand.
git -C "$repo" config uploadpack.allowFilter true
git -C "$repo" config uploadpack.allowAnySHA1InWant true
