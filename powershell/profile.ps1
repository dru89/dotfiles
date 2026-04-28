#Requires -Version 7

# ── Line editing ──────────────────────────────────────────────────────────────
# Must come before atuin so atuin can override Ctrl+R
Set-PSReadLineOption -EditMode Emacs

# ── Starship prompt ───────────────────────────────────────────────────────────
# Point directly at dotfiles to avoid os error 448 when following symlinks
# across OneDrive mount boundaries in SSH sessions.
if (-not $env:STARSHIP_CONFIG) {
    $env:STARSHIP_CONFIG = "$HOME\dotfiles\starship\.config\starship.toml"
}
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ── Atuin shell history ───────────────────────────────────────────────────────
# Skip in SSH sessions: atuin's init sets stdout encoding in a way that fails
# when stdout isn't a proper Windows console (os error from OpenSSH sessions).
if (Get-Command atuin -ErrorAction SilentlyContinue) {
    if (-not ($env:SSH_CLIENT -or $env:SSH_CONNECTION)) {
        Invoke-Expression ((&atuin init powershell) -join "`n")
    }
}

# ── Environment ───────────────────────────────────────────────────────────────
$env:RIPGREP_CONFIG_PATH = "$HOME\dotfiles\ripgrep\.config\ripgrep\.rgrc"
if (-not $env:DEVELOPER_DIR) { $env:DEVELOPER_DIR = "$HOME\Developer" }

# ── Navigation ────────────────────────────────────────────────────────────────
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# ── serve ─────────────────────────────────────────────────────────────────────
function serve {
    param([string]$dir = ".", [int]$port = 3000)
    python -m http.server --directory $dir $port
}

# ── jql ──────────────────────────────────────────────────────────────────────
function jql {
    param([string]$filter = ".")
    $input | jq -C $filter | less -r
}

# ── randstr / randhex ─────────────────────────────────────────────────────────
function randstr {
    param([int]$len = 32)
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = [byte[]]::new($len * 2)
    $rng.GetBytes($bytes)
    -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] } | Select-Object -First $len)
}

function randhex {
    param([int]$len = 32)
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = [byte[]]::new([Math]::Ceiling($len / 2) + 1)
    $rng.GetBytes($bytes)
    (($bytes | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, $len)
}

# ── findup / cdup ─────────────────────────────────────────────────────────────
function findup {
    param([Parameter(Mandatory)][string]$pattern)
    $dir = (Get-Location).Path
    while ($true) {
        $match = Get-ChildItem -Path $dir -Filter $pattern -Force -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($match) { return $match.FullName }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) {
            Write-Error "No match found for '$pattern'"
            return
        }
        $dir = $parent
    }
}

function cdup {
    param([Parameter(Mandatory)][string]$pattern)
    $match = findup $pattern
    if ($match) { Set-Location (Split-Path $match -Parent) }
}

# ── cdr / cdw ─────────────────────────────────────────────────────────────────
# Frecency-ranked fuzzy directory picker for repos (cdr) and writing projects (cdw).
# History file mirrors the bash version's format: <epoch>\t<root>\t<relpath>
# so visit counts are shared if you ever run both shells on the same machine.

$script:_CdfzfHistory = Join-Path $env:LOCALAPPDATA 'cdfzf\history'

function _cdfzf_record([string]$root, [string]$relpath) {
    $dir = Split-Path $script:_CdfzfHistory -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $epoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    Add-Content -Path $script:_CdfzfHistory -Value "$epoch`t$root`t$relpath" -Encoding UTF8
}

function _cdfzf_rank([string]$root, [string[]]$mtimePaths) {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $scores = @{}

    if (Test-Path $script:_CdfzfHistory) {
        foreach ($line in Get-Content $script:_CdfzfHistory) {
            $p = $line -split "`t", 3
            if ($p.Count -lt 3 -or $p[1] -ne $root) { continue }
            $age = $now - [long]$p[0]
            $w = if     ($age -lt 14400)   { 100 }  # 4 hours
                 elseif ($age -lt 86400)   { 70  }  # 1 day
                 elseif ($age -lt 604800)  { 50  }  # 1 week
                 elseif ($age -lt 2592000) { 30  }  # 30 days
                 else                      { 10  }
            if (-not $scores.ContainsKey($p[2])) { $scores[$p[2]] = 0 }
            $scores[$p[2]] += $w
        }
    }

    $mtimePaths | ForEach-Object {
        $p = $_ -split "`t", 2
        $mtime = [long]$p[0]; $path = $p[1]
        $score = if ($scores.ContainsKey($path)) { 10000000000 + $scores[$path] } else { $mtime }
        [pscustomobject]@{ Score = $score; Path = $path }
    } | Sort-Object Score -Descending | Select-Object -ExpandProperty Path
}

function _cdfzf([string]$root, [string]$prompt = "Select: ", [string]$query = "") {
    if (-not (Test-Path $root)) { Write-Warning "Not found: $root"; return }

    $prunePat = 'node_modules|\.venv|venv|__pycache__|\.tox|vendor|target|build|dist|\.next|\.cache'
    $mtimePaths = [Collections.Generic.List[string]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $rootNorm = $root.TrimEnd('\', '/')

    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $excludes = 'node_modules', '.venv', 'venv', '__pycache__', '.tox',
                    'vendor', 'target', 'build', 'dist', '.next', '.cache' |
                    ForEach-Object { '--exclude', $_ }
        $gitDirs  = fd --hidden --type d --max-depth 6 '^\.git$'  $root @excludes 2>$null
        $bareDirs = fd --hidden --type d --max-depth 6 '^\.bare$' $root @excludes 2>$null
    } else {
        $gitDirs  = Get-ChildItem $root -Recurse -Force -Filter '.git'  -Directory -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -notmatch $prunePat } |
                        Select-Object -ExpandProperty FullName
        $bareDirs = Get-ChildItem $root -Recurse -Force -Filter '.bare' -Directory -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -notmatch $prunePat } |
                        Select-Object -ExpandProperty FullName
    }

    foreach ($gd in $gitDirs) {
        if (-not $gd) { continue }
        $repoDir = Split-Path $gd -Parent
        $rel = $repoDir.Substring($rootNorm.Length).TrimStart('\', '/')
        if ($seen.Add($rel)) {
            $mtime = [DateTimeOffset]::new((Get-Item $gd -Force).LastWriteTime).ToUnixTimeSeconds()
            $mtimePaths.Add("$mtime`t$rel")
        }
    }

    foreach ($bd in $bareDirs) {
        if (-not $bd) { continue }
        $containerDir = Split-Path $bd -Parent
        git -C $containerDir worktree list 2>$null | ForEach-Object {
            $wtPath = ($_ -split '\s+')[0]
            if ($wtPath -eq $containerDir -or -not (Test-Path $wtPath -PathType Container)) { return }
            $rel = $wtPath.Substring($rootNorm.Length).TrimStart('\', '/')
            if ($seen.Add($rel)) {
                $gitFile = Join-Path $wtPath '.git'
                $mtime = if (Test-Path $gitFile) {
                    [DateTimeOffset]::new((Get-Item $gitFile -Force).LastWriteTime).ToUnixTimeSeconds()
                } else { 0 }
                $mtimePaths.Add("$mtime`t$rel")
            }
        }
    }

    if ($mtimePaths.Count -eq 0) { Write-Warning "No repos found under $root"; return }

    $ranked = _cdfzf_rank -root $root -mtimePaths $mtimePaths.ToArray()

    if ($query) {
        $matches = @($ranked | Where-Object { $_ -like "*$query*" })
        if ($matches.Count -eq 1) {
            _cdfzf_record $root $matches[0]
            Set-Location (Join-Path $root $matches[0])
            return
        }
    }

    $fzfArgs = @('--height', '40%', '--reverse', '--border', '--prompt', $prompt, '--no-sort')
    if ($query) { $fzfArgs += '--query', $query }

    $selected = $ranked | fzf @fzfArgs
    if ($selected) {
        _cdfzf_record $root $selected
        Set-Location (Join-Path $root $selected)
    }
}

function cdr { param([string]$q) _cdfzf $env:DEVELOPER_DIR "Repo: " $q }
function cdw { param([string]$q) _cdfzf "$HOME\Writing" "Writing: " $q }

# ── PSReadLine syntax colors (Catppuccin Mocha) ───────────────────────────────
Set-PSReadLineOption -Colors @{
    Command          = '#89B4FA'
    Parameter        = '#CDD6F4'
    String           = '#A6E3A1'
    Variable         = '#CBA6F7'
    Comment          = '#6C7086'
    Operator         = '#89DCEB'
    Number           = '#FAB387'
    Type             = '#F9E2AF'
    Error            = '#F38BA8'
    InlinePrediction = '#585B70'
}

# ── Local overrides (machine-specific, untracked) ─────────────────────────────
# Put DEVBOX_HOST, tool completions, work paths, etc. in profile.local.ps1
# next to this file. It's gitignored and sourced automatically if it exists.
$_localProfile = Join-Path (Split-Path $PROFILE -Parent) 'profile.local.ps1'
if (Test-Path $_localProfile) { . $_localProfile }
Remove-Variable _localProfile
