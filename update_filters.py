import urllib.request
import re
import os

URLS_FILE = "urls.txt"
OUTPUT_FILE = "combined_filters.txt"

# Regex patterns to catch comments safely
comment_pattern = re.compile(r'^!|^\[')      # Matches lines starting with ! or [
single_hash_pattern = re.compile(r'^#[^#@]') # Matches lines with single # (preserves ## and #@#)

# Using a set automatically and instantly removes duplicates
combined_lines = set() 

if not os.path.exists(URLS_FILE):
    print(f"Error: {URLS_FILE} not found. Please create it and add your URLs.")
    exit(1)

with open(URLS_FILE, 'r') as f:
    urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]

print("Downloading and processing filter lists...")

for url in urls:
    print(f"Fetching: {url}")
    try:
        # User-Agent added because some raw text hosts block empty agents
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            content = response.read().decode('utf-8', errors='ignore')
            
            for line in content.splitlines():
                line = line.strip()
                
                # Skip empty lines, standard comments, and single-hash comments
                if not line:
                    continue
                if comment_pattern.match(line):
                    continue
                if single_hash_pattern.match(line):
                    continue
                
                # Add to set (automatically drops duplicates)
                combined_lines.add(line)
                
    except Exception as e:
        print(f"  -> Error fetching {url}: {e}")

print("Sorting lists...")
sorted_lines = sorted(combined_lines)

print(f"Saving to {OUTPUT_FILE}...")
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    for line in sorted_lines:
        f.write(line + '\n')

print("Success! Final list compiled.")