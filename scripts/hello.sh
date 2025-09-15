#!/usr/bin/env bash
set -euo pipefail
# demo script that sources common helpers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
. "$ROOT_DIR/lib/common.sh"

info "OS detected: $OS"
info "Hello from scripts/hello.sh"
