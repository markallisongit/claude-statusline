# Installs the statusline for the current user. Needs Git for Windows (Claude Code runs its shell through Git Bash too).
# Usage: irm https://raw.githubusercontent.com/markallisongit/claude-statusline/main/install.ps1 | iex

# Script block keeps $ErrorActionPreference and variables out of the caller's session under iex
& {
    $ErrorActionPreference = 'Stop'

    # PS 5.1 may default to TLS 1.0, which GitHub rejects
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $bash = $null
    if ($env:CLAUDE_CODE_GIT_BASH_PATH -and (Test-Path -LiteralPath $env:CLAUDE_CODE_GIT_BASH_PATH -PathType Leaf)) {
        $bash = $env:CLAUDE_CODE_GIT_BASH_PATH
    }

    # Git's exec path sits inside its install (mingw64\libexec\git-core), so walking up finds bin\bash.exe for winget, scoop and custom installs alike
    $git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bash -and $git) {
        $dir = & $git.Source --exec-path 2>$null
        while ($dir -and -not $bash) {
            $candidate = Join-Path $dir 'bin\bash.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { $bash = $candidate }
            $dir = [IO.Path]::GetDirectoryName($dir)
        }
    }
    if (-not $bash) {
        throw 'Git for Windows is required: winget install Git.Git'
    }

    # Pin Git's bash.exe so the command never resolves to WSL's bash
    $cmd = '"' + ($bash -replace '\\', '/') + '" ~/.claude/statusline-command.sh'

    $claudeDir = Join-Path $HOME '.claude'
    $settings = Join-Path $claudeDir 'settings.json'
    New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

    Invoke-WebRequest -UseBasicParsing -OutFile (Join-Path $claudeDir 'statusline-command.sh') `
        -Uri 'https://raw.githubusercontent.com/markallisongit/claude-statusline/main/statusline-command.sh'

    $raw = $null
    $backup = $null
    if (Test-Path -LiteralPath $settings) {
        $backup = "$settings.bak"
        Copy-Item -LiteralPath $settings -Destination $backup -Force
        $raw = Get-Content -LiteralPath $settings -Raw -Encoding UTF8
    }
    if ([string]::IsNullOrWhiteSpace($raw)) { $raw = '{}' }
    $json = $raw | ConvertFrom-Json
    $json | Add-Member -NotePropertyName statusLine -NotePropertyValue ([pscustomobject]@{ type = 'command'; command = $cmd }) -Force
    $text = $json | ConvertTo-Json -Depth 100
    # BOM-less UTF-8: a BOM breaks Claude Code's JSON parse, and PS 5.1's -Encoding UTF8 writes one
    [IO.File]::WriteAllText($settings, $text + "`n", (New-Object System.Text.UTF8Encoding $false))

    Write-Host "Installed to $claudeDir. statusLine: $cmd"
    if ($backup) { Write-Host "Previous settings saved to $backup" }
}
