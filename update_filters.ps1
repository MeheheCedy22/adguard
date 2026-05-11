$urlsFile = "urls.txt"
$outputFile = "combined_filters.txt"

if (-Not (Test-Path $urlsFile)) {
    Write-Host "Error: $urlsFile not found. Please create it." -ForegroundColor Red
    exit
}

Write-Host "Reading URLs..." -ForegroundColor Cyan
$urls = Get-Content $urlsFile | Where-Object { $_ -match "\S" -and $_ -notmatch "^#" }

# A HashSet is used instead of a standard array to instantly eliminate duplicates
$combinedLines = New-Object System.Collections.Generic.HashSet[string]

foreach ($url in $urls) {
    Write-Host "Fetching: $url"
    try {
        # Download the raw text
        $content = Invoke-RestMethod -Uri $url -Headers @{"User-Agent"="Mozilla/5.0"}
        $lines = $content -split "`r?`n"
        
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            
            # Skip empty lines
            if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
            
            # Skip standard comments (! or [)
            if ($trimmed -match "^!|^\[") { continue }
            
            # Skip single '#' comments (preserves '##' and '#@#')
            if ($trimmed -match "^#[^#@]") { continue }
            
            # Add to HashSet (duplicates are ignored automatically)
            [void]$combinedLines.Add($trimmed)
        }
    } catch {
        Write-Host "  -> Failed to fetch ${url}: $_" -ForegroundColor Red
    }
}

Write-Host "Sorting and saving..." -ForegroundColor Cyan
$sortedLines = $combinedLines | Sort-Object -Unique

# Write to file using fast .NET method to handle massive line counts
$outputPath = Join-Path (Get-Location) $outputFile
[System.IO.File]::WriteAllLines($outputPath, $sortedLines)

Write-Host "Success! Saved to $outputFile" -ForegroundColor Green