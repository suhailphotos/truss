\
#!/usr/bin/env bash
# namecheck.sh — check if names are available on popular registries
# Compatible with macOS Bash 3.2 (no ${var,,} / associative arrays).
#
# Registries supported:
#   - crates   → Rust crates.io
#   - npm      → npm (good for TypeScript/JS packages)
#   - pypi     → Python PyPI
#
# Usage:
#   namecheck.sh [-r crates|npm|pypi|all] [-f file] [--no-variants] [names...]
#
# Examples:
#   # check a shortlist on crates + npm
#   namecheck.sh -r crates,npm apogee spoke apoapsis
#
#   # read names from a file (one per line, '#' comments ok)
#   namecheck.sh -r all -f names.txt
#
#   # or pass names via env var:
#   NAMES="apogee spoke apoapsis" ./namecheck.sh -r crates
#
set -euo pipefail

# -------- utils --------
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' ; }

# minimal urlencode for scoped npm packages (@scope/name)
urlencode_basic() {
  # only encode '@' and '/' which are the realistic offenders for npm scopes
  # (this avoids needing Python/perl/urlencode)
  local s="$1"
  s="${s//@/%40}"
  s="${s//\//%2F}"
  printf '%s' "$s"
}

exists_url_200() {
  # HEAD is unreliable on some registries; use GET but discard body
  local url="$1"
  curl -fsS -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q '^200$'
}

# -------- crates --------
crates_exists() {
  local name="$1"
  exists_url_200 "https://crates.io/api/v1/crates/${name}"
}

check_crates() {
  local raw="$1"
  local name alt1 alt2
  name="$(lower "$raw")"
  alt1="${name//-/_}"   # crates treats - and _ as identical
  alt2="${name//_/-}"
  if crates_exists "$name" || { [ "$alt1" != "$name" ] && crates_exists "$alt1"; } \
     || { [ "$alt2" != "$name" ] && [ "$alt2" != "$alt1" ] && crates_exists "$alt2"; }; then
    # figure out which variant collided
    local hit=""
    crates_exists "$name" && hit="$name"
    if [ -z "$hit" ] && [ "$alt1" != "$name" ] && crates_exists "$alt1"; then hit="$alt1"; fi
    if [ -z "$hit" ] && [ "$alt2" != "$name" ] && [ "$alt2" != "$alt1" ] && crates_exists "$alt2"; then hit="$alt2"; fi
    printf '[crates] ❌ %s is taken (conflicts with "%s")\n' "$raw" "$hit"
  else
    printf '[crates] ✅ %s looks available\n' "$raw"
  fi
}

# -------- npm --------
npm_exists() {
  # npm registry is case-sensitive-ish in API, but new package names are lowercase.
  # Query as-is with minimal encoding for scopes; most names should be lowercase.
  local name_enc; name_enc="$(urlencode_basic "$1")"
  exists_url_200 "https://registry.npmjs.org/${name_enc}"
}

check_npm() {
  local raw="$1"
  local name; name="$(lower "$raw")"
  if npm_exists "$name"; then
    printf '[npm] ❌ %s is taken\n' "$raw"
  else
    printf '[npm] ✅ %s looks available\n' "$raw"
  fi
}

# -------- PyPI --------
pypi_exists() {
  # PyPI normalizes names in a case-insensitive manner and treats -, _, . as identical.
  # The JSON API 404s when a project doesn't exist.
  local norm="$1"
  exists_url_200 "https://pypi.org/pypi/${norm}/json"
}

check_pypi() {
  local raw="$1"
  # Apply simple normalization heuristics client-side to catch obvious collisions.
  local name alt1 alt2 alt3
  name="$(lower "$raw")"
  alt1="${name//_/-}"
  alt2="${name//./-}"
  alt3="${alt1//./-}"
  if pypi_exists "$name" || { [ "$alt1" != "$name" ] && pypi_exists "$alt1"; } \
     || { [ "$alt2" != "$name" ] && pypi_exists "$alt2"; } \
     || { [ "$alt3" != "$name" ] && pypi_exists "$alt3"; }; then
    printf '[pypi] ❌ %s is taken\n' "$raw"
  else
    printf '[pypi] ✅ %s looks available\n' "$raw"
  fi
}

# -------- CLI parsing --------
REGISTRIES="crates"  # default
FROM_FILE=""
USE_VARIANTS=1       # currently only meaningful for crates+pypi; npm is name-as-is
REM_ARGS=""

usage() {
  cat <<'USAGE'
Usage:
  namecheck.sh [-r crates|npm|pypi|all] [-f file] [--no-variants] [names...]

Options:
  -r, --registry LIST   Comma-separated list: crates,npm,pypi,all (default: crates)
  -f, --file FILE       Read names (one per line) from FILE (lines starting with # are ignored)
      --no-variants     Do not check normalized variants (hyphen/underscore/dot) for crates/PyPI
  -h, --help            Show help

Sources of names (in order of precedence):
  1) positional arguments
  2) -f FILE (one name per line; '#' comments allowed)
  3) NAMES environment variable (whitespace-separated)
  4) stdin (pipe/redirect), one name per line

Examples:
  namecheck.sh -r crates,npm apogee spoke apoapsis
  namecheck.sh -r all -f names.txt
  NAMES="apogee spoke" ./namecheck.sh -r pypi
USAGE
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -r|--registry)
        REGISTRIES="${2:-}"; shift 2;;
      -f|--file)
        FROM_FILE="${2:-}"; shift 2;;
      --no-variants)
        USE_VARIANTS=0; shift;;
      -h|--help)
        usage; exit 0;;
      --) shift; break;;
      -*)
        echo "Unknown option: $1" >&2; usage; exit 1;;
      *)
        # first non-flag → stop parsing; rest are names
        break;;
    esac
  done
  # Remaining args are names; pass back via $REM_ARGS
  REM_ARGS="$*"
}

collect_names() {
  NAMES_COLLECTED=""

  # 1) positional args
  if [ -n "${REM_ARGS:-}" ]; then
    NAMES_COLLECTED="$REM_ARGS"
  fi

  # 2) file
  if [ -n "${FROM_FILE:-}" ]; then
    if [ ! -r "$FROM_FILE" ]; then
      echo "Cannot read file: $FROM_FILE" >&2; exit 1
    fi
    local line
    while IFS= read -r line || [ -n "$line" ]; do
      # trim and skip comments/blank lines
      line="$(printf '%s' "$line" | trim)"
      case "$line" in ''|\#*) continue;; esac
      NAMES_COLLECTED="$NAMES_COLLECTED $line"
    done < "$FROM_FILE"
  fi

  # 3) env var
  if [ -z "$NAMES_COLLECTED" ] && [ -n "${NAMES:-}" ]; then
    NAMES_COLLECTED="$NAMES"
  fi

  # 4) stdin (if piped)
  if [ -z "$NAMES_COLLECTED" ] && [ ! -t 0 ]; then
    local line
    while IFS= read -r line || [ -n "$line" ]; do
      line="$(printf '%s' "$line" | trim)"
      case "$line" in ''|\#*) continue;; esac
      NAMES_COLLECTED="$NAMES_COLLECTED $line"
    done
  fi

  # squeeze spaces
  NAMES_COLLECTED="$(printf '%s\n' "$NAMES_COLLECTED" | awk '{$1=$1};1')"
  if [ -z "$NAMES_COLLECTED" ]; then
    echo "No names provided." >&2
    usage; exit 1
  fi
}

run_checks_for() {
  local reg="$1" name="$2"
  case "$reg" in
    crates)
      if [ "$USE_VARIANTS" -eq 1 ]; then
        check_crates "$name"
      else
        if crates_exists "$(lower "$name")"; then
          printf '[crates] ❌ %s is taken\n' "$name"
        else
          printf '[crates] ✅ %s looks available\n' "$name"
        fi
      fi
      ;;
    npm)
      check_npm "$name"
      ;;
    pypi)
      if [ "$USE_VARIANTS" -eq 1 ]; then
        check_pypi "$name"
      else
        if pypi_exists "$(lower "$name")"; then
          printf '[pypi] ❌ %s is taken\n' "$name"
        else
          printf '[pypi] ✅ %s looks available\n' "$name"
        fi
      fi
      ;;
    *)
      echo "Unknown registry: $reg" >&2; return 1;;
  esac
}

main() {
  parse_args "$@"
  collect_names

  # expand registry list
  local regs=""
  case "$REGISTRIES" in
    all) regs="crates npm pypi" ;;
    *)
      # comma- or space-separated
      regs="$(printf '%s' "$REGISTRIES" | tr ',' ' ')"
      ;;
  esac

  # iterate over names and registries
  local name reg
  for name in $NAMES_COLLECTED; do
    for reg in $regs; do
      run_checks_for "$reg" "$name"
    done
  done
}

main "$@"
