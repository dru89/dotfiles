#!/usr/bin/env bash
command -v brew > /dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
command -v stow > /dev/null || brew install stow
mkdir -p "$HOME/bin"
stow --target "$HOME" atuin
stow --target "$HOME" bin
stow --target "$HOME" bash
stow --target "$HOME" curl
stow --target "$HOME" git
stow --target "$HOME" ghostty
stow --target "$HOME" homebrew
stow --target "$HOME" neovim
stow --target "$HOME" ripgrep
stow --target "$HOME" shell
stow --target "$HOME" starship
stow --target "$HOME" tmux

(cd && brew bundle)

# Install global agent skills (requires npm/npx from brew bundle).
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v npx > /dev/null && [[ -f "$DOTFILES/skills.txt" ]]; then
  grep -v '^#' "$DOTFILES/skills.txt" | grep -v '^$' | while read -r skill; do
    npx skills add "$skill" -g -y
  done
else
  echo "Skipped agent skills install — npx not found. Install Node and run:"
  echo "  grep -v '^#' skills.txt | grep -v '^\$' | while read -r s; do npx skills add \"\$s\" -g -y; done"
fi
