#!/bin/sh
# First start: turn the dataset (mounted read-only at /seed) into the bare repository
# /srv/git/$PROJECT.git with a single commit on `main`. Later starts keep the repository, so
# everything participants saved through webdav stays until `reset`. Extra, empty projects get
# their repository from `new-repo <slug>` (scripts/new-project.sh, NEW-PROJECT.md).
set -eu

if [ ! -d "/srv/git/${PROJECT}.git" ]; then
    test -d /seed/data || { echo "gitserver: /seed/data missing — run scripts/prepare.sh" >&2; exit 1; }
    new-repo "$PROJECT" /seed
fi

exec git daemon --reuseaddr --base-path=/srv/git --export-all --enable=receive-pack \
    --informative-errors /srv/git
