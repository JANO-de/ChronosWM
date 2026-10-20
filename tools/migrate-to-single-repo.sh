#!/usr/bin/env bash
# Run on [DESKTOP]. Turns the niri fork into the ONE chronos repo (code + shell + docs).
# Old folders are kept (renamed), nothing is deleted.
set -euo pipefail
cd ~/Proyectos
[ -d niri/.git ] || { echo "no ~/Proyectos/niri fork"; exit 1; }
[ -d chronos/.git ] || { echo "no ~/Proyectos/chronos"; exit 1; }
git -C niri status --porcelain | grep -q . && { echo "commit/stash niri first"; exit 1; }
git -C chronos status --porcelain | grep -q . && { echo "commit/stash chronos first"; exit 1; }

# 1. archive old chronos folder (clears the name)
mv chronos chronos-old

# 2. bring non-compositor parts into the fork
cd niri
mkdir -p handoffs
cp -r ../chronos-old/shell ../chronos-old/docs ../chronos-old/nix .
cp ../chronos-old/HANDOFF-*.md handoffs/ 2>/dev/null || true
# compositor/ is NOT copied: patches are already applied in this fork, and
# gesture-core lives at ./chronos-gesture-core (single copy, workspace member).

# 3. single source of truth for the recognizer
test -f chronos-gesture-core/src/lib.rs || { echo "missing chronos-gesture-core in fork"; exit 1; }
diff -q ../chronos-old/compositor/gesture-core/src/lib.rs chronos-gesture-core/src/lib.rs || \
  echo "NOTE: gesture-core copies differ; copy the delivered lib.rs over chronos-gesture-core/src/lib.rs"

git add -A && git commit -m "chronos: merge shell, docs, nix, handoffs into the fork (single repo)"

# 4. rename the fork dir; keep upstream remote for rebases
cd ~/Proyectos && mv niri chronos
git -C chronos remote get-url upstream >/dev/null 2>&1 || \
  git -C chronos remote add upstream https://github.com/YaLTeR/niri.git

# 5. repoint MyNixOS
cd ~/Proyectos/MyNixOS
sed -i 's#git+file:///home/jano/Proyectos/niri#git+file:///home/jano/Proyectos/chronos#' flake.nix
grep -n 'chronos.url' flake.nix
echo "Now: nix flake update chronos && nixos-rebuild as usual."
