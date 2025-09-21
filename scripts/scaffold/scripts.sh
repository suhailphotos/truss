#!/usr/bin/env bash
set -euo pipefail
# Usage: scripts/scaffold/scripts.sh <name> <repo_root>

name="${1:?name}"; root="${2:?repo_root}"
cd "$root"

mkdir -p scripts lib tools bin

# .gitignore
if [ ! -f .gitignore ]; then
  cat > .gitignore <<'EOF'
.DS_Store
*.swp
*.swo
*~
bin/*
EOF
fi

# .editorconfig
if [ ! -f .editorconfig ]; then
  cat > .editorconfig <<'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2

[*.sh]
indent_size = 2
EOF
fi

# lib/common.sh
if [ ! -f lib/common.sh ]; then
  cat > lib/common.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
warn() { printf '⚠️  %s\n' "$*" >&2; }
info() { printf '➜ %s\n' "$*"; }
die()  { printf '✖ %s\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null || die "Missing required command: $1"; }
OS="$(uname -s)"; case "$OS" in Darwin) OS="macOS";; Linux) OS="linux";; *) OS="unknown";; esac
export OS
EOF
  chmod +x lib/common.sh
fi

# tools/lint.sh
if [ ! -f tools/lint.sh ]; then
  cat > tools/lint.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if ! command -v shellcheck >/dev/null; then
  echo "shellcheck not found"; exit 1
fi
files=$(find lib scripts tools -type f -name '*.sh' 2>/dev/null || true)
[ -z "${files:-}" ] && { echo "No .sh files to lint."; exit 0; }
# shellcheck disable=SC2086
shellcheck -x $files || true
EOF
  chmod +x tools/lint.sh
fi

# tools/fmt.sh
if [ ! -f tools/fmt.sh ]; then
  cat > tools/fmt.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if ! command -v shfmt >/dev/null; then
  echo "shfmt not found"; exit 1
fi
shfmt -w -i 2 -ci -sr lib scripts tools
EOF
  chmod +x tools/fmt.sh
fi

# tools/new.sh
if [ ! -f tools/new.sh ]; then
  cat > tools/new.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[ $# -eq 2 ] || { echo "Usage: tools/new.sh <category> <name>"; exit 1; }
catg="$1"; name="$2"; dir="scripts/${catg}"; path="${dir}/${name}.sh"
mkdir -p "$dir"; [ -e "$path" ] && { echo "Refusing to overwrite: $path" >&2; exit 1; }
cat > "$path" <<'TPL'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$ROOT_DIR/lib/common.sh"
main(){ info "hello from ${0##*/}"; }
main "$@"
TPL
chmod +x "$path"; echo "Created: $path"
EOF
  chmod +x tools/new.sh
fi

# sample
if [ ! -f scripts/hello.sh ]; then
  cat > scripts/hello.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$ROOT_DIR/lib/common.sh"
info "OS detected: $OS"
info "Hello from scripts/hello.sh"
EOF
  chmod +x scripts/hello.sh
fi

echo "Scripts scaffold created."
