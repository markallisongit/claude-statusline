# Claude Code status line for Windows. Windows PowerShell 5.1 or pwsh, nothing else needed.
# Same segments and colours as statusline-command.sh.
$ErrorActionPreference = 'SilentlyContinue'

function Clean($value) {
    if ($null -eq $value) { return '' }
    return ([string]$value) -replace '[\x00-\x1f\x7f-\x9f]', ''
}

function IsNumber($value) {
    return ($value -is [double]) -or ($value -is [decimal]) -or ($value -is [int64]) -or ($value -is [int])
}

# Rounds half away from zero
function Round($value) {
    return [int][math]::Round([double]$value, [MidpointRounding]::AwayFromZero)
}

# Read stdin as UTF-8 bytes: console code pages would mangle non-ASCII paths
$buffer = New-Object IO.MemoryStream
[Console]::OpenStandardInput().CopyTo($buffer)
$json = [Text.Encoding]::UTF8.GetString($buffer.ToArray()) | ConvertFrom-Json

$esc = [char]27
$reset = "${esc}[0m"
$sep = "${esc}[38;2;108;112;134m | $reset"
function Paint($code, $text) { return "${esc}[${code}m$text$reset" }

$cwd = Clean $json.workspace.current_dir
if (-not $cwd) { $cwd = Clean $json.cwd }
$model = Clean $json.model.display_name
$effort = Clean $json.effort.level
$usedCtx = $json.context_window.used_percentage
$usedSession = $json.rate_limits.five_hour.used_percentage
$usedWeek = $json.rate_limits.seven_day.used_percentage
$weekReset = $json.rate_limits.seven_day.resets_at

# Git branch, only when git is installed and cwd is a repo
$branch = ''
if ($cwd -and (Get-Command git -ErrorAction SilentlyContinue)) {
    $env:GIT_OPTIONAL_LOCKS = '0'
    git -C $cwd rev-parse --git-dir *> $null
    if ($LASTEXITCODE -eq 0) { $branch = Clean (git -C $cwd symbolic-ref --short HEAD 2> $null) }
}

$segments = @()
$segments += Paint '1;38;2;203;166;247' "$(Clean $env:USERNAME)@$(Clean $env:COMPUTERNAME)"
$segments += Paint '38;2;137;180;250' $cwd
if ($branch) { $segments += Paint '38;2;166;227;161' $branch }
if ($model) { $segments += Paint '38;2;180;190;254' $model }
if ($effort) { $segments += Paint '38;2;250;179;135' $effort }

if (IsNumber $usedCtx) {
    $ctx = Round $usedCtx
    if ($ctx -ge 80) { $color = '38;2;243;139;168' } elseif ($ctx -ge 50) { $color = '38;2;249;226;175' } else { $color = '38;2;148;226;213' }
    $segments += Paint $color "ctx:$ctx%"
}

if (IsNumber $usedSession) {
    $left = Round (100 - [double]$usedSession)
    $segments += "${esc}[38;2;186;194;222mS${esc}[38;2;127;132;156m$left%$reset"
}

if (IsNumber $usedWeek) {
    $left = Round (100 - [double]$usedWeek)
    $segments += "${esc}[38;2;186;194;222mW${esc}[38;2;127;132;156m$left%$reset"
}

if (IsNumber $weekReset) {
    $left = [long][math]::Floor([double]$weekReset) - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($left -gt 0) {
        $days = [math]::Floor($left / 86400)
        $hours = [math]::Floor(($left % 86400) / 3600)
        $mins = [math]::Floor(($left % 3600) / 60)
        if ($days -gt 0) { $text = "${days}d${hours}h" } elseif ($hours -gt 0) { $text = "${hours}h${mins}m" } else { $text = "${mins}m" }
        $segments += Paint '38;2;127;132;156' "$text remaining"
    }
}

# UTF-8 without BOM: console output encodings would mangle non-ASCII text
$bytes = [Text.Encoding]::UTF8.GetBytes(($segments -join $sep) + "`n")
$stdout = [Console]::OpenStandardOutput()
$stdout.Write($bytes, 0, $bytes.Length)
$stdout.Flush()
