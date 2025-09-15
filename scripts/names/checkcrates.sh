#!/usr/bin/env bash
set -euo pipefail

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

exists() {
  local n="$1" code
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://crates.io/api/v1/crates/$n")
  [ "$code" = "200" ]
}

check_one() {
  local raw="$1"
  local name alt1 alt2
  name="$(lower "$raw")"
  alt1="${name//-/_}"   # cargo treats - and _ as the same
  alt2="${name//_/-}"

  # taken if ANY variant exists
  if exists "$name" || { [ "$alt1" != "$name" ] && exists "$alt1"; } \
     || { [ "$alt2" != "$name" ] && [ "$alt2" != "$alt1" ] && exists "$alt2"; }; then
    # figure out which one collided (for the message)
    local hit=""
    exists "$name" && hit="$name"
    if [ -z "$hit" ] && [ "$alt1" != "$name" ] && exists "$alt1"; then hit="$alt1"; fi
    if [ -z "$hit" ] && [ "$alt2" != "$name" ] && [ "$alt2" != "$alt1" ] && exists "$alt2"; then hit="$alt2"; fi
    printf '❌ %s is taken (conflicts with "%s")\n' "$raw" "$hit"
  else
    printf '✅ %s looks available\n' "$raw"
  fi
}

check_crates() {
  if [ $# -eq 0 ]; then
    echo "usage: check_crates <name> [name2 ...]" >&2
    return 1
  fi
  for n in "$@"; do check_one "$n"; done
}

# run against your current shortlist (edit as you like)
check_crates apogee spoke apoapsis periapsis aphelion meridiem azimuth gnomon yoke detent clevis trammel splice plait limb plumb
