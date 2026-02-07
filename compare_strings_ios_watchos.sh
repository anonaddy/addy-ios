#!/bin/bash

# Configuration - Hardcoded Paths
OS_EN="addy/Localizable.xcstrings"
WATCH_EN="addy_watchkit/Localizable.xcstrings"
OUTPUT="duplicate_keys.txt"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install it (e.g., 'brew install jq')."
    exit 1
fi

# Verify files exist
if [[ ! -f "$OS_EN" ]]; then
    echo "Error: File not found at $OS_EN"
    exit 1
fi

if [[ ! -f "$WATCH_EN" ]]; then
    echo "Error: File not found at $WATCH_EN"
    exit 1
fi

echo "Searching for duplicate keys between OS and Watch catalogs (excluding 'MOVED TO SHARED')..."

# Extract keys excluding entries where comment == "MOVED TO SHARED"
extract_keys() {
    jq -r '.strings 
        | to_entries 
        | map(select(.value.comment != "MOVED TO SHARED")) 
        | map(.key)[]' "$1" | sort
}

# Compare and find common keys
comm -12 <(extract_keys "$OS_EN") <(extract_keys "$WATCH_EN") > "$OUTPUT"

# Results output
if [ -s "$OUTPUT" ]; then
    COUNT=$(wc -l < "$OUTPUT" | xargs)
    echo "Success: $COUNT duplicate keys found."
    echo "Results saved to: $OUTPUT"
    echo "--- Common Keys ---"
    cat "$OUTPUT"
else
    echo "Clean sweep! No duplicate keys found between the two files."
    [ -f "$OUTPUT" ] && rm "$OUTPUT"
fi
