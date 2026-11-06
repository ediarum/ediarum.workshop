#!/usr/bin/env bash
# Fetch the services' build sources (the *_BUILD settings in sources.env) that are git URLs,
# with the user's own git login, into .sources/<repo>/, and print NAME=<local folder> for each.
# start.sh exports these, so Docker builds from local folders and never has to log in itself.
# Paths are left out: compose uses them as they are.
#
#   scripts/fetch-services.sh    → e.g. INDEX_FRONTEND_BUILD=/…/.sources/ediarum.index/frontend
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/fetch.sh

sed -n 's/^\([A-Z_]*_BUILD\)=\(.*\)$/\1 \2/p' sources.env | while read -r name value; do
    case "$value" in
        *://*|git@*) ;;
        *) continue ;;
    esac
    # <url>#<ref>[:<subfolder>]
    url="${value%%#*}"
    fragment="${value#*#}"
    ref="${fragment%%:*}"
    sub=""
    [ "$ref" = "$fragment" ] || sub="/${fragment#*:}"
    repo="$(basename "$url" .git)"
    dir="$(fetch "$repo" "$url#$ref")"
    echo "$name=$dir$sub"
done
