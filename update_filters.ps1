$urlsFile = "urls.txt"
$outputFile = "combined_filters.txt"

if (-Not (Test-Path $urlsFile)) {
    Write-Host "Error: $urlsFile not found. Please create it." -ForegroundColor Red
    exit
}

Write-Host "========================================="
Write-Host "  AdGuard Filter Updater (PowerShell)  "
Write-Host "========================================="

$urls = Get-Content $urlsFile | Where-Object { $_ -match "\S" -and $_ -notmatch "^#" }
Write-Host "URLs to process: $($urls.Count)`n"

# Statistics variables
$totalDownloaded = 0
$commentCount = 0
$emptyCount = 0
$allLines = New-Object System.Collections.Generic.List[string]
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($url in $urls) {
    Write-Host "Fetching: $url"
    try {
        $content = Invoke-RestMethod -Uri $url -Headers @{"User-Agent"="Mozilla/5.0"}
        $lines = $content -split "`r?`n"
        $totalDownloaded += $lines.Count
        
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            
            if ([string]::IsNullOrWhiteSpace($trimmed)) {
                $emptyCount++
                continue
            }
            if ($trimmed -match "^!|^\[" -or $trimmed -match "^#[^#@]") {
                $commentCount++
                continue
            }
            
            $allLines.Add($trimmed)
        }
        Write-Host "  -> SUCCESS ($($lines.Count) lines)" -ForegroundColor ASCII_GREEN
    } catch {
        Write-Host "  -> Failed to fetch ${url}: $_" -ForegroundColor Red
    }
}

Write-Host "`nProcessing rules..." -ForegroundColor Cyan
$totalValid = $allLines.Count

# HashSet to remove duplicates
$uniqueLines = New-Object System.Collections.Generic.HashSet[string]
foreach ($line in $allLines) {
    [void]$uniqueLines.Add($line)
}

$totalUnique = $uniqueLines.Count
$duplicatesRemoved = $totalValid - $totalUnique

Write-Host "Sorting rules..." -ForegroundColor Cyan
$sortedLines = $uniqueLines | Sort-Object

Write-Host "Saving to $outputFile..." -ForegroundColor Cyan
$outputPath = Join-Path (Get-Location) $outputFile
[System.IO.File]::WriteAllLines($outputPath, $sortedLines)

$stopwatch.Stop()

Write-Host "`n========================================="
Write-Host "              STATISTICS                 "
Write-Host "========================================="
Write-Host "Total URLs Processed   : $($urls.Count)"
Write-Host "Total Lines Downloaded : $totalDownloaded"
Write-Host "Comments Removed       : $commentCount"
Write-Host "Empty Lines Removed    : $emptyCount"
Write-Host "Valid Rules Found      : $totalValid"
Write-Host "Duplicates Removed     : $duplicatesRemoved"
Write-Host "Final Rules Count      : $totalUnique"
if ($totalValid -gt 0) {
    $spaceSaved = (($totalValid - $totalUnique) / $totalValid) * 100
    Write-Host "Deduplication Savings  : $($spaceSaved.ToString('F2'))%"
}
Write-Host "Execution Time         : $($stopwatch.Elapsed.TotalSeconds.ToString('F2')) seconds"
Write-Host "========================================="
