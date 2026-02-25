#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="$DIR/default.nix"
REPO="p-stream/p-stream-desktop"

echo "Fetching latest version from GitHub..."
LATEST_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

if [[ -z "$LATEST_VERSION" || "$LATEST_VERSION" == "null" ]]; then
    echo "Error: Could not fetch latest version"
    exit 1
fi

CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$FILE")

if [[ "$LATEST_VERSION" == "$CURRENT_VERSION" ]]; then
    echo "p-stream-desktop is already up-to-date: $CURRENT_VERSION"
    exit 0
fi

echo "Updating p-stream-desktop $CURRENT_VERSION -> $LATEST_VERSION..."

URL="https://github.com/$REPO/releases/download/$LATEST_VERSION/P-Stream-$LATEST_VERSION.AppImage"
echo "Prefetching AppImage to calculate new SHA256 hash..."
NEW_HASH=$(nix-prefetch-url --type sha256 --sri "$URL")

if [[ -z "$NEW_HASH" ]]; then
    echo "Error: Failed to prefetch URL"
    exit 1
fi

echo "Updating $FILE..."
sed -i -E "s|version = \"[^\"]+\"|version = \"$LATEST_VERSION\"|" "$FILE"
sed -i -E "s|hash = \"[^\"]+\"|hash = \"$NEW_HASH\"|" "$FILE"

echo "Successfully updated to $LATEST_VERSION with hash $NEW_HASH"
