#!/usr/bin/env bash
# Stop the workshop stack. Everything is kept; ./start.sh continues where you left off.
set -euo pipefail
cd "$(dirname "$0")"
docker compose --env-file workshop.env --env-file sources.env stop
