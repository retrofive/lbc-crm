
# LBC-CRM Auto-Push Watcher
# Run this script while editing — it pushes to GitHub whenever LBC-CRM.html is saved.
# Usage: Right-click > Run with PowerShell, or: pwsh -File push-on-save.ps1

$dir  = $PSScriptRoot
$file = "LBC-CRM.html"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path   = $dir
$watcher.Filter = $file
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$watcher.EnableRaisingEvents = $true

Write-Host ""
Write-Host "  LBC-CRM Auto-Push" -ForegroundColor Cyan
Write-Host "  Watching: $dir\$file" -ForegroundColor Gray
Write-Host "  Remote:   https://github.com/retrofive/lbc-crm" -ForegroundColor Gray
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""

$lastPush = [datetime]::MinValue

while ($true) {
    $change = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::Changed, 3000)

    if (-not $change.TimedOut) {
        # Debounce — skip if we pushed within the last 4 seconds
        if (([datetime]::Now - $lastPush).TotalSeconds -lt 4) { continue }
        $lastPush = [datetime]::Now

        Start-Sleep -Milliseconds 600   # let the editor finish writing

        # Extract version number from the file
        $ver = ""
        $match = Select-String -Path "$dir\$file" -Pattern 'class="ver">v([\d.]+)' | Select-Object -First 1
        if ($match) { $ver = " v" + $match.Matches.Groups[1].Value }

        Set-Location $dir
        git add $file | Out-Null
        $result = git diff --cached --quiet 2>&1
        if ($LASTEXITCODE -ne 0) {
            git commit -m "Update LBC-CRM$ver" | Out-Null
            git push origin main 2>&1 | Out-Null
            Write-Host "  $(Get-Date -Format 'HH:mm:ss')  Pushed$ver to GitHub" -ForegroundColor Green
        } else {
            Write-Host "  $(Get-Date -Format 'HH:mm:ss')  No changes to push" -ForegroundColor DarkGray
        }
    }
}
