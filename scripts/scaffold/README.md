# scaffold

Tiny, type-specific project scaffolders that the generic bootstrap script can call.
If you don’t pass a type, nothing is scaffolded.

## Where to run from

```bash
# default location of this repo
cd "${MATRIX:-$HOME/Library/CloudStorage/Dropbox/matrix}/truss"
```
> If you keep `truss` somewhere else, `cd` there instead.

## Prereqs

- `gh` (GitHub CLI), `git`
- Optional: `op` (1Password CLI) to set/push with a tokenized remote (no username prompts).

## The bootstrap (entry point)

`./scripts/bootstrap/bootstrap_repo_generic.sh` creates the remote repo on GitHub (with **MIT** license + **README**), clones locally, optionally replaces the README, sets a tokenized remote using your 1Password secret, optionally runs a **scaffolder** by type, then commits and pushes.

### Flags (same for all types)

- `-u` GitHub username (required)
- `-r` repo name (required)
- `-d` one‑line description
- `-R` path to a local `README.md` to copy over
- `-V` visibility: `public|private` (default `public`)
- `-O` 1Password item path for your token (e.g., `op://devTools/GitHub Repo Key/secret key`)
- `-p` custom clone path (default is `${MATRIX}/<repo>`)
- `-t` project type: `plain|rust|python|scripts` (default `plain` → **no scaffolding**)

---

## Common examples

### 1) Plain repo (no scaffolding)
```bash
./scripts/bootstrap/bootstrap_repo_generic.sh \
  -u suhailphotos \
  -r atrium \
  -d "Home-level dotfiles with stow; non-XDG under ~ (see bindu for ~/.config)" \
  -R "/Users/suhail/Documents/Scratch/notes/README.md" \
  -O "op://devTools/GitHub Repo Key/secret key" \
  -V public
```

### 2) Rust crate (runs `scripts/scaffold/rust.sh`)
```bash
./scripts/bootstrap/bootstrap_repo_generic.sh \
  -u suhailphotos \
  -r mycrate \
  -t rust \
  -d "Rust crate for XYZ" \
  -R "/Users/suhail/Documents/Scratch/notes/README.md" \
  -O "op://devTools/GitHub Repo Key/secret key" \
  -V public
```

### 3) Python package (runs `scripts/scaffold/python.sh`)
```bash
./scripts/bootstrap/bootstrap_repo_generic.sh \
  -u suhailphotos \
  -r mypkg \
  -t python \
  -d "Python lib for ABC" \
  -R "/Users/suhail/Documents/Scratch/notes/README.md" \
  -O "op://devTools/GitHub Repo Key/secret key" \
  -V public
```

### 4) Shell scripts toolkit (runs `scripts/scaffold/scripts.sh`)
```bash
./scripts/bootstrap/bootstrap_repo_generic.sh \
  -u suhailphotos \
  -r truss-tools \
  -t scripts \
  -d "Shell scripts toolkit" \
  -R "/Users/suhail/Documents/Scratch/notes/README.md" \
  -O "op://devTools/GitHub Repo Key/secret key" \
  -V public
```

### 5) Custom destination (optional)
```bash
./scripts/bootstrap/bootstrap_repo_generic.sh \
  -u suhailphotos \
  -r sandbox \
  -t plain \
  -d "Scratch repo" \
  -R "/Users/suhail/Documents/Scratch/notes/README.md" \
  -O "op://devTools/GitHub Repo Key/secret key" \
  -V private \
  -p "$HOME/dev/sandbox"
```

---

## What each scaffolder does

All scaffolders are **idempotent**: they won’t overwrite if a project already exists.

### `scripts/scaffold/rust.sh <name> <repo_root>`
- Creates `Cargo.toml`, `src/main.rs`, and appends `/target` to `.gitignore` (if missing).
- Uses `<name>` (with `-` converted to `_`) for the crate name.
- Skips if `Cargo.toml` already exists.

### `scripts/scaffold/python.sh <name> <repo_root>`
- Creates `pyproject.toml` (PEP 621), `src/<name>/__init__.py`.
- Appends `.venv/` and `__pycache__/` to `.gitignore` (if missing).
- Skips if `pyproject.toml` or `src/<name>` already exists.

### `scripts/scaffold/scripts.sh <name> <repo_root>`
- Creates `scripts/ lib/ tools/ bin/`, a minimal `.editorconfig`, `.gitignore`, and example scripts.
- Skips existing files; safe to re-run.

Make sure they’re executable:
```bash
chmod +x scripts/scaffold/{rust.sh,python.sh,scripts.sh}
```

---

## Private repos and tokens

If you pass `-O` and have `op` installed, the bootstrap will:
- Rewrite `origin` to `https://x-access-token:<TOKEN>@github.com/<user>/<repo>.git` **before the first push**.
- This prevents the interactive username/password prompt.

If you skip `-O`, ensure `gh auth login` and a suitable credential helper are already set up.

---

## Defaults recap

- Clone path: `${MATRIX}/<repo>` (defaults to `~/Library/CloudStorage/Dropbox/matrix/<repo>` if `MATRIX` is unset).
- License: **MIT**, README added at repo creation.
- No scaffolding unless `-t` is `rust|python|scripts`.

---

## Extend with a new scaffolder

Add a new script under `scripts/scaffold/<type>.sh`, make it executable, and call the bootstrap with `-t <type>`. The bootstrap invokes it as:

```bash
scripts/scaffold/<type>.sh "<repo_name>" "<absolute_repo_root>"
```

Keep it idempotent (skip if files already exist).

---

**Tip:** To keep commands short, you can export your token path once per shell session:
```bash
export OP_SECRET_DEFAULT="op://devTools/GitHub Repo Key/secret key"
```

