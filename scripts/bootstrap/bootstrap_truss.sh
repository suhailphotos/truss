#!/usr/bin/env bash
set -euo pipefail

# Sensible, overridable defaults (can be set via env before calling)
GH_USER_DEFAULT="${GH_USER:-suhailphotos}"
LICENSE_DEFAULT="${LICENSE_DEFAULT:-MIT}"
VIS_DEFAULT="${VIS_DEFAULT:-public}"
OP_SECRET_DEFAULT="${OP_SECRET_DEFAULT:-}"                    # optional
README_PATH_DEFAULT="${README_PATH_DEFAULT:-}"                # optional

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="${SCRIPT_DIR}/bootstrap_scripts_repo.sh"
[ -f "$GEN" ] || { echo "Cannot find ${GEN}"; exit 1; }

# Helper: check if a short flag (e.g., u, r, p, R, L, V, O) is present
has_flag() {
  local f="-$1"
  for a in "$@"; do :; done   # noop to keep shellcheck happy
  for a in "${ARGS[@]}"; do
    [[ "$a" == "$f" ]] && return 0
  done
  return 1
}

ARGS=("$@")

# Inject defaults only if user didn't pass them
if ! has_flag u; then ARGS+=(-u "$GH_USER_DEFAULT"); fi
if ! has_flag L; then ARGS+=(-L "$LICENSE_DEFAULT"); fi
if ! has_flag V; then ARGS+=(-V "$VIS_DEFAULT"); fi
if [ -n "$OP_SECRET_DEFAULT" ] && ! has_flag O; then ARGS+=(-O "$OP_SECRET_DEFAULT"); fi
if [ -n "$README_PATH_DEFAULT" ] && ! has_flag R; then ARGS+=(-R "$README_PATH_DEFAULT"); fi

# IMPORTANT: do NOT add -p here. Let generator fall back to:
#   DEST="${MATRIX:-$HOME/Library/CloudStorage/Dropbox/matrix}/${REPO}"

exec "$GEN" "${ARGS[@]}"
