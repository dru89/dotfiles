#Requires -Version 7
<#
.SYNOPSIS
    One-shot Windows dev environment setup. Safe to re-run.

.DESCRIPTION
    Installs tools, clones dotfiles, and creates symlinks for git, neovim,
    starship, ripgrep, and the PowerShell profile. Checks state before acting
    and never silently overwrites. Steps that require manual action are
    collected and printed at the end.

.NOTES
    Run from any directory — everything uses absolute paths.
    Some steps require an internet connection.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ManualSteps = [Collections.Generic.List[string]]::new()
$script:Warnings    = [Collections.Generic.List[string]]::new()
$script:StepNum     = 0

# ── Output helpers ────────────────────────────────────────────────────────────

function Write-Step([string]$title) {
    $script:StepNum++
    Write-Host ""
    Write-Host "[$script:StepNum] $title" -ForegroundColor Cyan
}

function Write-OK([string]$msg)   { Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Skip([string]$msg) { Write-Host "  SKIP  $msg" -ForegroundColor DarkGray }
function Write-Info([string]$msg) { Write-Host "   ...  $msg" -ForegroundColor DarkCyan }
function Write-Warn([string]$msg) {
    Write-Host "  WARN  $msg" -ForegroundColor Yellow
    $script:Warnings.Add($msg)
}

function Add-ManualStep([string]$msg) {
    $script:ManualSteps.Add($msg)
    Write-Host "  TODO  $msg" -ForegroundColor Yellow
}

# ── Junction helper ───────────────────────────────────────────────────────────
#
# Creates a directory junction at $LinkPath pointing to $TargetPath.
# Used only for the Neovim config directory; file configs are copied instead.
# (Symlinks to files fail with os error 448 in Windows SSH sessions when paths
# cross mount points such as OneDrive boundaries.)
#
# Behavior:
#   - Already a junction to the right target → skip (noop)
#   - Junction to a different target → throw
#   - Real file or directory → throw (caller decides how to handle)
#   - Does not exist → create

function New-SafeJunction {
    param(
        [Parameter(Mandatory)][string]$LinkPath,
        [Parameter(Mandatory)][string]$TargetPath
    )

    if (Test-Path $LinkPath -ErrorAction SilentlyContinue) {
        $item = Get-Item $LinkPath -Force -ErrorAction SilentlyContinue
        $isReparse = $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)

        if ($isReparse) {
            if ($item.Target -eq $TargetPath) {
                Write-Skip (Split-Path $LinkPath -Leaf)
                return
            }
            throw "$(Split-Path $LinkPath -Leaf) already points to '$($item.Target)' — remove it first."
        }

        $kind = if ($item.PSIsContainer) { 'directory' } else { 'file' }
        throw "A real $kind already exists at $LinkPath."
    }

    $parent = Split-Path $LinkPath -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath | Out-Null
    Write-OK (Split-Path $LinkPath -Leaf)
}

# ── Config file copy helper ───────────────────────────────────────────────────
#
# Copies a dotfile config to its destination. Safe to re-run — overwrites the
# destination each time so it stays in sync with dotfiles after a git pull.
# If a stale symlink exists at the destination (from a prior quickstart run),
# it is removed and replaced with a real copy.

function Copy-DotfileConfig {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if (Test-Path $Destination -ErrorAction SilentlyContinue) {
        $item = Get-Item $Destination -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            Remove-Item $Destination -Force
            Write-Info "Replaced symlink → copy: $(Split-Path $Destination -Leaf)"
        }
    }

    $parent = Split-Path $Destination -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    Copy-Item -Path $Source -Destination $Destination -Force
    Write-OK (Split-Path $Destination -Leaf)
}

# ── Package install helpers ───────────────────────────────────────────────────

function Install-WingetPkg([string]$Id, [string]$DisplayName, [string]$Command) {
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Skip "$DisplayName"
        return
    }
    Write-Info "Installing $DisplayName"
    winget install --id $Id --exact --silent `
        --accept-package-agreements --accept-source-agreements
    Write-OK "$DisplayName installed — you may need to restart PowerShell for it to appear on PATH"
}

function Install-ScoopPkg([string]$Pkg) {
    if (Get-Command $Pkg -ErrorAction SilentlyContinue) {
        Write-Skip "$Pkg"
        return
    }
    scoop install $Pkg
    Write-OK "$Pkg installed"
}

# ═════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  Drew's Windows Dev Environment Setup" -ForegroundColor Magenta
Write-Host "  ══════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Safe to re-run. Checks state before every action."

# ═════════════════════════════════════════════════════════════════════════════
# Developer Mode is no longer required. File configs are copied rather than
# symlinked. The only reparse point created is a directory junction for Neovim,
# and junctions do not require Developer Mode.

# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Core tools (winget)"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  FAIL  winget not found. Install 'App Installer' from the Microsoft Store." -ForegroundColor Red
    exit 1
}

$wingetPkgs = @(
    @{ Id = 'Neovim.Neovim';           Name = 'Neovim';       Cmd = 'nvim'     },
    @{ Id = 'Git.Git';                 Name = 'Git';          Cmd = 'git'      },
    @{ Id = 'GitHub.cli';              Name = 'gh';           Cmd = 'gh'       },
    @{ Id = 'GitHub.GitLFS';           Name = 'Git LFS';      Cmd = 'git-lfs'  },
    @{ Id = 'OpenJS.NodeJS.LTS';       Name = 'Node.js LTS';  Cmd = 'node'     },
    @{ Id = 'BurntSushi.ripgrep.MSVC'; Name = 'ripgrep';      Cmd = 'rg'       },
    @{ Id = 'sharkdp.fd';              Name = 'fd';           Cmd = 'fd'       },
    @{ Id = 'dandavison.delta';        Name = 'delta';        Cmd = 'delta'    },
    @{ Id = 'Starship.Starship';       Name = 'Starship';     Cmd = 'starship' },
    @{ Id = 'Atuin.Atuin';             Name = 'Atuin';        Cmd = 'atuin'    },
    @{ Id = 'GoLang.Go';               Name = 'Go';           Cmd = 'go'       },
    @{ Id = 'Rustlang.Rustup';         Name = 'Rustup';       Cmd = 'rustup'   },
    @{ Id = 'junegunn.fzf';            Name = 'fzf';          Cmd = 'fzf'      },
    @{ Id = 'jqlang.jq';               Name = 'jq';           Cmd = 'jq'       }
)

foreach ($pkg in $wingetPkgs) {
    Install-WingetPkg $pkg.Id $pkg.Name $pkg.Cmd
}

# rust-analyzer component (requires rustup on PATH — may need a shell restart first)
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    $components = rustup component list --installed 2>$null
    if ($components -match 'rust-analyzer') {
        Write-Skip 'rust-analyzer'
    } else {
        rustup component add rust-analyzer
        Write-OK 'rust-analyzer component added'
    }
} else {
    Write-Warn "rustup not on PATH yet — restart PowerShell and re-run to add rust-analyzer"
}

# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Scoop + additional packages"

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Scoop"
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod get.scoop.sh | Invoke-Expression
        Write-OK "Scoop installed"
    } catch {
        Write-Warn "Scoop installation failed: $_"
        Add-ManualStep "Install Scoop manually: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm get.scoop.sh | iex"
    }
} else {
    Write-Skip "Scoop"
}

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    foreach ($pkg in @('mingw', 'make', 'tig', 'less')) {
        Install-ScoopPkg $pkg
    }
} else {
    Add-ManualStep "Once Scoop is available, install: scoop install mingw make tig less"
}

# tree-sitter CLI (required for nvim-treesitter grammar builds)
if (Get-Command tree-sitter -ErrorAction SilentlyContinue) {
    Write-Skip "tree-sitter-cli"
} elseif (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g tree-sitter-cli
    Write-OK "tree-sitter-cli installed"
} else {
    Write-Warn "npm not on PATH yet — restart PowerShell and re-run to install tree-sitter-cli"
    Add-ManualStep "After restarting PowerShell: npm install -g tree-sitter-cli"
}

# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Dotfiles"

$dotfilesDir   = "$HOME\dotfiles"
$dotfilesRepo  = 'https://github.com/dru89/dotfiles.git'
$sparseTopics  = 'git', 'neovim', 'starship', 'ripgrep', 'powershell'

if (Test-Path "$dotfilesDir\.git") {
    Write-Info "Updating dotfiles"
    git -C $dotfilesDir pull --ff-only
    git -C $dotfilesDir sparse-checkout add @sparseTopics
    Write-OK "Dotfiles up to date"
} else {
    Write-Info "Cloning dotfiles (sparse)"
    git clone --depth=1 --filter=blob:none --sparse $dotfilesRepo $dotfilesDir
    git -C $dotfilesDir sparse-checkout set @sparseTopics
    Write-OK "Dotfiles cloned"
}

# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Nerd Font"

# Installed fonts live in the registry; checking all of them is slow and
# the font name varies by weight. Just remind the user.
Add-ManualStep @"
Install a Nerd Font if you haven't:
     1. Download JetBrainsMono from https://www.nerdfonts.com/font-downloads
     2. Unzip, select all .ttf files, right-click → Install for all users
     3. Windows Terminal → Settings → your profile → Appearance → Font face
        → set to 'JetBrainsMono Nerd Font'
"@

# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Config files"
#
# File configs are copied rather than symlinked. Symlinks to files fail with
# os error 448 in Windows SSH sessions when paths cross mount points (e.g.
# OneDrive). Re-running this script keeps copies in sync after a dotfiles pull.
# The Neovim directory uses a junction, which Windows handles differently and
# does not trigger the mount-point restriction.

# Git
try { Copy-DotfileConfig "$dotfilesDir\git\.gitconfig"               "$HOME\.gitconfig"               } catch { Write-Warn $_ }
try { Copy-DotfileConfig "$dotfilesDir\git\.gitignore_global"        "$HOME\.gitignore_global"        } catch { Write-Warn $_ }
try { Copy-DotfileConfig "$dotfilesDir\git\.tigrc"                   "$HOME\.tigrc"                   } catch { Write-Warn $_ }

# Starship
New-Item -ItemType Directory -Path "$HOME\.config" -Force | Out-Null
try { Copy-DotfileConfig "$dotfilesDir\starship\.config\starship.toml" "$HOME\.config\starship.toml"  } catch { Write-Warn $_ }

# ripgrep
New-Item -ItemType Directory -Path "$HOME\.config\ripgrep" -Force | Out-Null
try { Copy-DotfileConfig "$dotfilesDir\ripgrep\.config\ripgrep\.rgrc"  "$HOME\.config\ripgrep\.rgrc"  } catch { Write-Warn $_ }

# Neovim — directory junction (transparent to tools, not affected by the symlink restriction)
try { New-SafeJunction "$env:LOCALAPPDATA\nvim" "$dotfilesDir\neovim\.config\nvim" } catch { Write-Warn $_ }

# PowerShell profile — write a stub that dot-sources from dotfiles so that
# profile changes take effect immediately after a dotfiles pull without a
# re-run of this script.
$profileSource  = "$dotfilesDir\powershell\profile.ps1"
$profileDir     = Split-Path $PROFILE -Parent
$localProfile   = Join-Path $profileDir 'profile.local.ps1'
$profileStub    = @"
#Requires -Version 7
# Auto-generated by quickstart-windows.ps1 — do not edit directly.
# Machine-specific config goes in: $localProfile
`$_dotfilesProfile = "$profileSource"
if (Test-Path `$_dotfilesProfile) { . `$_dotfilesProfile }
Remove-Variable _dotfilesProfile
"@

$needsWrite = $true
if (Test-Path $PROFILE -ErrorAction SilentlyContinue) {
    $item = Get-Item $PROFILE -Force -ErrorAction SilentlyContinue
    $isReparse = $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)

    if ($isReparse) {
        # Stale symlink from a prior run — replace with stub.
        Remove-Item $PROFILE -Force
        Write-Info "Replaced profile symlink with stub"
    } elseif ((Get-Content $PROFILE -Raw) -eq $profileStub) {
        Write-Skip "PowerShell profile stub"
        $needsWrite = $false
    } else {
        # Real file with different content. Show it and ask.
        Write-Host ""
        Write-Host "  WARN  $PROFILE is a real file (not a stub)." -ForegroundColor Yellow
        Write-Host "        It will be replaced with a stub that sources dotfiles." -ForegroundColor DarkYellow
        Write-Host "        Machine-specific lines should move to:" -ForegroundColor DarkYellow
        Write-Host "        $localProfile" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "        Current profile:" -ForegroundColor DarkGray
        Get-Content $PROFILE | ForEach-Object { Write-Host "          $_" -ForegroundColor DarkGray }
        Write-Host ""

        $ans = Read-Host "  Replace with stub now? [y/N]"
        if ($ans -match '^[Yy]') {
            Remove-Item $PROFILE -Force
        } else {
            Add-ManualStep "Replace $PROFILE with a stub that sources $profileSource (after moving machine-specific lines to $localProfile)"
            $needsWrite = $false
        }
    }
}

if ($needsWrite) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Set-Content -Path $PROFILE -Value $profileStub -Encoding UTF8
    Write-OK "PowerShell profile stub written"
    if (-not (Test-Path $localProfile)) {
        Add-ManualStep "Create $localProfile with machine-specific config — the tracked profile sources it automatically if it exists"
    }
}

# ═════════════════════════════════════════════════════════════════════════════
Write-Step "GitHub CLI auth"

$ghStatus = gh auth status 2>&1 | Out-String
if ($ghStatus -match 'Logged in') {
    Write-OK "Already authenticated"
} else {
    Add-ManualStep "Authenticate GitHub CLI: gh auth login (choose GitHub.com → HTTPS → web browser)"
}

# ═════════════════════════════════════════════════════════════════════════════
Write-Step "Windows Terminal theme"

Add-ManualStep @"
Add Catppuccin Mocha to Windows Terminal:
     1. Ctrl+, → Open JSON file (bottom-left)
     2. Add to "schemes": https://catppuccin.com/palette (copy the Mocha scheme)
     3. In your PowerShell profile entry, set: "colorScheme": "Catppuccin Mocha"
     4. Set font face to your Nerd Font in the same profile entry
"@

# ═════════════════════════════════════════════════════════════════════════════
Write-Step "First Neovim launch"

Add-ManualStep "Run 'nvim' and wait for lazy.nvim + Mason to finish (~2–5 min). If telescope-fzf-native fails to build, run ':Lazy build telescope-fzf-native.nvim' inside nvim. Quit and relaunch when done."

# ═════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  ══════════════════════════════════════" -ForegroundColor Magenta

if ($script:ManualSteps.Count -eq 0) {
    Write-Host "  All done!" -ForegroundColor Green
    Write-Host "  Reload your profile: . `$PROFILE" -ForegroundColor Cyan
} else {
    Write-Host "  Setup complete. Manual steps remaining:" -ForegroundColor Yellow
    Write-Host ""
    $n = 1
    foreach ($step in $script:ManualSteps) {
        Write-Host "  $n. $step" -ForegroundColor Yellow
        $n++
    }
    Write-Host ""
    Write-Host "  When ready: . `$PROFILE" -ForegroundColor Cyan
}
Write-Host ""
