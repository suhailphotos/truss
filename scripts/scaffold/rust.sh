#!/usr/bin/env bash
set -euo pipefail
# Usage: scripts/scaffold/rust.sh <name> <repo_root>

name="${1:?name}"; root="${2:?repo_root}"
cd "$root"

# Only scaffold if no Cargo project yet
if [ -f Cargo.toml ]; then
  echo "Rust: Cargo.toml already exists; skipping."
  exit 0
fi

mkdir -p src
cat > Cargo.toml <<EOF
[package]
name = "${name//-/_}"
version = "0.1.0"
edition = "2021"

[dependencies]
EOF

cat > src/main.rs <<'EOF'
fn main() {
    println!("hello, world");
}
EOF

# .gitignore additions
{ grep -qxF '/target' .gitignore 2>/dev/null || echo '/target'; } >> .gitignore || true

echo "Rust scaffold created."
