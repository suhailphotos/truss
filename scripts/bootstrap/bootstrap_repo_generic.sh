#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bootstrap_repo_generic.sh -u <gh_user> -r <repo> [-d <desc>] [-p <dest_path>]
                            [-R <readme_path>] [-V <public|private>] [-O <op_secret_path>]
                            [-t <plain|rust>] [-h]

Purpose:
  Create a GitHub repo (with README + MIT license), clone locally, optionally replace README,
  set tokenized remote via 1Password, make an initial commit, and push. No scaffolding by default.

Options:
  -u  GitHub username (e.g. suhailphotos)                 [required]
  -r  Repository name (e.g. atrium)                       [required]
  -d  One-line GitHub description                          (default: "")
  -p  Destination path to clone into                       (default: "$MATRIX/<repo>")
  -R  Path to README.md to copy into the repo              (optional; replaces default)
  -V  Visibility: public|private                           (default: public)
  -O  1Password item path for GitHub token (op read ...)   (optional; sets push remote)
  -t  Project type: plain|rust                             (default: plain)
  -h  Help
USAGE
}

# --- defaults ---
GH_USER=""
REPO=""
DESC=""
VISIBILITY="public"
README_PATH=""
DEST=""
OP_SECRET_PATH=""
TYPE="plain"
LICENSE_ID="MIT"   # default license

while getopts ":u:r:d:p:R:V:O:t:h" opt; do
  case "$opt" in
    u) GH_USER="$OPTARG" ;;
    r) REPO="$OPTARG" ;;
    d) DESC="$OPTARG" ;;
    p) DEST="$OPTARG" ;;
    R) README_PATH="$OPTARG" ;;
    V) VISIBILITY="$OPTARG" ;;
    O) OP_SECRET_PATH="$OPTARG" ;;
    t) TYPE="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

[ -z "${GH_USER}" ] && { echo "Missing -u <gh_user>"; usage; exit 1; }
[ -z "${REPO}" ] && { echo "Missing -r <repo>"; usage; exit 1; }
[ -z "${DEST}" ] && DEST="${MATRIX:-$HOME/Library/CloudStorage/Dropbox/matrix}/${REPO}"
case "$VISIBILITY" in public|private) ;; *) echo "Invalid -V (use public|private)"; exit 1;; esac
case "$TYPE" in plain|rust) ;; *) echo "Invalid -t (use plain|rust)"; exit 1;; esac

for cmd in gh git; do
  command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd"; exit 1; }
done

# --- 1) create remote repo with README + MIT license (avoids empty-clone warning) ---
if gh repo view "${GH_USER}/${REPO}" >/dev/null 2>&1; then
  echo "Repo ${GH_USER}/${REPO} already exists. Skipping creation."
else
  if [ "${VISIBILITY}" = "private" ]; then VIS_FLAG="--private"; else VIS_FLAG="--public"; fi
  gh repo create "${GH_USER}/${REPO}" ${VIS_FLAG} \
    -d "${DESC}" \
    --license "${LICENSE_ID}" \
    --add-readme
fi

# --- 2) clone locally ---
mkdir -p "$(dirname "$DEST")"
if [ -d "${DEST}/.git" ]; then
  echo "Local repo already present at ${DEST}. Skipping clone."
else
  git clone "https://github.com/${GH_USER}/${REPO}.git" "${DEST}"
fi
cd "${DEST}"

# --- 3) optionally replace README with your local one ---
if [ -n "${README_PATH}" ] && [ -f "${README_PATH}" ]; then
  cp -f "${README_PATH}" README.md
elif [ ! -f README.md ]; then
  printf "# %s\n" "${REPO}" > README.md
fi

# --- 4) optional rust bootstrap handoff (uses your existing rust script) ---
if [ "${TYPE}" = "rust" ]; then
  CALLER_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
  RUST_BOOT="$(cd "$CALLER_DIR/../rust" && pwd)/bootstrap_repo.sh"
  if [ -x "$RUST_BOOT" ]; then
    "$RUST_BOOT" .
  else
    echo "WARNING: Rust bootstrap not found at: $RUST_BOOT" >&2
  fi
fi

# --- 5) set tokenized remote BEFORE pushing (prevents username prompt) ---
if [ -n "${OP_SECRET_PATH}" ]; then
  if command -v op >/dev/null; then
    if TOKEN="$(op read "${OP_SECRET_PATH}" --no-newline 2>/dev/null)"; then
      git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${GH_USER}/${REPO}.git"
    else
      echo "WARNING: Could not read token from 1Password path: ${OP_SECRET_PATH}" >&2
    fi
  else
    echo "WARNING: 'op' not found. Skipping remote auth update." >&2
  fi
fi

# --- 6) commit/push (only if there are changes) ---
git add .
if ! git diff --cached --quiet; then
  git commit -m "chore: initial import"
fi
git branch -M main
git push -u origin main

echo "✅ Done."
echo "   Repo: https://github.com/${GH_USER}/${REPO}"
echo "   Local: ${DEST}"
