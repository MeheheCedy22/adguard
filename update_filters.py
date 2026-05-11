import urllib.request
import re
import os
import time
import shutil

URLS_FILE = "urls.txt"
OUTPUT_FILE = "combined_filters.txt"
FILTERS_DIR = "filters"

# Regex patterns to catch comments safely
comment_pattern = re.compile(r'^!|^\[')      # Matches lines starting with ! or [
single_hash_pattern = re.compile(r'^#[^#@]') # Matches lines with single # (preserves ## and #@#)

# Using a list first to count total lines, then set for deduplication
all_lines = []
comment_count = 0
empty_count = 0
total_downloaded = 0
start_time = time.time()

if not os.path.exists(URLS_FILE):
    print(f"Error: {URLS_FILE} not found. Please create it and add your URLs.")
    exit(1)

with open(URLS_FILE, 'r') as f:
    urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]

print("=========================================")
print("  AdGuard Filter Updater (Python)  ")
print("=========================================")
print(f"URLs to process: {len(urls)}\n")

# Clear existing filters directory to prevent duplicates/old files
if os.path.exists(FILTERS_DIR):
    print(f"Cleaning up existing '{FILTERS_DIR}' folder...")
    shutil.rmtree(FILTERS_DIR)
os.makedirs(FILTERS_DIR, exist_ok=True)

for i, url in enumerate(urls, 1):
    print(f"Fetching: {url}")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            content = response.read().decode('utf-8', errors='ignore')
            
            # Save raw file, prefix with index to ensure no duplicate filenames
            raw_filename = url.split('/')[-1]
            if not raw_filename or '?' in raw_filename:
                raw_filename = "filter.txt"
            
            safe_filename = f"{i}_{raw_filename}"
            raw_filepath = os.path.join(FILTERS_DIR, safe_filename)
            
            with open(raw_filepath, 'w', encoding='utf-8') as raw_file:
                raw_file.write(content)
            
            lines = content.splitlines()
            total_downloaded += len(lines)
            
            for line in lines:
                line = line.strip()
                
                # Count and skip empty lines
                if not line:
                    empty_count += 1
                    continue
                # Count and skip standard comments
                if comment_pattern.match(line):
                    comment_count += 1
                    continue
                # Count and skip single-hash comments
                if single_hash_pattern.match(line):
                    comment_count += 1
                    continue
                
                # Add valid rules
                all_lines.append(line)
                
        print(f"  -> SUCCESS ({len(lines)} lines) - Saved to {raw_filepath}")
                
    except Exception as e:
        print(f"  -> ERROR fetching {url}: {e}")

print("\nProcessing rules...")
total_valid = len(all_lines)
unique_lines = set(all_lines)
total_unique = len(unique_lines)
duplicates_removed = total_valid - total_unique

print("Sorting rules...")
sorted_lines = sorted(unique_lines)

print(f"Saving to {OUTPUT_FILE}...")
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    for line in sorted_lines:
        f.write(line + '\n')

end_time = time.time()
execution_time = end_time - start_time

print("\n=========================================")
print("              STATISTICS                 ")
print("=========================================")
print(f"Total URLs Processed   : {len(urls)}")
print(f"Total Lines Downloaded : {total_downloaded:,}")
print(f"Comments Removed       : {comment_count:,}")
print(f"Empty Lines Removed    : {empty_count:,}")
print(f"Valid Rules Found      : {total_valid:,}")
print(f"Duplicates Removed     : {duplicates_removed:,}")
print(f"Final Rules Count      : {total_unique:,}")
if total_valid > 0:
    space_saved = ((total_valid - total_unique) / total_valid) * 100
    print(f"Deduplication Savings  : {space_saved:.2f}%")
print(f"Execution Time         : {execution_time:.2f} seconds")
print("=========================================")
