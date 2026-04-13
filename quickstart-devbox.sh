#!/usr/bin/env bash
# Devbox dotfiles quickstart.
# Stows Linux-compatible topics — skips Homebrew, ghostty, tmux, and packages.
# Atuin is configured separately by the devbox entrypoint (key/session/server URL).
#
# Invoked by the devbox entrypoint when DEVBOX_DOTFILES_INIT is set, e.g.:
#   DEVBOX_DOTFILES_INIT="bash quickstart-devbox.sh"

set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v stow &>/dev/null || sudo apt-get install -y -q stow 2>/dev/null

# Remove files useradd copies from /etc/skel — they would conflict with stow.
rm -f "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"

# Stow Linux-compatible topics.
# Skipped topics:
#   homebrew  — brew doesn't exist on Linux
#   ghostty   — Mac terminal app
#   packages  — Brewfile
#   tmux      — not installed in the devbox base image
#   neovim    — not installed in the devbox base image
#   atuin     — devbox entrypoint writes key/session/config directly
for topic in bash shell git starship ripgrep curl atuin; do
    if [[ -d "${DOTFILES}/${topic}" ]]; then
        stow --target "$HOME" --dir "$DOTFILES" "$topic"
        echo "  stowed: ${topic}"
    fi
done

echo "Dotfiles installed."
