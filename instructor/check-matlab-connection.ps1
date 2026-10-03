<# Verify the pinned MATLAB MCP server and configure the two local project folders.
   Does not change global IDE settings, PATH, or user environment variables. #>
param([string]$MatlabRoot)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path $PSScriptRoot -Parent
$setupPath = Join-Path $workspace 'setup.ps1'
$setupText = Get-Content -LiteralPath $setupPath -Raw
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($setupPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'setup.ps1 could not be parsed.' }
# Reuse the installer's protocol client without executing the installer.
$helperNames = @('Get-MatlabRelease', 'Find-MatlabRoots', 'Format-Arg', 'Start-McpSession',
    'Send-McpRequest', 'Send-McpNotification', 'Stop-McpSession', 'Initialize-Mcp', 'Get-ToolText')
$helpers = $ast.FindAll({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in $helperNames
}, $true)
if ($helpers.Count -ne $helperNames.Count) { throw 'Required installer helpers were not found.' }
foreach ($helper in $helpers) { Invoke-Expression $helper.Extent.Text }
if (-not $MatlabRoot) {
    $MatlabRoot = Find-MatlabRoots | Sort-Object { Get-MatlabRelease $_ } -Descending | Select-Object -First 1
}
if (-not $MatlabRoot -or -not (Test-Path -LiteralPath (Join-Path $MatlabRoot 'bin\matlab.exe'))) {
    throw 'A working MATLAB installation was not found.'
}
$pin = [regex]::Match($setupText, "MatlabMcp\s*=\s*'([^']+)'").Groups[1].Value
if (-not $pin) { throw 'The MATLAB MCP version pin was not found.' }
$serverDir = Join-Path $workspace '.tools\mcp\matlab'
$logDir = Join-Path $workspace '.tools\log'
$serverExe = Join-Path $serverDir 'matlab-mcp-server.exe'
$marker = Join-Path $serverDir 'VERSION'
New-Item -ItemType Directory -Path $serverDir,$logDir -Force | Out-Null
if (-not (Test-Path -LiteralPath $serverExe) -or -not (Test-Path -LiteralPath $marker) -or
    (Get-Content -LiteralPath $marker -Raw).Trim() -ne $pin) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/matlab/matlab-mcp-server/releases/download/$pin/matlab-mcp-server-windows-x64.exe" -OutFile $serverExe
    Unblock-File -LiteralPath $serverExe
    Set-Content -LiteralPath $marker -Value $pin -Encoding ASCII
}
$raceDir = Join-Path $workspace 'AI_Grand_Prix'
$server = @{command=$serverExe; args=@("--matlab-root=$MatlabRoot",
    "--initial-working-folder=$raceDir", '--matlab-display-mode=nodesktop', "--log-folder=$logDir")}
$session = $null
try {
    $session = Start-McpSession $server
    $tools = @(Initialize-Mcp $session 60)
    $evaluate = $tools | Where-Object { $_.name -eq 'evaluate_matlab_code' } | Select-Object -First 1
    if (-not $evaluate) { throw 'The MATLAB evaluation tool was not offered.' }
    $code = "cd('$($raceDir -replace "'", "''")'); r = practiceRace('Headless', true); " +
        "fprintf('AIW_RELEASE=%s\n',version('-release')); " +
        "fprintf('AIW_RESULT finished=%d time=%.2f score=%.2f\n',r.finished,r.totalTime,r.score);"
    $toolArgs = @{}
    foreach ($required in @($evaluate.inputSchema.required)) {
        if ($required -match 'code') { $toolArgs[$required] = $code }
        elseif ($required -match 'path|folder|dir') { $toolArgs[$required] = $raceDir }
    }
    if (-not $toolArgs.Count) { $toolArgs['code'] = $code }
    $result = Send-McpRequest $session 'tools/call' @{name=$evaluate.name; arguments=$toolArgs} 420
    $resultText = Get-ToolText $result
    if ($result.isError -or $resultText -notmatch 'AIW_RESULT finished=1 time=([\d.]+) score=([\d.]+)') {
        throw "MATLAB MCP validation failed: $resultText"
    }
    $raceTime = [double]$Matches[1]
    $raceScore = [double]$Matches[2]
    $releaseMatch = [regex]::Match($resultText, 'AIW_RELEASE=(\S+)')
    if ($releaseMatch.Groups[1].Value.TrimStart('R') -ne (Get-MatlabRelease $MatlabRoot).TrimStart('R')) {
        throw 'The MCP server started a different MATLAB release than requested.'
    }
    Write-Host "MATLAB MCP passed: $($releaseMatch.Groups[1].Value), $raceTime s, score $raceScore; $($tools.Count) tools."
} finally {
    if ($session) { Stop-McpSession $session }
}
# Keep any other configured servers and change only the matlab entry.
$utf8 = New-Object Text.UTF8Encoding $false
foreach ($folder in 'AI_Tools','AI_Grand_Prix') {
    $project = Join-Path $workspace $folder
    $configPath = Join-Path $project '.agents\mcp_config.json'
    $config = if (Test-Path -LiteralPath $configPath) { Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json } else { New-Object PSObject }
    if (-not $config.mcpServers) { $config | Add-Member -NotePropertyName mcpServers -NotePropertyValue (New-Object PSObject) -Force }
    $entry = [pscustomobject]@{command=$serverExe; args=@("--matlab-root=$MatlabRoot",
        "--initial-working-folder=$project", '--matlab-display-mode=desktop', "--log-folder=$logDir")}
    $config.mcpServers | Add-Member -NotePropertyName matlab -NotePropertyValue $entry -Force
    New-Item -ItemType Directory -Path (Split-Path $configPath -Parent) -Force | Out-Null
    [IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 20), $utf8)
    Write-Host "Configured MATLAB in $folder\.agents\mcp_config.json"
}
$report = [ordered]@{matlabRoot=$MatlabRoot; release=$releaseMatch.Groups[1].Value; serverVersion=$pin;
    toolCount=$tools.Count; baselineTime=$raceTime; baselineScore=$raceScore; passed=$true}
[IO.File]::WriteAllText((Join-Path $logDir 'matlab-mcp-check.json'), ($report | ConvertTo-Json), $utf8)
