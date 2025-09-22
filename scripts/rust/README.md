# truss — crate naming → bootstrap → publish

A concise, repeatable workflow to **name**, **create**, and **publish** a Rust crate using this repo’s scripts.

> TL;DR: brainstorm names → check availability → generate one‑liner + README → bootstrap repo → publish to crates.io → start coding.

---

## 0) Prereqs

- Tools: `gh`, `git`, `cargo` (optional: `op` for one‑shot tokens).
- Env: `$MATRIX` should point at your matrix root; default fallback is `~/Library/CloudStorage/Dropbox/matrix`.

---

## 1) Brainstorm names with ChatGPT

Use the prompt template at **`scripts/names/Prompt.md`** to generate 20–30 short, global‑pronounceable names. Keep 2–3 syllables, ASCII only, avoid collisions with your existing project names.

---

## 2) Check availability

Short‑list a few candidates and check on crates + PyPI with the helper script:

```bash
# example
scripts/names/namecheck.sh -r crates,pypi swivel liana stratum bus
```

Notes:
- **crates.io treats `-` and `_` as the same**; the script checks normalized variants.
- You can also sanity‑check with `cargo search <name>`.

Pick one that’s free on **crates** (PyPI is optional for now).

---

## 3) Lock the positioning (one‑liner + README)

Ask ChatGPT for a **one‑line description** and a minimal **README.md** for the new crate (keep tone crisp, include quick start). Save it locally, e.g.:

```
~/Downloads/<name>/README.md
```

---

## 4) Bootstrap the GitHub repo + crate

From this repo’s root (your truss repo), run the bootstrap script. Example for **swivel**:

```bash
scripts/rust/bootstrap_repo.sh   -u suhailphotos   -r swivel   -d "one trait, many databases: a tiny rust adapter layer for notion, supabase, and postgres"   -R "$HOME/Downloads/swivel/README.md"   -L MIT   -V public   -n swivel   -e 2021
```

What this does:
- Creates the GitHub repo (with LICENSE and a temporary README).
- Clones to `$MATRIX/crates/<repo>` by default.
- Runs `cargo init` (binary) and drops in `.gitignore` + a starter `src/main.rs`.
- Copies your downloaded README into the repo (via `-R`).
- Commits and pushes to `main`.

**Tip (optional):** If you prefer a **library** crate:
- Edit the script’s `cargo init` line to:
  ```bash
  cargo init --lib --name "${CARGO_NAME}" --edition "${EDITION}" --vcs none
  ```
- Or convert after bootstrap by moving code to `src/lib.rs` and putting a tiny CLI in `src/bin/<name>.rs`.

**Tip (placeholder text):** Update the `src/main.rs` here‑doc in the script to use `${CARGO_NAME:-$REPO}` instead of a hardcoded name.

---

## 5) Prepare for publish (Cargo.toml)

Add required metadata before publishing:

```toml
[package]
name = "swivel"                      # your chosen name
version = "0.1.0"
edition = "2021"
description = "One trait, many databases: a tiny Rust adapter layer for Notion, Supabase, and Postgres."
license = "MIT"
readme = "README.md"
repository = "https://github.com/suhailphotos/swivel"
keywords = ["database", "adapter", "traits", "notion", "supabase", "postgres"]
categories = ["database", "api-bindings"]

[dependencies]
# (add real deps later)
```

Verify the package contents:

```bash
cargo package --list
cargo publish --dry-run
```

---

## 6) Authenticate & publish to crates.io

1) Create an API token on crates.io (Account → API Tokens).

2) Login (persistent) **or** use a one‑shot env var:

```bash
# persistent
cargo login <YOUR_TOKEN>

# one-shot with 1Password
CARGO_REGISTRY_TOKEN="$(op read 'op://<vault>/<item>/token')" cargo publish --dry-run
```

3) Publish for real:

```bash
cargo publish
# or one-shot:
CARGO_REGISTRY_TOKEN="$(op read 'op://<vault>/<item>/token')" cargo publish
```

4) Tag the release in git (optional but recommended):

```bash
git tag v0.1.0 && git push --tags
```

> crates are immutable—bump the version (e.g., `0.1.1`) for the next publish.

---

## 7) Start coding

- For binaries: implement the CLI in `src/main.rs` (or `src/bin/<name>.rs`).
- For libraries: put public API in `src/lib.rs`, keep the CLI thin.
- Docs:
  ```bash
  cargo doc --open
  ```
- Tests:
  ```bash
  cargo test
  ```

---

## Quick checklist

- [ ] Names brainstormed (Prompt.md)
- [ ] Name available on crates
- [ ] One‑liner + README generated
- [ ] Repo bootstrapped and pushed
- [ ] Cargo.toml metadata filled
- [ ] crates.io token ready
- [ ] `cargo publish --dry-run` successful
- [ ] `cargo publish` done
- [ ] Tag pushed
- [ ] Begin implementation

---

## Troubleshooting

- **Name taken:** rerun availability with alternates; remember `-` vs `_` collide on crates.
- **`cargo publish --dry-run` fails:** check `Cargo.toml` for missing `description/license/readme`, or unintended files in the package (use `include`/`exclude` in `[package]`).
- **Binary vs library confusion:** pick one; you can still ship both by keeping lib code in `src/lib.rs` and a CLI in `src/bin/<name>.rs`.
