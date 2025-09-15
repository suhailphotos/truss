#!/usr/bin/env zsh
# --- CONFIG: where your active Pixi global manifest is linked ---
manifest="$HOME/.pixi/manifests/pixi-global.toml"

# 1) Get env names from Pixi manifest (e.g., ffmpeg, imagemagick, libvips, …)
pixi_envs=(${(f)"$(grep -E '^\[envs\.' "$manifest" \
  | sed -E 's/^\[envs\.([^]]+)\].*/\1/' \
  | sort -u)"})

print -P "%F{cyan}Pixi envs (from manifest):%f ${pixi_envs[*]}"

# 2) Map Pixi names → Homebrew formula names (libvips -> vips, others same)
brew_candidates=("${(@)pixi_envs/#libvips/vips}")

# 3) What’s actually installed via Homebrew?
installed=(${(f)"$(brew list --formula 2>/dev/null)"})
overlap=()
for pkg in "${brew_candidates[@]}"; do
  if printf '%s\n' "${installed[@]}" | grep -Fxq "$pkg"; then
    overlap+=("$pkg")
  fi
done

if (( ${#overlap} )); then
  print -P "%F{yellow}Overlap (installed by Homebrew AND declared in Pixi):%f ${overlap[*]}"
else
  print -P "%F{green}No overlap found.%f"
fi

# 4) Show reverse deps so you don’t break other brew formulas
if (( ${#overlap} )); then
  echo
  echo "Homebrew dependents (if any):"
  for pkg in "${overlap[@]}"; do
    uses="$(brew uses --installed --recursive "$pkg" | paste -sd' ' -)"
    printf '  %-15s -> %s\n' "$pkg" "${uses:-(none)}"
  done
fi

# 5) If you’re happy with the list, uncomment the block below to uninstall.
#    This skips anything that other Homebrew formulas depend on.

#: <<'UNINSTALL'
#for pkg in "${overlap[@]}"; do
#  if [[ -n "$(brew uses --installed --recursive "$pkg")" ]]; then
#    print -P "%F{red}Skipping%f $pkg (other brew pkgs depend on it)"
#    continue
#  fi
#  print -P "%F{magenta}Uninstalling%f $pkg (Homebrew)…"
#  brew uninstall "$pkg"
#done
#UNINSTALL
