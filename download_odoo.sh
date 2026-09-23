#!/bin/bash
set -e

FILE_ID="$1"
OUTPUT="odoo.tar.gz"

echo "Downloading odoo source from Google Drive..."
echo "File ID: $FILE_ID"

# Handle Google Drive's "virus scan" confirmation for files >100MB
COOKIE_FILE=$(mktemp)
curl -sc "$COOKIE_FILE" "https://drive.google.com/uc?export=download&id=${FILE_ID}" > /dev/null

CONFIRM=$(grep -oP 'confirm=\K[^&]+' "$COOKIE_FILE" || true)

if [ -n "$CONFIRM" ]; then
    echo "Large file detected, using confirmation token..."
    curl -Lb "$COOKIE_FILE" \
         "https://drive.google.com/uc?export=download&confirm=${CONFIRM}&id=${FILE_ID}" \
         -o "$OUTPUT"
else
    curl -L "https://drive.google.com/uc?export=download&id=${FILE_ID}" -o "$OUTPUT"
fi

# Verify it's a valid gzip
if ! file "$OUTPUT" | grep -q "gzip"; then
    echo "ERROR: Downloaded file is not gzip. Google Drive may have returned an HTML error page."
    head -c 500 "$OUTPUT"
    exit 1
fi

echo "Extracting..."
tar -xzf "$OUTPUT"
rm -f "$OUTPUT"

echo "Done. Odoo folder size:"
du -sh odoo/
