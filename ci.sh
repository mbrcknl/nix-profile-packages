#!/usr/bin/env bash
set -euo pipefail

fallback_paths=$(nix run .#get-fallback-paths)
cat <<< "$fallback_paths" > nix/fallback-paths.nix

git add nix/fallback-paths.nix

if [ -n "$(git diff --cached)" ]; then
  git commit -m "ci: Update nix fallback paths" -m "[skip actions]"
fi

nix flake check --print-build-logs
