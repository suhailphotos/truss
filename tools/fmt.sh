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
