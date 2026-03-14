#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix bash common-updater-scripts ripgrep

set -eou pipefail

PACKAGE_DIR="$(realpath "$(dirname "$0")")"
cd "$PACKAGE_DIR"
while ! test -f flake.nix; do cd ..; done
FLAKE_DIR="$PWD"

# Grayjay uses numeric tags (e.g. "17") on GitLab
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

# Update src hash
NEW_SRC_HASH=$(nix-prefetch-url --unpack "https://gitlab.futo.org/api/v4/projects/videostreaming%2FGrayjay%2EDesktop/repository/archive.tar.gz?sha=refs%2Ftags%2F${latestVersion}" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri)
sed -i -E "0,/hash\s*=\s*\"[^\"]+/{s@(hash\s*=\s*\")[^\"]+@\1${NEW_SRC_HASH}@}" "$PACKAGE_DIR"/default.nix

# Update npmDepsHash by invalidating it so nix rebuilds it
# (set to empty so the build error will show the correct hash — manual step)
echo "Note: npmDepsHash may need manual update if frontend dependencies changed."

# Set environment variables for the GitHub Actions workflow
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$latestVersion" >> "$GITHUB_ENV"
fi

echo "grayjay updated to $latestVersion"
