#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: tools/new.sh <category> <name>"
  echo "Example: tools/new.sh cargo bootstrap_repo"
  exit 1
}

[ $# -eq 2 ] || usage
catg="$1"; name="$2"
dir="scripts/${catg}"
path="${dir}/${name}.sh"

mkdir -p "$dir"
if [ -e "$path" ]; then
  echo "Refusing to overwrite existing file: $path" >&2
  exit 1
fi

cat > "$path" <<'TPL'
#!/usr/bin/env bash
set -euo pipefail
# shell: ${0##*/}

# resolve repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../lib/common.sh
. "$ROOT_DIR/lib/common.sh"

main() {
  info "hello from ${0##*/}"
  # TODO: your logic here
}

main "$@"
TPL

chmod +x "$path"
echo "Created: $path"
