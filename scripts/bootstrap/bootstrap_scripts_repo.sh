\
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bootstrap_scripts_repo.sh -u <gh_user> -r <repo> [-d <desc>] [-p <dest_path>] [-R <readme_path>]
                            [-L <license>] [-V <public|private>] [-O <op_secret_path>] [-h]

Purpose:
  Create a GitHub repository for a shell-scripts toolkit, clone it locally, scaffold a
  clean structure (scripts/, lib/, tools/, bin/), drop a common helper library, add a
  sample script, and push the initial commit.

Options:
  -u  GitHub username (e.g. suhailphotos)                 [required]
  -r  Repository name (e.g. truss)                        [required]
  -d  One-line GitHub description                          (default: "")
  -p  Destination path to clone into                       (default: "$MATRIX/tools/<repo>")
  -R  Path to README.md to copy into the repo              (optional)
  -L  License ID for gh (--license)                        (default: MIT)
  -V  Visibility: public|private                           (default: public)
  -O  1Password item path for GitHub token (op read ...)   (optional; sets push remote)
  -h  Show help

Notes:
  • Requires: gh, git. (Optional: op, shellcheck, shfmt)
  • We create the remote first (gh), then clone.
  • Scaffolds POSIX-friendly Bash scripts (compatible with macOS Bash 3.2).
USAGE
}

# --- defaults ---
LICENSE="MIT"
VISIBILITY="public"
README_PATH=""
OP_SECRET_PATH=""
GH_USER=""
REPO=""
DESC=""
DEST=""

# --- parse args ---
while getopts ":u:r:d:p:R:O:L:V:h" opt; do
  case "$opt" in
    u) GH_USER="$OPTARG" ;;
    r) REPO="$OPTARG" ;;
    d) DESC="$OPTARG" ;;
    p) DEST="$OPTARG" ;;
    R) README_PATH="$OPTARG" ;;
    O) OP_SECRET_PATH="$OPTARG" ;;
    L) LICENSE="$OPTARG" ;;
    V) VISIBILITY="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

[ -z "${GH_USER}" ] && { echo "Missing -u <gh_user>"; usage; exit 1; }
[ -z "${REPO}" ] && { echo "Missing -r <repo>"; usage; exit 1; }
[ -z "${DEST}" ] && DEST="${MATRIX:-$HOME/Library/CloudStorage/Dropbox/matrix}/${REPO}"

for cmd in gh git; do
  command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd"; exit 1; }
done

# --- 1) create remote repo if missing ---
if gh repo view "${GH_USER}/${REPO}" >/dev/null 2>&1; then
  echo "Repo ${GH_USER}/${REPO} already exists. Skipping creation."
else
  if [ "${VISIBILITY}" = "private" ]; then
    VIS_FLAG="--private"
  else
    VIS_FLAG="--public"
  fi

  gh repo create "${GH_USER}/${REPO}" \
    --add-readme \
    --license "${LICENSE}" \
    -d "${DESC}" \
    ${VIS_FLAG}
fi

# --- 2) clone locally ---
mkdir -p "$(dirname "$DEST")"
if [ -d "${DEST}/.git" ]; then
  echo "Local repo already present at ${DEST}. Skipping clone."
else
  git clone "https://github.com/${GH_USER}/${REPO}.git" "${DEST}"
fi

cd "${DEST}"

# --- 3) scaffold structure ---
mkdir -p scripts lib tools bin

# .gitignore
if [ ! -f .gitignore ]; then
  cat > .gitignore <<'EOF'
# build artifacts / editor junk
.DS_Store
*.swp
*.swo
*~
# generated files
bin/*
EOF
fi

# .editorconfig (sane defaults)
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

# lib/common.sh (helpers)
if [ ! -f lib/common.sh ]; then
  cat > lib/common.sh <<'EOF'
#!/usr/bin/env bash
# common helpers for scripts in this repo
set -euo pipefail

warn() { printf '⚠️  %s\n' "$*" >&2; }
info() { printf '➜ %s\n' "$*"; }
die()  { printf '✖ %s\n' "$*" >&2; exit 1; }

require_cmd() { command -v "$1" >/dev/null || die "Missing required command: $1"; }

# detect OS (simple)
OS="$(uname -s)"
case "$OS" in
  Darwin) OS="macOS" ;;
  Linux)  OS="linux" ;;
  *)      OS="unknown" ;;
esac
export OS
EOF
  chmod +x lib/common.sh
fi

# tools/lint.sh (shellcheck using find for bash 3.2)
if [ ! -f tools/lint.sh ]; then
  cat > tools/lint.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Lint all shell scripts using shellcheck if available.
if ! command -v shellcheck >/dev/null; then
  echo "shellcheck not found. Install with:"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "  brew install shellcheck"
  else
    echo "  sudo apt-get install -y shellcheck    # Debian/Ubuntu"
    echo "  # or see https://www.shellcheck.net for other platforms"
  fi
  exit 1
fi

files=$(find lib scripts tools -type f -name '*.sh' 2>/dev/null || true)
[ -z "${files:-}" ] && { echo "No .sh files to lint."; exit 0; }
# shellcheck disable=SC2086 # we intentionally expand the list
shellcheck -x $files || true
EOF
  chmod +x tools/lint.sh
fi

# tools/fmt.sh (shfmt)
if [ ! -f tools/fmt.sh ]; then
  cat > tools/fmt.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Format all shell scripts using shfmt if available.
if ! command -v shfmt >/dev/null; then
  echo "shfmt not found. Install with:"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "  brew install shfmt"
  else
    echo "  go install mvdan.cc/sh/v3/cmd/shfmt@latest"
    echo "  # or check your distro's package manager"
  fi
  exit 1
fi
shfmt -w -i 2 -ci -sr lib scripts tools
EOF
  chmod +x tools/fmt.sh
fi

# tools/new.sh (script generator from template)
if [ ! -f tools/new.sh ]; then
  cat > tools/new.sh <<'EOF'
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
EOF
  chmod +x tools/new.sh
fi

# sample script
if [ ! -f scripts/hello.sh ]; then
  cat > scripts/hello.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# demo script that sources common helpers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
. "$ROOT_DIR/lib/common.sh"

info "OS detected: $OS"
info "Hello from scripts/hello.sh"
EOF
  chmod +x scripts/hello.sh
fi

# --- 4) replace README from external file if provided ---
if [ -n "${README_PATH}" ]; then
  if [ -f "${README_PATH}" ]; then
    cp -f "${README_PATH}" README.md
  else
    echo "WARNING: README path not found: ${README_PATH}" >&2
  fi
fi

# --- 5) optionally set remote with 1Password token (push auth) ---
if [ -n "${OP_SECRET_PATH}" ]; then
  if command -v op >/dev/null; then
    TOKEN="$(op read "${OP_SECRET_PATH}")"
    git remote set-url origin "https://${TOKEN}@github.com/${GH_USER}/${REPO}"
  else
    echo "WARNING: 'op' not found. Skipping remote auth update." >&2
  fi
fi

# --- 6) initial commit & push ---
git add .
if ! git diff --cached --quiet; then
  git commit -m "bootstrap: scaffold shell-scripts toolkit (scripts/, lib/, tools/, bin/)"
  git push -u origin main
else
  echo "No changes to commit."
fi

echo "✅ Done."
echo "   Repo: https://github.com/${GH_USER}/${REPO}"
echo "   Local: ${DEST}"
