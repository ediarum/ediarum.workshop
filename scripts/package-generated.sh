#!/usr/bin/env bash
# CI side: pack the folders scripts/prepare.sh built into dist/workshop-generated.tar.gz, the
# file start.sh downloads from GENERATED_URL (sources.env).
#
#   scripts/package-generated.sh [<tag>]
#
# With a tag (a release), GENERATED_URL must point at that tag's file, so the scripts in the
# release download the data built with them.
set -euo pipefail
cd "$(dirname "$0")/.."

project="$(sed -n 's/^PROJECT=//p' workshop.env | head -1)"
[ -d "dataset/$project/data" ] && [ -f oxygen/workshop.xpr ] \
    || { echo "package: run scripts/prepare.sh first" >&2; exit 1; }

if [ -n "${1:-}" ]; then
    url="$(sed -n 's/^GENERATED_URL=//p' sources.env | head -1)"
    case "$url" in
        */"$1"/workshop-generated.tar.gz) ;;
        *) echo "package: GENERATED_URL in sources.env ('$url') must end in /$1/workshop-generated.tar.gz" >&2
           exit 1 ;;
    esac
fi

mkdir -p dist
tar -czf dist/workshop-generated.tar.gz dataset oxygen
ls -l dist/workshop-generated.tar.gz
