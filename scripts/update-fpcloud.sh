#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# The release every surface is published at (fogpipe ADR-169). Absent while one
# is still arriving, which is not a reason to move.
new="$(curl -fsS https://api.cloud.fogpipe.com/version | jq -r '.latest_release // empty')"
[[ -n "$new" ]] || exit 0

# The flake input tracks cloud-cli's `release` channel, which is that same
# version, so nix needs no number.
nix flake update cloud-cli

git diff --quiet -- flake.lock && exit 0
git commit flake.lock --message "fpcloud $new"
