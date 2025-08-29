#!/usr/bin/env -S bash

wallpaper="$1"
activated=0

# Iterate over home-manager generations
home-manager generations | while IFS= read -r line; do
  # Extract the first /nix/store/... path from the line
  path="$(grep -oE '/nix/store/[^ ]+' <<<"$line" | head -n1 || true)"

  # Skip if no path found on this line
  [[ -n "${path:-}" ]] || continue

  if [[ -d "$path/specialisation" ]]; then
    path="$path/specialisation"
    activate="$path/$wallpaper/activate"
    if [[ -x "$activate" ]]; then
      echo "activating now"
      "$activate"
      activated=1
      exit 0
    fi
  fi
done
exit 1
