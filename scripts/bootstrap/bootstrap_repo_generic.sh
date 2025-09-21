#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bootstrap_repo_generic.sh -u <gh_user> -r <repo> [-d <desc>] [-p <dest_path>]
                            [-R <readme_path>] [-V <public|private>] [-O <op_secret_path>]
                            [-t <plain|rust|python|scripts>] [-h]

Purpose:
  Create a GitHub repo (with README + MIT license), clone locally, optionally replace README,
  set tokenized remote via 1Password, optionally run a type-specific scaffolder, commit, and push.
  No scaffolding when -t is omitted or set to "plain".

Options:
  -u  GitHub username (e.g. suhailphotos)                 [required]
  -r  Repository name (e.g. atrium)                       [required]
  -d  One-line GitHub description                          (default: "")
  -p  Destination path to clone into                       (default: "$MATRIX/<repo>")
  -R  Path to README.md to copy into the repo              (optional; replaces default)
  -V  Visibility: public|private                           (default: public)
  -O  1Password item path for GitHub token (op read ...)   (optional; used for clone/push)
  -t  Project type: plain|rust|python|scripts              (default: plain = no scaffolding)
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
case "$TYPE" in plain|rust|python|scripts) ;; *) echo "Invalid -t (use plain|rust|python|scripts)"; exit 1;; esac

for cmd in gh git; do
  command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd"; exit 1; }
done

# --- 1) create remote repo with README + MIT license ---
if gh repo view "${GH_USER}/${REPO}" >/dev/null 2>&1; then
  echo "Repo ${GH_USER}/${REPO} already exists. Skipping creation."
else
  if [ "${VISIBILITY}" = "private" ]; then VIS_FLAG="--private"; else VIS_FLAG="--public"; fi
  gh repo create "${GH_USER}/${REPO}" ${VIS_FLAG} \
    -d "${DESC}" \
    --license "${LICENSE_ID}" \
    --add-readme
fi

# --- 2) clone locally (handle private clones with token if available) ---
mkdir -p "$(dirname "$DEST")"
if [ -d "${DEST}/.git" ]; then
  echo "Local repo already present at ${DEST}. Skipping clone."
else
  CLONE_URL="https://github.com/${GH_USER}/${REPO}.git"
  if [ "${VISIBILITY}" = "private" ] && [ -n "${OP_SECRET_PATH}" ] && command -v op >/dev/null; then
    if TOKEN="$(op read "${OP_SECRET_PATH}" --no-newline 2>/dev/null)"; then
      CLONE_URL="https://x-access-token:${TOKEN}@github.com/${GH_USER}/${REPO}.git"
    fi
  fi
  git clone "${CLONE_URL}" "${DEST}"
fi
cd "${DEST}"

# --- 3) optionally replace README with your local one ---
if [ -n "${README_PATH}" ] && [ -f "${README_PATH}" ]; then
  cp -f "${README_PATH}" README.md
elif [ ! -f README.md ]; then
  printf "# %s\n" "${REPO}" > README.md
fi

# --- 4) optional scaffolding by type (no-op for plain) ---
if [ "${TYPE}" != "plain" ]; then
  CALLER_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
  SCAFFOLD_DIR="$(cd "$CALLER_DIR/../scaffold" && pwd 2>/dev/null || echo "")"
  SCAFFOLD_SCRIPT="${SCAFFOLD_DIR}/${TYPE}.sh"
  if [ -n "$SCAFFOLD_DIR" ] && [ -x "$SCAFFOLD_SCRIPT" ]; then
    # Pass repo name and absolute repo root; run inside repo root
    "$SCAFFOLD_SCRIPT" "${REPO}" "$(pwd)"
  else
    echo "NOTE: Scaffolder not found for type '${TYPE}' at: ${SCAFFOLD_SCRIPT} (skipping)"
  fi
fi

# --- 5) set tokenized remote BEFORE pushing (prevents username prompt) ---
if [ -n "${OP_SECRET_PATH}" ] && command -v op >/dev/null; then
  if TOKEN="$(op read "${OP_SECRET_PATH}" --no-newline 2>/dev/null)"; then
    git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${GH_USER}/${REPO}.git"
  else
    echo "WARNING: Could not read token from 1Password path: ${OP_SECRET_PATH}" >&2
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
