#!/usr/bin/env bash
# Trainer side: build the two generated folders the stack and oXygen need, from the sources
# named in sources.env. start.sh runs this when one of them is missing.
#
#   dataset/avhr/   scripts/make-dataset.py   from DATA_SOURCE (+ DATA_LETTERS)
#   oxygen/         scripts/make-oxygen.py    from BASE_EDIT_SOURCE, with workshop.env's settings
#
# A source that is a git URL (…#<tag, branch or commit>) is fetched into .sources/<name>/ and
# reused while its ref stays the same. Needs git and Python 3.9 or newer.
#
#   scripts/prepare.sh [extra arguments for make-oxygen.py]
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
cd "$here"

setting() { sed -n "s/^$1=//p" sources.env | head -1; }

# fetch NAME SOURCE [SPARSE-PATH …] → prints the folder to use
source scripts/fetch.sh

data="$(fetch data "$(setting DATA_SOURCE)" /data/index/ /data/letter/ /README.md)"
base="$(fetch base-edit "$(setting BASE_EDIT_SOURCE)")"

# python3 on Linux and macOS; on Windows often python or py (python3 there may be the Store's stub)
python=""
for candidate in python3 python py; do
    if "$candidate" -c 'import sys; sys.exit(sys.version_info < (3, 9))' >/dev/null 2>&1; then
        python="$candidate"
        break
    fi
done
[ -n "$python" ] || { echo "prepare: Python 3.9 or newer is needed (python3, python or py)." >&2; exit 1; }

"$python" scripts/make-dataset.py "$data" --letters "$(setting DATA_LETTERS)" --source "$(setting DATA_SOURCE)"
"$python" scripts/make-oxygen.py --base "$base" "$@"
