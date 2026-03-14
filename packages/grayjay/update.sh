#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix bash common-updater-scripts ripgrep gnused nix-prefetch-git

set -eou pipefail

PACKAGE_DIR="$(realpath "$(dirname "$0")")"
cd "$PACKAGE_DIR"
while ! test -f flake.nix; do cd ..; done
FLAKE_DIR="$PWD"

# Grayjay uses numeric tags (e.g. "17", "18") on GitLab
latestVersion=$(
    curl --fail --silent "https://gitlab.futo.org/api/v4/projects/videostreaming%2FGrayjay%2EDesktop/repository/tags?per_page=100" |
    jq -r '.[].name' |
    rg '^\d+$' |
    sort --version-sort |
    tail -n1
)

currentVersion=$(nix eval --raw ".#grayjay.version")

if [[ "$currentVersion" == "$latestVersion" ]]; then
    echo "grayjay is up-to-date: $currentVersion"
    exit 0
fi

echo "Updating grayjay: $currentVersion -> $latestVersion"

# Update version in default.nix
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${latestVersion}@" "$PACKAGE_DIR"/default.nix

# Fetch new source hash using nix-prefetch-git (supports submodules + LFS)
echo "Fetching correct source hash (this may take a while)..."
PREFETCH_JSON=$(nix-prefetch-git \
    --url "https://gitlab.futo.org/videostreaming/Grayjay.Desktop" \
    --rev "refs/tags/${latestVersion}" \
    --fetch-submodules \
    --fetch-lfs \
    2>/dev/null)

NEW_SRC_HASH=$(echo "$PREFETCH_JSON" | jq -r '.hash')

if [[ -z "$NEW_SRC_HASH" || "$NEW_SRC_HASH" == "null" ]]; then
    echo "Error: Could not determine new source hash."
    sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${currentVersion}@" "$PACKAGE_DIR"/default.nix
    exit 1
fi

echo "New source hash: $NEW_SRC_HASH"

# Update the first hash = "..." occurrence (the src hash, not npmDepsHash)
sed -i -E "0,/hash\s*=\s*\"[^\"]+/{s@(hash\s*=\s*\")[^\"]+@\1${NEW_SRC_HASH}@}" "$PACKAGE_DIR"/default.nix

# Set environment variables for the GitHub Actions workflow
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$latestVersion" >> "$GITHUB_ENV"
fi

echo "grayjay updated to $latestVersion"
