#!/usr/bin/env bash
set -euo pipefail

fallback_paths="$(nix build --print-out-paths --no-link .#fallback-paths)"
cp "$fallback_paths" nix/fallback-paths.nix

git add nix/fallback-paths.nix

if [ -n "$(git diff --cached)" ]; then
  git commit -m "ci: Update nix fallback paths" -m "[skip actions]"
fi

nix flake check --print-build-logs
