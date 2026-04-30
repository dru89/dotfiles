#!/usr/bin/env bash
# Arch Linux dotfiles quickstart.
# Installs packages via pacman and paru, stows all Linux-compatible topics.
# Usage: bash quickstart-arch.sh

set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install paru if not present.
if ! command -v paru &>/dev/null; then
    echo "Installing paru..."
    sudo pacman -S --needed git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi

# Install pacman packages.
if [[ -f "$DOTFILES/packages/arch.txt" ]]; then
    echo "Installing pacman packages..."
    grep -v '^#' "$DOTFILES/packages/arch.txt" | grep -v '^$' | \
        xargs sudo pacman -S --needed --noconfirm
fi

# Install AUR packages.
if [[ -f "$DOTFILES/packages/arch-aur.txt" ]]; then
    echo "Installing AUR packages..."
    grep -v '^#' "$DOTFILES/packages/arch-aur.txt" | grep -v '^$' | \
        xargs paru -S --needed --noconfirm
fi

# Install Go tools (requires go from pacman packages above).
echo "Installing Go tools..."
go install github.com/dru89/sesh/cmd/sesh@latest

# Set default shell to the pacman-managed bash.
BASH_PATH=/usr/bin/bash
if [[ "$SHELL" != "$BASH_PATH" ]]; then
    grep -qF "$BASH_PATH" /etc/shells || echo "$BASH_PATH" | sudo tee -a /etc/shells
    chsh -s "$BASH_PATH"
fi

# Pre-create directories so stow creates per-file symlinks, not directory symlinks.
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.claude"

# Stow all Linux-compatible topics (skip homebrew).
for topic in atuin bash bin claude curl ghostty git neovim ripgrep shell starship tmux; do
    if [[ -d "${DOTFILES}/${topic}" ]]; then
        stow --target "$HOME" --dir "$DOTFILES" "$topic"
        echo "  stowed: ${topic}"
    fi
done

# Install global agent skills (requires npm from pacman packages).
if command -v npx &>/dev/null && [[ -f "$DOTFILES/skills.txt" ]]; then
    grep -v '^#' "$DOTFILES/skills.txt" | grep -v '^$' | while read -r skill; do
        npx skills add "$skill" -g -y
    done
else
    echo "Skipped agent skills install — npx not found. Install Node and run:"
    echo "  grep -v '^#' skills.txt | grep -v '^\$' | while read -r s; do npx skills add \"\$s\" -g -y; done"
fi

echo "Dotfiles installed."
