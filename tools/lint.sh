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
