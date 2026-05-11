#!/bin/bash

URLS_FILE="urls.txt"
OUTPUT_FILE="combined_filters.txt"
TEMP_FILE="temp_filters.txt"

# Clear previous temp file if it exists
> "$TEMP_FILE"

echo "Downloading and processing filter lists..."

while IFS= read -r url; do
    # Skip empty lines or commented lines in the urls.txt
    if [[ -z "$url" || "$url" == \#* ]]; then
        continue
    fi

    echo "Fetching: $url"
    
    # Process the downloaded list:
    # 1. tr -d '\r'          : Removes Windows carriage returns to prevent formatting issues
    # 2. sed '/^!/d'         : Removes standard AdBlock comments starting with '!'
    # 3. sed '/^\[/d'        : Removes metadata headers starting with '['
    # 4. sed '/^#[^#@]/d'    : Removes single '#' comments but PRESERVES '##' and '#@#' rules
    # 5. sed '/^[[:space:]]*$/d' : Removes completely empty lines
    
    curl -sL "$url" | tr -d '\r' | \
    sed -e '/^!/d' -e '/^\[/d' -e '/^#[^#@]/d' -e '/^[[:space:]]*$/d' >> "$TEMP_FILE"

done < "$URLS_FILE"

echo "Sorting and removing duplicates..."
# Sort the combined file and remove exact duplicates
sort -u "$TEMP_FILE" > "$OUTPUT_FILE"

# Clean up the temporary file
rm "$TEMP_FILE"

echo "Success! Final list saved to $OUTPUT_FILE"