# remove-keys.ps1 — clear your Scopus key from AI_Tools\my_keys.env (run at the end on a shared PC).
#   & "$env:USERPROFILE\AI_Workshop\remove-keys.ps1"
# Deleting the whole AI_Workshop folder (and the two desktop shortcuts) also removes everything.

$keys = Join-Path $PSScriptRoot 'AI_Tools\my_keys.env'
if (Test-Path $keys) {
    $clean = foreach ($line in Get-Content $keys) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=') { "$($Matches[1])=" } else { $line }
    }
    [IO.File]::WriteAllLines($keys, [string[]]$clean, (New-Object Text.UTF8Encoding $false))
}
Write-Host 'Keys cleared from AI_Tools\my_keys.env.' -ForegroundColor Green
