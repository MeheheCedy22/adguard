#!/bin/bash

URLS_FILE="urls.txt"
OUTPUT_FILE="combined_filters.txt"
TEMP_FILE="temp_filters.txt"
RAW_FILE="raw_filters.txt"

> "$TEMP_FILE"
> "$RAW_FILE"

echo "========================================="
echo "  AdGuard Filter Updater (Bash)  "
echo "========================================="

# Count URLs
URL_COUNT=$(grep -cvE '^[[:space:]]*$|^#' "$URLS_FILE")
echo -e "URLs to process: $URL_COUNT\n"

START_TIME=$(date +%s)
TOTAL_DOWNLOADED=0

while IFS= read -r url; do
    if [[ -z "$url" || "$url" == \#* ]]; then
        continue
    fi

    echo "Fetching: $url"
    
    # Download raw content
    curl -sL "$url" | tr -d '\r' > temp_dl.txt
    LINES_DL=$(wc -l < temp_dl.txt)
    TOTAL_DOWNLOADED=$((TOTAL_DOWNLOADED + LINES_DL))
    
    cat temp_dl.txt >> "$RAW_FILE"
    
    echo "  -> SUCCESS ($LINES_DL lines)"

done < "$URLS_FILE"
rm -f temp_dl.txt

echo -e "\nProcessing rules..."

# Statistics
EMPTY_COUNT=$(grep -c '^[[:space:]]*$' "$RAW_FILE")
COMMENT_COUNT=$(awk '/^!|^\[|^#[^#@]/ {print}' "$RAW_FILE" | wc -l)

# Filter rules
awk '!/^!|^\[|^#[^#@]/ && !/^[[:space:]]*$/' "$RAW_FILE" > "$TEMP_FILE"

TOTAL_VALID=$(wc -l < "$TEMP_FILE")

echo "Sorting rules and removing duplicates..."
sort -u "$TEMP_FILE" > "$OUTPUT_FILE"

TOTAL_UNIQUE=$(wc -l < "$OUTPUT_FILE")
DUPLICATES_REMOVED=$((TOTAL_VALID - TOTAL_UNIQUE))

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

# Cleanup
rm "$TEMP_FILE" "$RAW_FILE"

echo -e "\n========================================="
echo "              STATISTICS                 "
echo "========================================="
echo "Total URLs Processed   : $URL_COUNT"
echo "Total Lines Downloaded : $TOTAL_DOWNLOADED"
echo "Comments Removed       : $COMMENT_COUNT"
echo "Empty Lines Removed    : $EMPTY_COUNT"
echo "Valid Rules Found      : $TOTAL_VALID"
echo "Duplicates Removed     : $DUPLICATES_REMOVED"
echo "Final Rules Count      : $TOTAL_UNIQUE"

if [ "$TOTAL_VALID" -gt 0 ]; then
    # Bash doesn't do floating point math easily, use awk
    SAVINGS=$(awk "BEGIN {printf \"%.2f\", (($TOTAL_VALID - $TOTAL_UNIQUE) / $TOTAL_VALID) * 100}")
    echo "Deduplication Savings  : $SAVINGS%"
fi

echo "Execution Time         : $EXECUTION_TIME seconds"
echo "========================================="
