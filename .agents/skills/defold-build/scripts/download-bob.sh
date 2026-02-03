#!/bin/bash
# Download Defold bob.jar (Bash)
# No external dependencies except curl (standard on Linux/macOS)

set -e

BOB_DIR=".internal"
BOB_PATH="$BOB_DIR/bob.jar"

# Create directory if needed
mkdir -p "$BOB_DIR"

# Fetch stable info.json and extract SHA1 (no jq dependency)
echo "Fetching Defold stable version info..."
INFO_JSON=$(curl -s "https://d.defold.com/stable/info.json")
BOB_SHA1=$(echo "$INFO_JSON" | grep -o '"sha1"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
echo "Latest stable SHA1: $BOB_SHA1"

# Check local bob.jar version if exists
LOCAL_SHA1=""
if [ -f "$BOB_PATH" ]; then
    VERSION_OUTPUT=$(java -jar "$BOB_PATH" --version 2>&1 || true)
    LOCAL_SHA1=$(echo "$VERSION_OUTPUT" | grep -oE '[a-f0-9]{40}' | head -1 || true)
    echo "Local bob.jar SHA1: $LOCAL_SHA1"
fi

# Download if version mismatch or missing
if [ "$LOCAL_SHA1" != "$BOB_SHA1" ]; then
    BOB_URL="https://d.defold.com/archive/$BOB_SHA1/bob/bob.jar"
    echo "Downloading bob.jar from $BOB_URL..."
    curl -L -o "$BOB_PATH" "$BOB_URL"
    echo "Downloaded bob.jar to $BOB_PATH"
else
    echo "bob.jar is up to date"
fi

echo "Done. bob.jar ready at $BOB_PATH"
