# Installs the statusline for the current user. Needs only Windows PowerShell 5.1 or later.
# Usage: irm https://raw.githubusercontent.com/markallisongit/claude-statusline/main/install.ps1 | iex

# Script block keeps $ErrorActionPreference and variables out of the caller's session under iex
& {
    $ErrorActionPreference = 'Stop'

    # PS 5.1 may default to TLS 1.0, which GitHub rejects
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $claudeDir = Join-Path $HOME '.claude'
    $settings = Join-Path $claudeDir 'settings.json'
    $script = Join-Path $claudeDir 'statusline-command.ps1'
    New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

    Invoke-WebRequest -UseBasicParsing -OutFile $script `
        -Uri 'https://raw.githubusercontent.com/markallisongit/claude-statusline/main/statusline-command.ps1'

    # Forward slashes so the path survives whichever shell Claude Code runs the command in
    $cmd = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' + ($script -replace '\\', '/') + '"'

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
