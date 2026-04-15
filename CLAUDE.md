# CLAUDE.md — dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow "topic" whose contents mirror `$HOME`.

## Target environments

These dotfiles run on multiple machines. Changes must work everywhere or be guarded appropriately.

- **MacBook Pro** — work machine (Disney), macOS, primary development environment
- **MacBook Air** — personal macOS machine
- **ds9** — home server running Arch Linux
- **Devboxes** — ephemeral Linux VMs, usually Debian/Ubuntu
- **WSL** — Windows Subsystem for Linux (Ubuntu)

Two quickstart scripts handle installation:
- `quickstart.sh` — macOS: installs Homebrew, stow, stows all topics, runs `brew bundle`
- `quickstart-devbox.sh` — Linux: installs stow via apt, stows only the Linux-compatible subset (bash, shell, git, starship, ripgrep, curl, atuin, bin)

## Repo layout

```
atuin/       → ~/.config/atuin/          Atuin shell history
bash/        → ~/.bashrc, etc.           Shell init, PATH, env
bin/         → ~/bin/                    Standalone scripts (see below)
curl/        → ~/.curlrc                 Custom user-agent
ghostty/     → ~/.config/ghostty/        Terminal keybinds
git/         → ~/.gitconfig, etc.        Git, delta, tig
homebrew/    → ~/Brewfile                Shared Homebrew packages
neovim/      → ~/.config/nvim/           Full Lua neovim config
packages/    (not stowed)                Arch package list for ds9
ripgrep/     → ~/.config/ripgrep/.rgrc   Smart-case default
shell/       → ~/.aliases                Functions: clone, reorg, cdr, cdw, etc.
skills.txt   (not stowed)                Agent skills installed via npx skills add
starship/    → ~/.config/starship.toml   Prompt config
tmux/        → ~/.tmux.conf              tmux config
```

## Work-specific content stays out of this repo

This is a personal repo tracked on public GitHub. Work-specific configuration (enterprise credentials, internal tool paths, VPN-dependent env vars) must never go in tracked files. Use the local escape hatches below.

## Local escape hatches

These untracked files override or extend the dotfiles on a per-machine basis:

| File | Sourced from | Purpose |
|------|-------------|---------|
| `~/.env.local` | `.bashrc` line 45 | Machine-specific env vars, credentials, work paths |
| `~/.localshell` | `.bashrc` line 50 | Additional shell config (secondary escape hatch) |
| `~/.local_gitconfig` | `.gitconfig` `[include]` | Work git settings (credential helpers, signing, email overrides) |
| `~/.Brewfile` | `brew bundle --global` (manual) | Work-specific Homebrew packages |

If a tool or agent needs to set env vars, git config, or install packages that are specific to one machine, put them in the appropriate escape hatch file. Do not modify tracked dotfiles for machine-specific needs.

## Portability rules

1. **No macOS-only syntax without a fallback.** `stat -f %m` is macOS; `stat -c %Y` is Linux. Use both with a fallback chain, or guard with a `uname` check.
2. **No GNU-only or BSD-only flags.** `sed -i ''` (BSD) vs `sed -i` (GNU) is a common trap. Prefer `ed`, `awk`, or a temp file when in-place editing is needed.
3. **Guard platform-specific blocks** with `[[ "$(uname)" == "Darwin" ]]` or similar. See `.bashrc` line 69 for an example.
4. **Homebrew references** should be conditional on `command -v brew`. The Linux machines don't have it.
5. **The devbox quickstart skips** homebrew, ghostty, tmux, neovim, and packages. If you add a new stow topic, decide whether it belongs on Linux and update `quickstart-devbox.sh` accordingly.

## Pre-commit discipline

Before committing, always diff against HEAD. Tools (including AI agents) sometimes edit tracked config files directly when they should have used a local escape hatch. Common things to watch for:

- **`~/.gitconfig` changes** — git credential helpers, user.email, signing keys that are machine-specific should go in `~/.local_gitconfig` instead
- **`~/.bashrc` changes** — env vars for a specific tool installation should go in `~/.env.local`
- **New stow topics** — make sure they're portable or guarded, and update both quickstart scripts if needed

If a diff contains work-specific or machine-specific changes to a tracked file, move those changes to the appropriate escape hatch and revert the tracked file before committing.

## Key functions in shell/.aliases

- `clone <url>` — clones to `$DEVELOPER_DIR/<host>/<org>/<repo>`, creating the directory structure automatically. Detects GitHub orgs and GitLab groups.
- `reorg [--apply]` — audits repos under `$DEVELOPER_DIR` and moves any whose path doesn't match their origin remote. Dry run by default.
- `cdr [query]` / `cdw [query]` — fuzzy directory picker for repos (`$DEVELOPER_DIR`) and writing projects (`~/Writing`). Frecency-ranked, with query prefill and single-match auto-cd.
- `_cdfzf` — shared implementation for `cdr`/`cdw`. Maintains a frecency history at `~/.local/share/cdfzf/history`.

## Scripts in bin/

`~/bin/` is on `$PATH` (set in `.bashrc`). The `bin/` stow topic manages tracked scripts; other tools symlink into `~/bin/` independently. The quickstart scripts pre-create `~/bin/` with `mkdir -p` so stow creates per-file symlinks rather than folding the directory (which would cause untracked files to land in the repo).

Tracked scripts:

- `find-up <pattern>` — walks up the directory tree to find a file matching a glob. Standalone version of the `findup` shell function.
- `newdoc <name>` — creates a writing project at `~/Writing/<name>/` with git, reference dir, and Obsidian project link. Records to cdfzf frecency history.
- `cleanup-branches` — deletes local git branches whose last commit is older than 3 weeks. Protects main, master, and the current branch.
- `mute [on|off|toggle|status]` — macOS-only fake mute that sets volume to 1 instead of 0 so CoreAudio process taps still receive audio data.

Untracked symlinks (managed by their own repos):

- doc-tools: `docfetch`, `gcat`, `gcomments`, `gfetch`, `gpush`, `spfetch`, `cfetch`
- Other tools: `teams-archive`, `transcribe`, `screenshot`, `flush-scratchpad`

## Neovim

Full Lua config under `neovim/.config/nvim/`. Uses lazy.nvim for plugin management, mason for LSP servers. The nvim `.gitignore` includes a `local/` entry for machine-specific plugin overrides (drop a file in `lua/plugins/` and lazy.nvim picks it up).

## Things that don't have local overrides yet

- **tmux** — no `source-file -q ~/.tmux.local.conf` mechanism. If machine-specific tmux config is needed, that line should be added.
- **starship** — no include mechanism in starship's config format. Would need conditional logic or a build step.
- **ghostty** — supports `config-file` for includes, but the current config is minimal (two keybinds).
