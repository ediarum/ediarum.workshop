#!/usr/bin/env bash
# Remove the workshop stack with all its data (edits, ids, index, added projects). The next
# ./start.sh begins from the original dataset again. Images are kept.
set -euo pipefail
cd "$(dirname "$0")"
echo "(What was pushed to a project's own repository, NEW-PROJECT.md, stays there.)"
read -r -p "Delete all workshop data (your edits included)? [y/N] " answer
case "$answer" in
    [yYjJ]*)
        docker compose --env-file workshop.env --env-file sources.env down -v --remove-orphans
        # the id prefixes of projects added with scripts/new-project.sh (their data is gone now)
        sed -i.bak '/^# --- added by scripts\/new-project/q' config/id/projects.toml
        rm -f config/id/projects.toml.bak
        # the git token of a project added with its own repository (the repository itself is kept)
        rm -f secrets/git_token secrets/git.env
        ;;
    *) echo "Nothing deleted." ;;
esac
