#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bootstrap_repo.sh -u <gh_user> -r <repo> [-d <desc>] [-p <dest_path>] [-R <readme_path>]
                    [-L <license>] [-V <public|private>] [-n <cargo_name>] [-e <edition>]
                    [-O <op_secret_path>] [-h]

Options:
  -u  GitHub username (e.g. suhailphotos)                [required]
  -r  Repository name (e.g. apogee)                       [required]
  -d  One-line GitHub description                          (default: "")
  -p  Destination path to clone into                       (default: "$MATRIX/crates/<repo>")
  -R  Path to README.md to copy into the repo              (recommended)
  -L  License ID for gh (--license)                        (default: MIT)
  -V  Visibility: public|private                           (default: public)
  -n  Cargo package/binary name                            (default: repo name)
  -e  Rust edition                                         (default: 2021)
  -O  1Password item path for GitHub token (op read ...)   (optional; sets push remote)
  -h  Show help

Notes:
  • Requires: gh, git, cargo. (Optional: op)
  • We create the remote first (gh), then clone, then `cargo init --vcs none`.
  • If -O is provided, we set a token-in-URL push remote (be mindful of storing secrets in .git/config).
USAGE
}

# --- defaults ---
LICENSE="MIT"
VISIBILITY="public"
EDITION="2021"
CARGO_NAME=""
DEST=""
README_PATH=""
OP_SECRET_PATH=""
GH_USER=""
REPO=""
DESC=""

# --- parse args (POSIX getopts) ---
while getopts ":u:r:d:p:R:O:L:V:n:e:h" opt; do
  case "$opt" in
    u) GH_USER="$OPTARG" ;;
    r) REPO="$OPTARG" ;;
    d) DESC="$OPTARG" ;;
    p) DEST="$OPTARG" ;;
    R) README_PATH="$OPTARG" ;;
    O) OP_SECRET_PATH="$OPTARG" ;;
    L) LICENSE="$OPTARG" ;;
    V) VISIBILITY="$OPTARG" ;;
    n) CARGO_NAME="$OPTARG" ;;
    e) EDITION="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

[ -z "${GH_USER}" ] && { echo "Missing -u <gh_user>"; usage; exit 1; }
[ -z "${REPO}" ] && { echo "Missing -r <repo>"; usage; exit 1; }
[ -z "${DEST}" ] && DEST="${MATRIX:-$HOME/Library/CloudStorage/Dropbox/matrix}/crates/${REPO}"
[ -z "${CARGO_NAME}" ] && CARGO_NAME="${REPO}"

for cmd in gh git cargo; do
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

# --- 3) cargo init (no git) ---
if [ -f Cargo.toml ]; then
  echo "Cargo.toml exists. Skipping cargo init."
else
  cargo init --bin --name "${CARGO_NAME}" --edition "${EDITION}" --vcs none
fi

# --- 4) .gitignore (minimal) ---
if [ ! -f .gitignore ]; then
  cat > .gitignore <<'EOF'
/target
**/*.rs.bk
# editor cruft
*.swp
.DS_Store
EOF
fi

# --- 5) starter src/main.rs if missing ---
mkdir -p src
if [ ! -f src/main.rs ]; then
  cat > src/main.rs <<'EOF'
fn main() {
    // TODO: Detect environment and emit shell config.
    println!("# apogee: pre-alpha placeholder");
    println!("alias apogee_ok='echo apogee is alive'");
}
EOF
fi

# --- 6) replace README from external file if provided ---
if [ -n "${README_PATH}" ]; then
  if [ -f "${README_PATH}" ]; then
    cp -f "${README_PATH}" README.md
  else
    echo "WARNING: README path not found: ${README_PATH}" >&2
  fi
fi

# --- 7) optionally set remote with 1Password token (push auth) ---
if [ -n "${OP_SECRET_PATH}" ]; then
  if command -v op >/dev/null; then
    TOKEN="$(op read "${OP_SECRET_PATH}")"
    git remote set-url origin "https://${TOKEN}@github.com/${GH_USER}/${REPO}"
  else
    echo "WARNING: 'op' not found. Skipping remote auth update." >&2
  fi
fi

# --- 8) commit & push ---
git add .
if ! git diff --cached --quiet; then
  git commit -m "bootstrap: initialize ${REPO} with cargo bin, README, .gitignore"
  git push -u origin main
else
  echo "No changes to commit."
fi

echo "✅ Done."
echo "   Repo: https://github.com/${GH_USER}/${REPO}"
echo "   Local: ${DEST}"
