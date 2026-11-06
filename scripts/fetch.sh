# Sourced by scripts/prepare.sh and scripts/fetch-services.sh (bash: Linux, macOS, Git Bash).
#
#   fetch NAME SOURCE [SPARSE-PATH …] → prints the folder to use
#
# SOURCE is a path (relative to the workshop folder) or a git URL with #<tag, branch or commit>.
# A URL is fetched with the user's own git (and its login) into .sources/NAME/, and reused while
# its ref stays the same.

# The current folder; in Git Bash as C:/… (pwd -W), which Windows programs (git, docker, python)
# understand too, so it can be handed on as it is.
native_pwd() { pwd -W 2>/dev/null || pwd; }

fetch() {
    local name="$1" source="$2"
    shift 2
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && native_pwd)"
    case "$source" in
        *://*|git@*) ;;
        *) (cd "$here" && cd "$source" && native_pwd); return ;;
    esac
    local url="${source%%#*}" ref="${source#*#}"
    [ "$ref" != "$source" ] || { echo "fetch: $name: $source has no #<ref>" >&2; return 1; }
    local dir="$here/.sources/$name"
    if [ "$(cat "$dir/.workshop-source" 2>/dev/null)" != "$source" ]; then
        echo "fetch: $name ($url at $ref) …" >&2
        rm -rf "$dir"
        mkdir -p "$dir"
        git -C "$dir" init -q
        # the files go into Linux images: keep their line endings as committed
        git -C "$dir" config core.autocrlf false
        git -C "$dir" remote add origin "$url"
        if [ $# -gt 0 ]; then
            # the patterns start with /: Git Bash would turn them into C:/Program Files/Git/…
            MSYS_NO_PATHCONV=1 git -C "$dir" sparse-checkout set --no-cone "$@" >&2
        fi
        git -C "$dir" fetch -q --depth 1 --filter=blob:none origin "$ref" >&2 \
            || { echo "fetch: git could not fetch $url at $ref (does 'git clone $url' work?)" >&2; return 1; }
        git -C "$dir" -c advice.detachedHead=false checkout -q FETCH_HEAD >&2
        echo "$source" > "$dir/.workshop-source"
    fi
    echo "$dir"
}
