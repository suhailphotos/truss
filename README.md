# truss

**truss** is my home for small, sharp **cross‑platform shell scripts**—bootstrap helpers, project generators, formatters, and one‑off utilities that hold the rest of my stack together.

> target shells: POSIX-friendly Bash (macOS 3.2+ compatible), Zsh. Scripts avoid Bash‑4+ features unless noted.

## layout

```
truss/
├─ bin/                # optional wrappers/symlinks
├─ lib/
│  └─ common.sh        # helpers: require_cmd, info/warn/die, OS detect
├─ scripts/
│  ├─ hello.sh         # sample; sources lib/common.sh
│  └─ (your categories here: cargo/, python/, system/, uv/, git/, etc.)
├─ tools/
│  ├─ fmt.sh           # runs shfmt
│  └─ lint.sh          # runs shellcheck
├─ .editorconfig
├─ .gitignore
└─ README.md
```

## quick start

Clone the repo, then:

```sh
# lint everything (requires shellcheck)
tools/lint.sh

# format everything (requires shfmt)
tools/fmt.sh

# run the sample
scripts/hello.sh
```

## add a new script

Use the generator to scaffold a script in a category:

```sh
# Example: create scripts/cargo/bootstrap_repo.sh
tools/new.sh cargo bootstrap_repo
```

The template sets up:

- `set -euo pipefail`
- repository root detection
- sourcing `lib/common.sh`
- a `main()` entry point

## common helpers

`lib/common.sh` is sourced by all scripts and provides:

- `require_cmd <cmd>` — exit if a command is missing
- `info "<msg>"` — friendly log line
- `warn "<msg>"` — non-fatal warning
- `die "<msg>"` — print message and exit 1
- `OS` — `macOS`, `linux`, or `unknown` (simple uname-based detect)

Example:

```sh
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
. "$ROOT_DIR/lib/common.sh"

main() {
  require_cmd git
  info "running on $OS"
  # ...
}

main "$@"
```

## conventions

- Keep scripts **POSIX‑ish** and macOS Bash‑3.2 compatible (no `${var,,}`, no associative arrays).
- Prefer **plain Bash**; when Zsh‑only features are required, call it out in a header comment.
- Group scripts by **category** under `scripts/<category>/name.sh`.
- Avoid hard‑coding paths—prefer envs (e.g. `$MATRIX`) and discovery.
- Always lint/format before committing: `tools/lint.sh` and `tools/fmt.sh`.

## external tools

- `shellcheck` — lint (`brew install shellcheck` on macOS)
- `shfmt` — format (`brew install shfmt` or `go install mvdan.cc/sh/v3/cmd/shfmt@latest`)

## security notes

- Scripts that need secrets should read them from the environment or a secret manager (e.g. `op read ...`) and must **never** commit tokens or write them into git remotes accidentally.

## license

MIT
