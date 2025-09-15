\
#!/usr/bin/env bash
set -euo pipefail

GH_USER_DEFAULT="suhailphotos"
REPO_DEFAULT="truss"
DESC_DEFAULT="Cross-platform shell scripts: bootstrap, lint, format, and utility helpers."
DEST_DEFAULT="${MATRIX:-$HOME/Library/CloudStorage/Dropbox/matrix}/tools/truss"
LICENSE_DEFAULT="MIT"
VIS_DEFAULT="public"
OP_SECRET_DEFAULT="op://devTools/GitHub Repo Key/secret key"
README_PATH_DEFAULT="${HOME}/Downloads/README.truss.md"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="${SCRIPT_DIR}/bootstrap_scripts_repo.sh"

if [ ! -f "$GEN" ]; then
  echo "Cannot find ${GEN}. Place this wrapper next to bootstrap_scripts_repo.sh." >&2
  exit 1
fi

exec "$GEN" \
  -u "${GH_USER_DEFAULT}" \
  -r "${REPO_DEFAULT}" \
  -d "${DESC_DEFAULT}" \
  -p "${DEST_DEFAULT}" \
  -R "${README_PATH_DEFAULT}" \
  -L "${LICENSE_DEFAULT}" \
  -V "${VIS_DEFAULT}" \
  -O "${OP_SECRET_DEFAULT}" \
  "$@"
