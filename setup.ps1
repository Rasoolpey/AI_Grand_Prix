<#
=============================================================================
 setup.ps1 — AI Workshop one-command setup for Windows (VS Code + Google Antigravity extension)
=============================================================================

 Download the repo ZIP, extract it (e.g. into Documents), open a terminal in the
 extracted AI_Grand_Prix-main folder and paste (no admin rights needed):

     irm https://raw.githubusercontent.com/Rasoolpey/AI_Grand_Prix/main/setup.ps1 | iex

 SELF-CONTAINED: everything lives in ONE folder: the extracted folder itself when
 run inside it, otherwise %USERPROFILE%\AI_Workshop.
 Nothing is written to PATH or environment variables. Outside the folder:
   - the Google Antigravity extension, added to YOUR VS Code (per user, no admin);
   - the workshop's MCP servers, MERGED into %USERPROFILE%\.gemini\config\mcp_config.json
     (Antigravity only loads MCP servers from that global file or from plugins, NOT from a
     workspace .agents\mcp_config.json). Your own servers are kept; a .bak is saved first.
 To uninstall, delete the folder and the two desktop shortcuts, and remove the entries
 matlab, google-scholar, scopus, markitdown from that mcp_config.json (and the extension if you like).

     AI_Grand_Prix-main\  (or AI_Workshop\)
       AI_Tools\        Part 1 workspace: AI tools + research   (my_keys.env = YOUR Scopus key; skills)
       AI_Grand_Prix\   Part 2 workspace: the race              (skills)
       .tools\          uv, a private Python, all MCP servers, Docling, logs (you never need to open this)

 Steps:
   1. Find MATLAB                         6. Your Scopus key -> AI_Tools\my_keys.env
   2. Workshop files                      7. Global MCP config + per-workspace skills
   3. uv + private Python                 8. Self-test (MCP servers, Scopus Q1 search, Docling, a baseline race)
   4. MATLAB MCP Server (MathWorks)       9. VS Code extension + desktop shortcuts
   5. Google Scholar, Scopus, MarkItDown + Docling (PDF -> text) for the skills' scripts

 Safe to run again — it never overwrites your own work.

 Optional settings (set BEFORE running, e.g.  $env:AIW_DIR = "D:\ai"):
   AIW_DIR              workshop folder              (default: the extracted folder, else %USERPROFILE%\AI_Workshop)
   AIW_MATLAB_ROOT      MATLAB folder, if auto-detect picks the wrong one
   AIW_SKIP_TEST=1      skip the self-test (MATLAB start-up takes ~1-2 min)
   AIW_LOCAL_WORKSHOP   copy AI_Tools + AI_Grand_Prix from this local folder instead of GitHub (testing)
   AIW_REPO_BRANCH      GitHub branch to download   (default main)
   AIW_NO_SHORTCUTS=1   don't create desktop shortcuts
   AIW_NO_EXTENSION=1   don't install the Google Antigravity extension in VS Code
   AIW_NO_DOCLING=1     skip Docling (~1 GB + 0.7 GB models); the literature review then uses MarkItDown
   AIW_MCP_CONFIG       MCP config file to merge the servers into (default %USERPROFILE%\.gemini\config\mcp_config.json)
   AIW_LOG_DIR          log folder (default .tools\log; %LOCALAPPDATA%\AIW\log when that path is too long)
   AIW_KEYS_FILE        a workshop_keys.env to read the Scopus key from (default: searched for)
   SCOPUS_API_KEY / SCOPUS_INST_TOKEN
                        written to AI_Tools\my_keys.env instead of asking (otherwise a key
                        already in that file is re-used, or you are asked)
=============================================================================
#>

function Install-AIWorkshop {
    param(
        [string]$WorkshopDir = $env:AIW_DIR,
        [string]$MatlabRoot  = $env:AIW_MATLAB_ROOT,
        [string]$Branch      = $(if ($env:AIW_REPO_BRANCH) { $env:AIW_REPO_BRANCH } else { 'main' }),
        [switch]$SkipSelfTest = ($env:AIW_SKIP_TEST -eq '1')
    )

    $ErrorActionPreference = 'Stop'
    $ProgressPreference    = 'SilentlyContinue'   # Invoke-WebRequest is ~10x slower with the progress bar
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    # PowerShell 5.1 otherwise serialises some arrays as {"value":[...],"Count":n}
    Remove-TypeData System.Array -ErrorAction SilentlyContinue

    # ------------------------------------------------------------ pinned versions
    # Every student gets byte-identical tools. Bump these deliberately, never "latest".
    $Pins = @{
        Uv            = '0.12.22'                                     # github.com/astral-sh/uv
        Python        = '3.12'
        MatlabMcp     = 'v0.14.0'                                     # github.com/matlab/matlab-mcp-server
        ScholarSha    = '738d60a4d69464731e7c5b3a61767c06ff2cec0d'    # github.com/JackKuo666/Google-Scholar-MCP-Server
        ScopusSha     = '4968cc6231d129625a8448b020f5c58228d7689d'    # github.com/JOSETRA44/scopus-mcp
        MarkItDown    = '0.0.1a7'                                     # pypi markitdown-mcp (microsoft)
        Docling       = '2.133.0'                                     # pypi docling-slim (IBM): PDF -> Markdown
        OpenCv        = '5.0.0.93'                                    # pypi opencv-python-headless (Docling's table model)
        MattPocockSha = 'd81f3a183412e71a5b1e84ca21bc1a35eea03a60'    # github.com/mattpocock/skills
    }

    $RepoName    = 'AI_Grand_Prix'
    # One repo holds the whole workshop: README, AI_Tools/ (Part 1), AI_Grand_Prix/ (Part 2), instructor/ (not copied).
    $WorkshopZip = "https://github.com/Rasoolpey/AI_Grand_Prix/archive/refs/heads/$Branch.zip"
    # Run inside the extracted repo zip (lab PCs have no git)? Then install IN PLACE: that folder becomes the
    # workshop folder. "Extract All" often nests the folder, so look one level down too.
    $here = $null
    foreach ($cand in @((Get-Location).Path, (Join-Path (Get-Location).Path "$RepoName-$Branch"))) {
        if ((Test-Path (Join-Path $cand 'setup.ps1')) -and (Test-Path (Join-Path $cand 'AI_Tools')) -and
            (Test-Path (Join-Path $cand $RepoName))) { $here = (Resolve-Path $cand).Path.TrimEnd('\'); break }
    }
    if (-not $WorkshopDir) { $WorkshopDir = $(if ($here) { $here } else { Join-Path $env:USERPROFILE 'AI_Workshop' }) }
    # Everything lives under $WorkshopDir. Keep paths SHORT: Windows' 260-character limit breaks deep
    # Python packages, and the MATLAB MCP server creates a socket in the log folder (even smaller limit).
    $ToolsDir   = Join-Path $WorkshopDir '.tools'
    $McpDir     = Join-Path $ToolsDir 'mcp'
    $LogDir     = $(if ($env:AIW_LOG_DIR) { $env:AIW_LOG_DIR } else { Join-Path $ToolsDir 'log' })
    # The MATLAB MCP server puts a socket (~31-character name) in the log folder, and Windows caps socket paths at
    # ~108 characters. In a deep folder (nested zip, long user name, OneDrive Documents) use a short log folder.
    if (-not $env:AIW_LOG_DIR -and $LogDir.Length -gt 70) { $LogDir = Join-Path $env:LOCALAPPDATA 'AIW\log' }
    $RaceDir    = Join-Path $WorkshopDir $RepoName
    $ResearchDir= Join-Path $WorkshopDir 'AI_Tools'
    $KeysFile   = Join-Path $ResearchDir 'my_keys.env'   # inside the Part 1 workspace, so students see it
    $Total      = 9
    $problems   = New-Object System.Collections.Generic.List[string]

    # ================================================================ helpers
    function Step([int]$n, [string]$msg) { Write-Host "`n[$n/$Total] $msg" -ForegroundColor Cyan }
    function Ok([string]$msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
    function Info([string]$msg) { Write-Host "       $msg" -ForegroundColor Gray }
    function Warn([string]$msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow; $problems.Add($msg) }

    # Run a native exe without PowerShell 5.1 turning its stderr into terminating errors.
    function Invoke-Native([string]$Exe, [string[]]$Arguments) {
        $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        try { & $Exe @Arguments 2>&1 | ForEach-Object { Info "$_" }; return $LASTEXITCODE }
        finally { $ErrorActionPreference = $old }
    }

    function Save-Url([string]$Url, [string]$OutFile) {
        Invoke-WebRequest $Url -OutFile "$OutFile.download" -UseBasicParsing
        Move-Item "$OutFile.download" $OutFile -Force
    }

    # Download a GitHub archive (zip) and unpack its single top folder to $Dest.
    function Expand-GitHubZip([string]$Url, [string]$Dest) {
        $zip = Join-Path $env:TEMP ("aiw_" + [guid]::NewGuid().ToString('N') + '.zip')
        $tmp = "$zip.d"
        Save-Url $Url $zip
        Expand-Archive $zip -DestinationPath $tmp -Force
        $top = Get-ChildItem $tmp -Directory | Select-Object -First 1
        if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
        New-Item -ItemType Directory -Path (Split-Path $Dest -Parent) -Force | Out-Null
        Move-Item $top.FullName $Dest
        Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Copy a folder tree, but never overwrite files the student already has.
    function Copy-Missing([string]$From, [string]$To) {
        Get-ChildItem $From -Recurse -File -Force | ForEach-Object {
            $rel    = $_.FullName.Substring($From.TrimEnd('\').Length).TrimStart('\')
            $target = Join-Path $To $rel
            if (-not (Test-Path $target)) {
                New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
                Copy-Item $_.FullName $target
            }
        }
    }

    function Write-JsonFile([string]$Path, $Object) {
        New-Item -ItemType Directory -Path (Split-Path $Path -Parent) -Force | Out-Null
        # UTF-8 *without* BOM — some JSON readers reject a BOM.
        [IO.File]::WriteAllText($Path, ($Object | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding $false))
    }

    # Merge our servers into an mcp_config.json, keeping anything else the student configured.
    function Merge-McpConfig([string]$Path, [System.Collections.IDictionary]$Servers) {
        $cfg = $null
        if (Test-Path $Path) {
            Copy-Item $Path "$Path.bak" -Force
            $raw = Get-Content $Path -Raw
            if ($raw -and $raw.Trim()) {
                try { $cfg = $raw | ConvertFrom-Json } catch { Warn "Could not read $Path - saved a .bak copy and rewrote it." }
            }
        }
        if (-not $cfg) { $cfg = New-Object PSObject }
        if (-not ($cfg.PSObject.Properties.Name -contains 'mcpServers') -or -not $cfg.mcpServers) {
            $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue (New-Object PSObject) -Force
        }
        foreach ($name in $Servers.Keys) {
            $cfg.mcpServers | Add-Member -NotePropertyName $name -NotePropertyValue ([pscustomobject]$Servers[$name]) -Force
        }
        Write-JsonFile $Path $cfg
    }

    function Get-MatlabRelease([string]$root) {
        $vi = Join-Path $root 'VersionInfo.xml'
        if (Test-Path $vi) {
            try { $r = ([xml](Get-Content $vi -Raw)).MathWorks_version_info.release; if ($r) { return $r.Trim() } } catch { }
        }
        $leaf = Split-Path $root -Leaf
        if ($leaf -match '^R\d{4}[ab]$') { return $leaf }
        return 'unknown'
    }

    function Find-MatlabRoots {
        $roots = New-Object System.Collections.Generic.List[string]
        foreach ($hive in 'HKLM:\SOFTWARE\MathWorks\MATLAB', 'HKCU:\SOFTWARE\MathWorks\MATLAB') {
            if (Test-Path $hive) {
                Get-ChildItem $hive -ErrorAction SilentlyContinue | ForEach-Object {
                    $r = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).MATLABROOT
                    if ($r) { $roots.Add($r) }
                }
            }
        }
        foreach ($base in @("$env:ProgramFiles\MATLAB", "${env:ProgramFiles(x86)}\MATLAB")) {
            if ($base -and (Test-Path $base)) { Get-ChildItem $base -Directory -Filter 'R20*' | ForEach-Object { $roots.Add($_.FullName) } }
        }
        $cmd = Get-Command matlab -ErrorAction SilentlyContinue
        if ($cmd) { $roots.Add((Split-Path (Split-Path $cmd.Source -Parent) -Parent)) }
        $roots | Where-Object { $_ -and (Test-Path (Join-Path $_ 'bin\matlab.exe')) } |
            ForEach-Object { (Resolve-Path $_).Path.TrimEnd('\') } | Select-Object -Unique
    }

    # Hidden input for keys.
    function Read-Secret([string]$Prompt) {
        $sec = Read-Host -Prompt "       $Prompt" -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { return ("" + [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)).Trim() }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }

    # my_keys.env: plain NAME=value lines, '#' comments.
    function Read-KeysFile([string]$Path) {
        $kv = @{}
        if (Test-Path $Path) {
            foreach ($line in Get-Content $Path) {
                if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') { $kv[$Matches[1]] = $Matches[2].Trim('"', "'") }
            }
        }
        return $kv
    }

    # Rewrites the whole file from $K (a hashtable of NAME -> value), so pass every key you want to keep.
    function Write-KeysFile([string]$Path, [hashtable]$K) {
        function V([string]$n) { if ($K.ContainsKey($n) -and $K[$n]) { return $K[$n] } else { return '' } }
        $text = @"
# KEYS: paste each key after its = sign, then save (Ctrl+S) and reload VS Code (Ctrl+Shift+P > Reload Window).
# This file stays on your computer. Never share it.

# Scopus (literature search): https://dev.elsevier.com  ->  "I want an API key"  (register with your university e-mail)
SCOPUS_API_KEY=$(V 'SCOPUS_API_KEY')
# Optional: only needed OFF campus without the VPN (ask the library for an institution token).
SCOPUS_INST_TOKEN=$(V 'SCOPUS_INST_TOKEN')

"@
        [IO.File]::WriteAllText($Path, $text, (New-Object Text.UTF8Encoding $false))
    }

    # ---------------------------------------------------------------- MCP self-test client
    # Speaks the MCP stdio protocol (newline-delimited JSON-RPC) to a server, exactly like Antigravity does.
    function Format-Arg([string]$a) {
        if ($a -notmatch '[\s"]') { return $a }
        return '"' + (($a -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
    }

    function Start-McpSession($Server) {
        $psi = New-Object Diagnostics.ProcessStartInfo
        $psi.FileName  = $Server.command
        $psi.Arguments = (@($Server.args) | Where-Object { $_ } | ForEach-Object { Format-Arg $_ }) -join ' '
        $psi.UseShellExecute        = $false
        $psi.CreateNoWindow         = $true
        $psi.RedirectStandardInput  = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
        if ($Server.cwd) { $psi.WorkingDirectory = $Server.cwd }
        if ($Server.env) { foreach ($k in $Server.env.Keys) { $psi.EnvironmentVariables[$k] = [string]$Server.env[$k] } }
        # .NET Framework encodes the child's stdin with [Console]::InputEncoding and, if that is UTF-8 with a BOM,
        # writes the BOM at start-up, which breaks the server's first JSON message. Use BOM-less UTF-8 while starting.
        $prevEnc = $null
        try { $prevEnc = [Console]::InputEncoding; [Console]::InputEncoding = New-Object Text.UTF8Encoding $false } catch { }
        try { $p = [Diagnostics.Process]::Start($psi) }
        finally { if ($prevEnc) { try { [Console]::InputEncoding = $prevEnc } catch { } } }
        $null = $p.StandardError.ReadToEndAsync()     # keep draining stderr so the server never blocks on it
        $w = New-Object IO.StreamWriter($p.StandardInput.BaseStream, (New-Object Text.UTF8Encoding $false))
        $w.NewLine = "`n"; $w.AutoFlush = $true
        return @{ Proc = $p; Writer = $w; NextId = 1; Pending = $null }
    }

    function Send-McpRequest($S, [string]$Method, $Params, [int]$TimeoutSec = 60) {
        $id  = $S.NextId; $S.NextId++
        $msg = @{ jsonrpc = '2.0'; id = $id; method = $Method }
        if ($null -ne $Params) { $msg.params = $Params }
        $S.Writer.WriteLine(($msg | ConvertTo-Json -Depth 20 -Compress))
        $deadline = (Get-Date).AddSeconds($TimeoutSec)
        while ($true) {
            if (-not $S.Pending) { $S.Pending = $S.Proc.StandardOutput.ReadLineAsync() }
            $left = [int](($deadline - (Get-Date)).TotalMilliseconds)
            if ($left -le 0) { throw "no answer to '$Method' within $TimeoutSec s" }
            if (-not $S.Pending.Wait([Math]::Min($left, 1000))) {
                if ($S.Proc.HasExited) { throw "server exited early (exit code $($S.Proc.ExitCode))" }
                continue
            }
            $line = $S.Pending.Result; $S.Pending = $null
            if ($null -eq $line) { throw 'server closed its output' }
            if (-not $line.TrimStart().StartsWith('{')) { continue }          # ignore stray non-JSON output
            try { $resp = $line | ConvertFrom-Json } catch { continue }
            if (($resp.PSObject.Properties.Name -contains 'id') -and $resp.id -eq $id) {
                if ($resp.error) { throw "server error: $($resp.error.message)" }
                return $resp.result
            }
        }
    }

    function Send-McpNotification($S, [string]$Method) {
        $S.Writer.WriteLine((@{ jsonrpc = '2.0'; method = $Method } | ConvertTo-Json -Compress))
    }

    function Stop-McpSession($S) {
        try { $S.Writer.Close() } catch { }
        if (-not $S.Proc.WaitForExit(15000)) { try { $S.Proc.Kill() } catch { } }
    }

    function Initialize-Mcp($S, [int]$TimeoutSec) {
        $null = Send-McpRequest $S 'initialize' @{
            protocolVersion = '2025-06-18'
            capabilities    = @{}
            clientInfo      = @{ name = 'ai-workshop-setup'; version = '1.0' }
        } $TimeoutSec
        Send-McpNotification $S 'notifications/initialized'
        return @((Send-McpRequest $S 'tools/list' @{} $TimeoutSec).tools)
    }

    function Get-ToolText($Result) {
        (@($Result.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n"
    }

    # =====================================================================================
    Write-Host ''
    Write-Host '  ==============================================' -ForegroundColor Magenta
    Write-Host '        AI WORKSHOP  -  one-command setup        ' -ForegroundColor Magenta
    Write-Host '  ==============================================' -ForegroundColor Magenta

    # ================================================================ 1. MATLAB
    Step 1 'Looking for MATLAB'
    if ($MatlabRoot) {
        if (-not (Test-Path (Join-Path $MatlabRoot 'bin\matlab.exe'))) { throw "AIW_MATLAB_ROOT='$MatlabRoot' does not contain bin\matlab.exe" }
        $MatlabRoot = (Resolve-Path $MatlabRoot).Path.TrimEnd('\')
    } else {
        $found = @(Find-MatlabRoots)
        if ($found.Count -eq 0) {
            throw "MATLAB was not found. Set `$env:AIW_MATLAB_ROOT = 'C:\Program Files\MATLAB\R2024b' and run again."
        }
        $MatlabRoot = $found | Sort-Object { Get-MatlabRelease $_ } -Descending | Select-Object -First 1
        if ($found.Count -gt 1) { Info "Found $($found.Count) MATLAB installs; using the newest." }
    }
    $release = Get-MatlabRelease $MatlabRoot
    Ok "MATLAB $release  at  $MatlabRoot"
    if ($release -match '^R\d{4}[ab]$' -and $release -lt 'R2024a') { Warn "MATLAB $release is older than R2024a (recommended)." }

    # ================================================================ 2. Workshop files
    Step 2 "Workshop files in $WorkshopDir"
    New-Item -ItemType Directory -Path $WorkshopDir, $McpDir, $LogDir -Force | Out-Null
    (Get-Item $ToolsDir -Force).Attributes = 'Hidden, Directory'   # keep the student's folder tidy
    # Workshop package: one download for both parts. Files a student already has are never overwritten.
    # Inside the extracted zip, those files are used (no second download); in place, nothing is copied.
    $pkgIsLocal = $false
    if ($env:AIW_LOCAL_WORKSHOP) {
        $pkg = $env:AIW_LOCAL_WORKSHOP; $pkgIsLocal = $true
    } elseif ($here) {
        $pkg = $here; $pkgIsLocal = $true
        if ($here -eq $WorkshopDir) { Info "Installing in this folder: $here" }
        else { Info "Using the workshop files in $here (no second download)" }
    } else {
        $pkg = Join-Path $env:TEMP ("aiw_pkg_" + [guid]::NewGuid().ToString('N'))
        Expand-GitHubZip $WorkshopZip $pkg
    }
    $inPlace = (Resolve-Path $pkg).Path.TrimEnd('\') -eq (Resolve-Path $WorkshopDir).Path.TrimEnd('\')
    if (-not (Test-Path (Join-Path $pkg 'AI_Tools'))) { throw "Workshop package has no AI_Tools folder ($pkg)." }
    if (-not $inPlace) {
        Copy-Missing (Join-Path $pkg 'AI_Tools') $ResearchDir
        foreach ($f in 'README.md', 'remove-keys.ps1') {      # student guide + key removal: always refresh
            if (Test-Path (Join-Path $pkg $f)) { Copy-Item (Join-Path $pkg $f) (Join-Path $WorkshopDir $f) -Force }
        }
    }
    Ok "Part 1 (AI tools) ready at $ResearchDir"

    # Part 2: the race.
    if (-not (Test-Path (Join-Path $pkg $RepoName))) { throw "Workshop package has no $RepoName folder ($pkg)." }
    if (-not $inPlace) { Copy-Missing (Join-Path $pkg $RepoName) $RaceDir }
    Ok "Part 2 (Grand Prix) ready at $RaceDir"
    if (-not $pkgIsLocal) { Remove-Item $pkg -Recurse -Force -ErrorAction SilentlyContinue }   # never delete a local copy

    # ================================================================ 3. uv + Python
    Step 3 'Installing uv + a private Python (inside the workshop folder)'
    # Point uv at the workshop folder for everything (binary, Python, cache) and never touch PATH.
    # These variables only live in this PowerShell window and are restored at the end.
    $uvEnv = [ordered]@{
        UV_INSTALL_DIR        = Join-Path $ToolsDir 'uv'
        UV_NO_MODIFY_PATH     = '1'
        UV_PYTHON_INSTALL_DIR = Join-Path $ToolsDir 'python'
        UV_PYTHON_BIN_DIR     = Join-Path $ToolsDir 'python\bin'
        UV_CACHE_DIR          = Join-Path $ToolsDir 'cache'
    }
    $savedEnv = @{}
    foreach ($k in $uvEnv.Keys) { $savedEnv[$k] = [Environment]::GetEnvironmentVariable($k, 'Process'); Set-Item "Env:$k" $uvEnv[$k] }
    $uv = Join-Path $uvEnv.UV_INSTALL_DIR 'uv.exe'
    if (-not (Test-Path $uv)) {
        # Plain release zip (no installer, so no PATH change and no receipt outside the workshop folder).
        $uvZip = Join-Path $env:TEMP ("aiw_uv_" + [guid]::NewGuid().ToString('N') + '.zip')
        Save-Url "https://github.com/astral-sh/uv/releases/download/$($Pins.Uv)/uv-x86_64-pc-windows-msvc.zip" $uvZip
        Expand-Archive $uvZip -DestinationPath $uvEnv.UV_INSTALL_DIR -Force
        Remove-Item $uvZip -Force -ErrorAction SilentlyContinue
    }
    if (-not (Test-Path $uv)) { throw "uv did not install. Check internet access to astral.sh and github.com." }
    Ok "uv ready ($uv)"
    if ((Invoke-Native $uv @('python', 'install', $Pins.Python)) -ne 0) { throw "uv could not install Python $($Pins.Python)." }
    Ok "Python $($Pins.Python) ready (private copy, does not touch any system Python)"

    function Install-PyServer([string]$Name, [string[]]$Packages) {
        $dir   = Join-Path $McpDir $Name
        $venv  = Join-Path $dir '.venv'
        $stamp = Join-Path $dir 'INSTALLED'
        $want  = ($Packages -join ' ')
        if ((Test-Path $stamp) -and (Get-Content $stamp -Raw).Trim() -eq $want -and (Test-Path "$venv\Scripts\python.exe")) {
            Ok "$Name already installed"; return $venv
        }
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Info "Installing $Name (downloads Python packages; can take a few minutes)..."
        if ((Invoke-Native $uv @('venv', $venv, '--python', $Pins.Python, '--allow-existing', '--quiet')) -ne 0) { throw "Could not create the $Name environment." }
        # Not --quiet: uv's progress lines (Resolved / Prepared / Installed) show the step is moving.
        if ((Invoke-Native $uv (@('pip', 'install', '--python', "$venv\Scripts\python.exe") + $Packages)) -ne 0) { throw "Could not install $Name." }
        Set-Content -Path $stamp -Value $want -Encoding ASCII
        Ok "$Name installed"
        return $venv
    }

    # ================================================================ 4. MATLAB MCP server
    Step 4 "MATLAB MCP Server ($($Pins.MatlabMcp))"
    $matlabMcpExe = Join-Path $McpDir 'matlab\matlab-mcp-server.exe'
    $marker       = Join-Path $McpDir 'matlab\VERSION'
    if ((Test-Path $matlabMcpExe) -and (Test-Path $marker) -and (Get-Content $marker -Raw).Trim() -eq $Pins.MatlabMcp) {
        Ok 'Already installed'
    } else {
        New-Item -ItemType Directory -Path (Split-Path $matlabMcpExe -Parent) -Force | Out-Null
        Save-Url "https://github.com/matlab/matlab-mcp-server/releases/download/$($Pins.MatlabMcp)/matlab-mcp-server-windows-x64.exe" $matlabMcpExe
        Unblock-File $matlabMcpExe
        Set-Content -Path $marker -Value $Pins.MatlabMcp -Encoding ASCII
        Ok 'Downloaded'
    }

    # ================================================================ 5. Research MCP servers
    Step 5 'Research tools (Google Scholar, Scopus, MarkItDown servers + Docling)'

    # Google Scholar — not on PyPI, so fetch the pinned source and run it through a small wrapper.
    $scholarDir = Join-Path $McpDir 'google-scholar'
    $scholarSrc = Join-Path $scholarDir 'src'
    $scholarPin = Join-Path $scholarDir 'SOURCE'
    if (-not ((Test-Path $scholarPin) -and (Get-Content $scholarPin -Raw).Trim() -eq $Pins.ScholarSha)) {
        Info 'Downloading the Google Scholar server source from GitHub...'
        Expand-GitHubZip "https://github.com/JackKuo666/Google-Scholar-MCP-Server/archive/$($Pins.ScholarSha).zip" $scholarSrc
        Set-Content -Path $scholarPin -Value $Pins.ScholarSha -Encoding ASCII
    }
    $scholarVenv = Install-PyServer 'google-scholar' @('mcp[cli]>=1.4.1,<2', 'scholarly>=1.7.0', 'bibtexparser<2', 'requests', 'beautifulsoup4')
    # The upstream server print()s errors to stdout, which corrupts the MCP stream. Redirect print() to stderr.
    $scholarRun = Join-Path $scholarDir 'run_server.py'
    @"
import builtins, runpy, sys
_print = builtins.print
def _stderr_print(*args, **kwargs):
    kwargs.setdefault('file', sys.stderr)
    _print(*args, **kwargs)
builtins.print = _stderr_print
src = r'$scholarSrc'
sys.path.insert(0, src)
runpy.run_path(src + r'\google_scholar_server.py', run_name='__main__')
"@ | Set-Content -Path $scholarRun -Encoding ASCII

    # Starts an MCP server after loading AI_Tools\my_keys.env into its environment, so students
    # keep keys in one plain file instead of inside hidden config.
    $keyLoader = Join-Path $McpDir 'run_with_keys.py'
    @"
import importlib, os, sys
keys_file, target = sys.argv[1], sys.argv[2]          # target = "package.module:function"
if os.path.exists(keys_file):
    for line in open(keys_file, encoding='utf-8'):
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            v = v.strip().strip('"').strip("'")
            if v:
                os.environ[k.strip()] = v
mod, func = target.split(':')
sys.argv = [mod] + sys.argv[3:]
getattr(importlib.import_module(mod), func)()
"@ | Set-Content -Path $keyLoader -Encoding ASCII

    # Scholar and Scopus use FastMCP, which mcp 2.x removed -> pin them to mcp 1.x. (MarkItDown needs mcp 2.x.)
    $scopusVenv = Install-PyServer 'scopus' @("https://github.com/JOSETRA44/scopus-mcp/archive/$($Pins.ScopusSha).zip", 'mcp<2')
    $mdVenv     = Install-PyServer 'markitdown' @("markitdown-mcp==$($Pins.MarkItDown)")

    # The skills' scripts (Scopus Q1 search, PDF -> text, IEEE report) run with this Python: from AI_Tools it is
    # ..\.tools\py\Scripts\python.exe. It holds Docling (IBM), which turns the PDFs into much cleaner Markdown than
    # MarkItDown (headings, tables, no run-together words). Slim install: PDF only, no OCR (journal PDFs have text).
    # About 1 GB installed + 0.7 GB models. If it fails the review falls back to MarkItDown, so only warn.
    $PyDir   = Join-Path $ToolsDir 'py'
    $PyExe   = Join-Path $PyDir 'Scripts\python.exe'
    $Models  = Join-Path $ToolsDir 'docling-models'
    $pyStamp = Join-Path $PyDir 'INSTALLED'
    $pyWant  = @("docling-slim[cli,convert-core,format-pdf,models-local]==$($Pins.Docling)", "opencv-python-headless==$($Pins.OpenCv)")
    if ((Invoke-Native $uv @('venv', $PyDir, '--python', $Pins.Python, '--allow-existing', '--quiet')) -ne 0) {
        Warn 'Could not create the Python for the research scripts (.tools\py). Run setup again.'
    } elseif ($env:AIW_NO_DOCLING -eq '1') {
        Info 'Docling skipped (AIW_NO_DOCLING=1): the literature review uses MarkItDown.'
    } elseif ((Test-Path $pyStamp) -and (Get-Content $pyStamp -Raw).Trim() -eq ($pyWant -join ' ') -and
              (Test-Path (Join-Path $Models 'docling-project--docling-models'))) {
        Ok 'Docling already installed'
    } else {
        Info 'Installing Docling (PDF -> text for the literature review; about 1 GB, a few minutes)...'
        if ((Invoke-Native $uv (@('pip', 'install', '--python', $PyExe) + $pyWant)) -ne 0) {
            Warn 'Docling did not install: the literature review will use MarkItDown instead (lower quality). Run setup again to retry.'
        } else {
            Info 'Downloading the Docling models (page layout + tables, about 0.7 GB)...'
            $dlTools = Join-Path $PyDir 'Scripts\docling-tools.exe'
            if ((Invoke-Native $dlTools @('models', 'download', 'layout', 'tableformer', '-o', $Models, '--quiet')) -eq 0) {
                Set-Content -Path $pyStamp -Value ($pyWant -join ' ') -Encoding ASCII
                Ok 'Docling installed (PDF -> text)'
            } else {
                Warn 'The Docling models did not download. Run setup again (otherwise Docling downloads them on first use).'
            }
        }
    }

    # The download cache (~400 MB) is not needed once the servers are installed.
    $null = Invoke-Native $uv @('cache', 'clean', '--quiet')

    # ================================================================ 6. Keys
    Step 6 "Your keys -> $KeysFile"
    # Antigravity loads MCP servers ONLY from the global mcp_config.json (or plugins), not from a workspace
    # .agents\mcp_config.json. Older versions of this script wrote those workspace files; step 7 removes them.
    $globalCfg   = $(if ($env:AIW_MCP_CONFIG) { $env:AIW_MCP_CONFIG } else { Join-Path $env:USERPROFILE '.gemini\config\mcp_config.json' })
    $researchCfg = Join-Path $ResearchDir '.agents\mcp_config.json'   # legacy, removed in step 7
    $raceCfg     = Join-Path $RaceDir '.agents\mcp_config.json'       # legacy, removed in step 7
    $saved     = Read-KeysFile $KeysFile
    # Workshop key: the instructor can share ONE file, workshop_keys.env (same NAME=value lines as my_keys.env).
    # Saved next to the extracted zip, in Downloads, Documents or on the Desktop, it fills the Scopus key: no questions.
    # Browsers may rename it (workshop_keys (1).env), so match the start of the name and take the newest.
    $wkFile = $null
    if ($env:AIW_KEYS_FILE -and (Test-Path $env:AIW_KEYS_FILE)) { $wkFile = $env:AIW_KEYS_FILE }
    else {
        $wkDirs = @((Get-Location).Path, (Split-Path (Get-Location).Path -Parent), $(if ($pkgIsLocal) { $pkg }),
                    (Join-Path $env:USERPROFILE 'Downloads'), [Environment]::GetFolderPath('MyDocuments'),
                    [Environment]::GetFolderPath('Desktop'))
        foreach ($d in ($wkDirs | Where-Object { $_ -and (Test-Path $_) })) {
            $hit = Get-ChildItem $d -File -Filter 'workshop_keys*' -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($hit) { $wkFile = $hit.FullName; break }
        }
    }
    $workshop = @{}
    if ($wkFile) { $workshop = Read-KeysFile $wkFile; Ok "Workshop keys found: $wkFile" }
    # Each key: environment variable, else the workshop file, else what my_keys.env already has.
    function Get-Key([string]$n) {
        foreach ($v in @([Environment]::GetEnvironmentVariable($n), $workshop[$n], $saved[$n])) { if ($v) { return $v } }
        return ''
    }
    $scopusKey = Get-Key 'SCOPUS_API_KEY'
    $instToken = Get-Key 'SCOPUS_INST_TOKEN'
    if ($scopusKey) { Ok 'Scopus key found' }
    if (-not $scopusKey) {
        Info 'Get a key at https://dev.elsevier.com (press Enter to skip; you can paste it into AI_Tools\my_keys.env later)'
        $scopusKey = Read-Secret 'Scopus API key'
        if ($scopusKey) { $instToken = Read-Secret 'Scopus institution token (optional - Enter to skip)' }
    }
    if ($scopusKey) {
        try {
            $h = @{ 'X-ELS-APIKey' = $scopusKey; 'Accept' = 'application/json' }
            if ($instToken) { $h['X-ELS-Insttoken'] = $instToken }
            $r = Invoke-RestMethod 'https://api.elsevier.com/content/search/scopus?query=TITLE(simulation)&count=1' -Headers $h -UseBasicParsing
            Ok "Scopus key works ($($r.'search-results'.'opensearch:totalResults') results for a test query)"
        } catch {
            $code = $_.Exception.Response.StatusCode.value__
            if ($code -eq 401 -or $code -eq 403) {
                Warn "Scopus rejected the key (HTTP $code). Check it in AI_Tools\my_keys.env; off campus you may need the institution token or the VPN."
            } else {
                Warn "Could not reach Scopus to check the key ($($_.Exception.Message)). Saved it anyway."
            }
        }
    } else {
        Warn "No Scopus key yet - put it in $KeysFile (Scopus tools won't work until then)."
    }
    $allKeys = @{ SCOPUS_API_KEY = $scopusKey; SCOPUS_INST_TOKEN = $instToken }
    Write-KeysFile $KeysFile $allKeys
    Ok "Saved: $KeysFile  (open it in any editor to change a key)"

    # ================================================================ 7. Antigravity config
    Step 7 'Antigravity config: MCP servers (global) + skills (per workspace)'
    function New-MatlabServer([string]$Folder) {
        [ordered]@{
            command = $matlabMcpExe
            args    = @("--matlab-root=$MatlabRoot", "--initial-working-folder=$Folder",
                        '--matlab-display-mode=desktop', "--log-folder=$LogDir")
        }
    }
    $servers = [ordered]@{
        # ONE matlab entry for both parts. It starts in the race folder so practiceRace/garage are on the path
        # (the race skills do cd(fileparts(which('practiceRace')))). Research work can cd() anywhere.
        'matlab' = New-MatlabServer $RaceDir
        'google-scholar' = [ordered]@{
            command = "$scholarVenv\Scripts\python.exe"
            args    = @($scholarRun)
            cwd     = $scholarSrc
        }
        'scopus' = [ordered]@{
            command = "$scopusVenv\Scripts\python.exe"
            args    = @($keyLoader, $KeysFile, 'scopus_mcp.server:main')
        }
        'markitdown' = [ordered]@{
            command = "$mdVenv\Scripts\markitdown-mcp.exe"
            args    = @()
        }
    }

    Merge-McpConfig $globalCfg $servers
    Ok "$globalCfg : matlab, google-scholar, scopus, markitdown (your other servers kept, backup: .bak)"
    # Remove the per-workspace files written by older versions: Antigravity ignores them, and if a future
    # version did read them each server would start twice.
    foreach ($old in $researchCfg, $raceCfg) {
        foreach ($f in $old, "$old.bak") { if (Test-Path $f) { Remove-Item $f -Force } }
    }

    # Matt Pocock's "grilling" (+ its "grill-me" entry point), pinned, into the Part 1 workspace.
    $skillsDir = Join-Path $ResearchDir '.agents\skills'
    $mpStamp   = Join-Path $skillsDir '.mattpocock-version'
    if (-not ((Test-Path $mpStamp) -and (Get-Content $mpStamp -Raw).Trim() -eq $Pins.MattPocockSha)) {
        $mpTmp = Join-Path $env:TEMP 'aiw_mattpocock'
        Expand-GitHubZip "https://github.com/mattpocock/skills/archive/$($Pins.MattPocockSha).zip" $mpTmp
        foreach ($s in 'grilling', 'grill-me') {
            $dst = Join-Path $skillsDir $s
            if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
            New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
            Copy-Item (Join-Path $mpTmp "skills\productivity\$s") $dst -Recurse
        }
        Copy-Item (Join-Path $mpTmp 'LICENSE') (Join-Path $skillsDir 'MATTPOCOCK-LICENSE.txt') -Force -ErrorAction SilentlyContinue
        Remove-Item $mpTmp -Recurse -Force -ErrorAction SilentlyContinue
        Set-Content -Path $mpStamp -Value $Pins.MattPocockSha -Encoding ASCII
    }
    # Workshop limit: the upstream skill grills "until the frontier is empty"; cap it at 10 questions.
    $grillSkill = Join-Path $skillsDir 'grilling\SKILL.md'
    if ((Test-Path $grillSkill) -and -not (Select-String -Path $grillSkill -Pattern 'Workshop limit' -SimpleMatch -Quiet)) {
        Add-Content -Path $grillSkill -Encoding ASCII -Value @'

## Workshop limit (overrides the rule above)

Ask **at most 10 questions in total**, counting every numbered question in every round; ask the most important ones first.
After the 10th answer, stop: summarise what is settled, list anything still open as an explicit assumption, and continue.
'@
    }
    Ok 'Skills: AI_Tools -> research-question (+ grill-me, grilling), literature-search, literature-review, research-figure, research-report | AI_Grand_Prix -> race-debrief, car-design-review'
    Info 'Skill scripts run with .tools\py: Scopus Q1 search, Docling PDF -> text, IEEE report for Overleaf'

    # ================================================================ 8. Self-test
    Step 8 'Self-test: talking to every MCP server like Antigravity will'
    if ($SkipSelfTest) {
        Info 'Skipped (AIW_SKIP_TEST=1).'
    } else {
        foreach ($name in 'google-scholar', 'scopus', 'markitdown') {
            $s = $null
            try {
                $s = Start-McpSession $servers[$name]
                $tools = @(Initialize-Mcp $s 90)
                Ok "$name answers ($($tools.Count) tools)"
            } catch {
                Warn "$name did not start: $($_.Exception.Message)"
            } finally { if ($s) { Stop-McpSession $s } }
        }

        # The skills' scripts: the Scopus Q1 search (key, search, journal metrics) and Docling.
        $q1 = Join-Path $ResearchDir '.agents\skills\literature-search\scripts\scopus_q1.py'
        if (-not (Test-Path $PyExe)) {
            Warn 'The Python for the research scripts (.tools\py) is missing. Run setup again.'
        } else {
            if ($scopusKey -and (Test-Path $q1)) {
                $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
                try { $out = (& $PyExe $q1 selftest 2>&1 | Out-String).Trim() } finally { $ErrorActionPreference = $old }
                if ($LASTEXITCODE -eq 0) { Ok "Scopus Q1 search: $out" } else { Warn "Scopus Q1 search: $out" }
            }
            if ($env:AIW_NO_DOCLING -ne '1') {
                if ((Invoke-Native $PyExe @('-c', 'import docling.document_converter')) -eq 0) { Ok 'Docling ready (PDF -> text)' }
                else { Warn 'Docling does not start: the literature review will use MarkItDown. Run setup again to retry.' }
            }
        }

        Info 'MATLAB: starting MATLAB through MCP and running a baseline race (1-3 min)...'
        $test = [ordered]@{ command = $matlabMcpExe
                            args    = @("--matlab-root=$MatlabRoot", "--initial-working-folder=$RaceDir",
                                        '--matlab-display-mode=nodesktop', "--log-folder=$LogDir") }
        $s = $null
        try {
            $s     = Start-McpSession $test
            $tools = @(Initialize-Mcp $s 60)
            $eval  = $tools | Where-Object { $_.name -eq 'evaluate_matlab_code' } | Select-Object -First 1
            if (-not $eval) { throw 'evaluate_matlab_code tool not offered' }
            $code = "cd('$($RaceDir -replace "'", "''")'); r = practiceRace('Headless', true); " +
                    "fprintf('AIW_RESULT finished=%d time=%.2f score=%.2f\n', r.finished, r.totalTime, r.score);"
            # Fill the tool's required inputs: the code, plus any folder/path argument.
            $toolArgs = @{}
            foreach ($req in @($eval.inputSchema.required)) {
                if ($req -match 'code')               { $toolArgs[$req] = $code }
                elseif ($req -match 'path|folder|dir') { $toolArgs[$req] = $RaceDir }
            }
            if ($toolArgs.Count -eq 0) { $toolArgs['code'] = $code }
            $res  = Send-McpRequest $s 'tools/call' @{ name = 'evaluate_matlab_code'; arguments = $toolArgs } 420
            $text = Get-ToolText $res
            if ($text -match 'AIW_RESULT finished=1 time=([\d.]+) score=([\d.]+)') {
                Ok "MATLAB via MCP works - baseline race $($Matches[1]) s, score $($Matches[2])"
            } elseif ($text -match '(?i)licen[cs]') {
                Warn "MATLAB has no licence on this account. Open MATLAB once, sign in, then re-run setup. Log: $LogDir"
            } elseif ($text -match 'AIW_RESULT') {
                Warn "MATLAB via MCP works, but the baseline car did not finish a lap: $(($text -split "`n" | Select-String 'AIW_RESULT').Line)"
            } else {
                Warn "MATLAB answered but the race did not run. First lines: $(($text -split "`n" | Select-Object -First 3) -join ' | ')"
            }
        } catch {
            Warn "MATLAB MCP test failed: $($_.Exception.Message). Logs: $LogDir"
        } finally { if ($s) { Stop-McpSession $s } }
    }

    # ================================================================ 9. VS Code extension + shortcuts
    Step 9 'VS Code: Antigravity extension + desktop shortcuts'
    # Students can't install apps on lab PCs, but VS Code is there and extensions install per user
    # (no admin). The Google Antigravity extension reads skills from .agents\ and MCP servers from
    # %USERPROFILE%\.gemini\config\mcp_config.json, the same as the app.
    $codeExe = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe'),
        $(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\Code.exe' })
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    # Fallback: the standalone Antigravity app, if a machine has it.
    $agExe = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Antigravity IDE\Antigravity IDE.exe'),
        (Join-Path $env:ProgramFiles 'Antigravity IDE\Antigravity IDE.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Antigravity\Antigravity.exe'),
        (Join-Path $env:ProgramFiles 'Antigravity\Antigravity.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    $AgExtension = 'google.google-antigravity'
    $editorExe = $(if ($codeExe) { $codeExe } else { $agExe })

    if ($codeExe) {
        Ok "VS Code: $codeExe"
        $codeCli = Join-Path (Split-Path $codeExe -Parent) 'bin\code.cmd'
        if ($env:AIW_NO_EXTENSION -eq '1') {
            Info 'Extension install skipped (AIW_NO_EXTENSION=1).'
        } elseif (Test-Path $codeCli) {
            $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
            try {
                $have = @(& $codeCli --list-extensions 2>$null) -contains $AgExtension
                if ($have) {
                    Ok 'Google Antigravity extension already installed'
                } else {
                    Info 'Installing the Google Antigravity extension (per user, no admin)...'
                    & $codeCli --install-extension $AgExtension 2>&1 | ForEach-Object { Info "$_" }
                    if (@(& $codeCli --list-extensions 2>$null) -contains $AgExtension) {
                        Ok 'Google Antigravity extension installed'
                    } else {
                        Warn "Could not install the extension automatically. In VS Code: Extensions (Ctrl+Shift+X) -> search 'Google Antigravity' (publisher Google) -> Install."
                    }
                }
            } finally { $ErrorActionPreference = $old }
        } else {
            Warn "Install the extension by hand. In VS Code: Extensions (Ctrl+Shift+X) -> search 'Google Antigravity' (publisher Google) -> Install."
        }
    } elseif ($agExe) {
        Ok "Antigravity app: $agExe"
    } else {
        Warn "VS Code was not found. Open VS Code, install the 'Google Antigravity' extension (publisher Google), then open the folders below."
    }

    if ($env:AIW_NO_SHORTCUTS -eq '1') {
        Info 'Shortcuts skipped (AIW_NO_SHORTCUTS=1).'
    } elseif ($editorExe) {
        try {
            $ws = New-Object -ComObject WScript.Shell
            foreach ($pair in @(@('AI Workshop - Part 1 AI Tools', $ResearchDir), @('AI Workshop - Part 2 Grand Prix', $RaceDir))) {
                $sc = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) "$($pair[0]).lnk"))
                $sc.TargetPath       = $editorExe
                $sc.Arguments        = '"' + $pair[1] + '"'
                $sc.WorkingDirectory = $pair[1]
                $sc.Save()
            }
            Ok 'Two shortcuts created on your desktop (each opens one part folder)'
        } catch { Info "Could not create shortcuts ($($_.Exception.Message)) - open the folders from VS Code instead (File > Open Folder)." }
    }

    foreach ($k in $savedEnv.Keys) {
        if ($null -eq $savedEnv[$k]) { Remove-Item "Env:$k" -ErrorAction SilentlyContinue } else { Set-Item "Env:$k" $savedEnv[$k] }
    }

    Write-Host ''
    if ($problems.Count -eq 0) {
        Write-Host '  ==============================================' -ForegroundColor Green
        Write-Host '    ALL SET!' -ForegroundColor Green
        Write-Host '  ==============================================' -ForegroundColor Green
    } else {
        Write-Host '  ==============================================' -ForegroundColor Yellow
        Write-Host "    Finished with $($problems.Count) warning(s):" -ForegroundColor Yellow
        $problems | ForEach-Object { Write-Host "     - $_" -ForegroundColor Yellow }
        Write-Host '  ==============================================' -ForegroundColor Yellow
    }
    Write-Host @"

  NEXT STEPS
  ----------
  1. If VS Code / Antigravity was already open, reload it (Ctrl+Shift+P -> "Reload Window") so it
     picks up the MCP servers: matlab, google-scholar, scopus, markitdown (registered in
     $globalCfg, available in every folder).
  2. Open the folder for each part (File > Open Folder, or use the desktop shortcuts) to get its skills:
       Part 1:  $ResearchDir        (research skills)
       Part 2:  $RaceDir   (race-debrief, car-design-review)
  3. Open the Antigravity panel, sign in with your Google account, and check
     ... (Additional Options) > MCP Servers to see the tools.

  Your keys:     $KeysFile
  Student guide: $WorkshopDir\README.md
  Shared PC?  At the end run  $WorkshopDir\remove-keys.ps1
              (or delete $WorkshopDir and the two desktop shortcuts)

"@
}

Install-AIWorkshop
