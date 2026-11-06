#!/usr/bin/env bash
# Start the ediarum workshop stack (Linux, macOS; Windows: in Git Bash). Safe to run again:
# everything is kept until reset.sh.
#
#   ./start.sh            build what changed, start, wait until the registers are loaded
#   ./start.sh --no-build start with the images built last time
set -euo pipefail
cd "$(dirname "$0")"

build=1
[ "${1:-}" = "--no-build" ] && build=0

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[31m%s\033[0m\n' "$*" >&2; exit 1; }
setting() { sed -n "s/^$1=//p" workshop.env | head -1; }

compose() { docker compose --env-file workshop.env --env-file sources.env "$@"; }

PORT="$(setting PORT)"
PROJECT="$(setting PROJECT)"
KEY="$(setting INDEX_OXYGEN_KEY)"

# --- preflight -------------------------------------------------------------------------------------
say "Checking Docker …"
docker info >/dev/null 2>&1 || fail "Docker is not running. Start Docker Desktop (or the docker service) and try again."
docker compose version >/dev/null 2>&1 || fail "'docker compose' is missing. Install Docker Desktop or the Compose plugin."
command -v git >/dev/null || fail "git is missing. Install it (Windows: Git for Windows, https://git-scm.com, and run this in Git Bash)."
v="$(docker compose version --short | sed 's/^v//')"
[ "$(printf '%s\n' 2.24 "$v" | sort -V | head -1)" = 2.24 ] || fail "Docker Compose $v is too old (2.24 or newer needed). Update Docker Desktop or the Compose plugin."
if ! compose ps --status running --services 2>/dev/null | grep -qx proxy; then
    if (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; then
        fail "Port $PORT is already in use. Stop the program using it, or change PORT in workshop.env (then run scripts/prepare.sh)."
    fi
fi

# dataset/ and oxygen/: download the release's ready-made copy, or build them from the sources
download_generated() {
    local url="$1"
    rm -rf .download && mkdir .download
    curl -fL --progress-bar -o .download/generated.tar.gz "$url" \
        && tar -xzf .download/generated.tar.gz -C .download \
        && [ -d ".download/dataset/$PROJECT/data" ] && [ -f .download/oxygen/workshop.xpr ] \
        || { rm -rf .download; return 1; }
    rm -rf dataset oxygen
    mv .download/dataset .download/oxygen .
    rm -rf .download
}
if [ ! -d "dataset/$PROJECT/data" ] || [ ! -f oxygen/workshop.xpr ]; then
    url="$(sed -n 's/^GENERATED_URL=//p' sources.env | head -1)"
    if [ -n "$url" ]; then
        say "Downloading dataset and oXygen project …"
        download_generated "$url" || {
            echo "  The download from $url failed; building them instead (needs git and python3)."
            url=""
        }
    fi
    if [ -z "$url" ]; then
        say "Preparing dataset and oXygen project …"
        scripts/prepare.sh
    fi
fi

# --- build and start -------------------------------------------------------------------------------
# services from git URLs (sources.env): fetched with your own git login, then built locally
say "Fetching the services' sources …"
services="$(scripts/fetch-services.sh)" || fail "Fetching a service failed (message above). Check that 'git clone' of that repository works in this terminal."
while IFS='=' read -r name dir; do
    [ -n "$name" ] && export "$name=$dir"
done <<< "$services"

if [ "$build" = 1 ]; then
    say "Building images (the first time takes several minutes) …"
    compose build
fi

say "Starting services and loading the registers (the first time takes a few minutes) …"
compose up -d --wait --wait-timeout 600 proxy || {
    compose ps -a
    fail "Some services did not come up. Logs: docker compose --env-file workshop.env --env-file sources.env logs <service>"
}

# --- wait for the first ingest ---------------------------------------------------------------------
say "Loading the registers into the index …"
url="http://127.0.0.1:$PORT/api/index/$PROJECT/entries?entry_type=person&limit=1&key=$KEY"
for i in $(seq 1 120); do
    total="$( (curl -fsS -D - -o /dev/null "$url" 2>/dev/null || true) | tr -d '\r' | sed -n 's/^[Xx]-[Tt]otal-[Cc]ount: //p')"
    if [ -n "$total" ] && [ "$total" -gt 0 ]; then
        echo "  $total persons"
        break
    fi
    [ "$i" = 120 ] && {
        compose logs --tail 40 index-import
        fail "The registers did not arrive within 10 minutes (log above)."
    }
    printf '.'
    sleep 5
done

# --- summary ---------------------------------------------------------------------------------------
cat <<EOF

ediarum workshop is running.

  Platform (Index, IDs, WebDAV)   http://localhost:$PORT/
  Login                           $(setting WORKSHOP_USER_EMAIL) / $(setting WORKSHOP_USER_PASSWORD)
  WebDAV access (used by oXygen)  http://localhost:$PORT/webdav/connection/$PROJECT/
  oXygen project file             $(pwd -W 2>/dev/null || pwd)/oxygen/workshop.xpr

  Stop:   ./stop.sh      (everything is kept)
  Reset:  ./reset.sh     (back to the start state)
EOF
