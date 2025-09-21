#!/usr/bin/env bash
set -euo pipefail
# Usage: scripts/scaffold/python.sh <name> <repo_root>

name="${1:?name}"; root="${2:?repo_root}"
pkg="${name//-/_}"
cd "$root"

# Skip if already a Python project
if [ -f pyproject.toml ] || [ -d "src/${pkg}" ]; then
  echo "Python: already initialized; skipping."
  exit 0
fi

mkdir -p "src/${pkg}"
cat > "src/${pkg}/__init__.py" <<'EOF'
__all__ = []
__version__ = "0.1.0"
EOF

cat > pyproject.toml <<EOF
[project]
name = "${name}"
version = "0.1.0"
description = ""
readme = "README.md"
requires-python = ">=3.10"
authors = [{name = "Suhail"}]

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"
EOF

# .gitignore additions
{
  grep -qxF '.venv/' .gitignore 2>/dev/null || echo '.venv/';
  grep -qxF '__pycache__/' .gitignore 2>/dev/null || echo '__pycache__/';
} >> .gitignore || true

echo "Python scaffold created."
