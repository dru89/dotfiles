#!/usr/bin/env bash
# macOS dotfiles quickstart.
# Installs Homebrew, stow, stows all topics, and runs brew bundle.

command -v brew > /dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
command -v stow > /dev/null || brew install stow

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pre-create directories so stow creates per-file symlinks, not directory symlinks.
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.claude"

# Stow all topics.
for topic in atuin bash bin claude curl ghostty git homebrew neovim ripgrep shell starship tmux; do
    if [[ -d "${DOTFILES}/${topic}" ]]; then
        stow --target "$HOME" --dir "$DOTFILES" "$topic"
        echo "  stowed: ${topic}"
    fi
done

(cd && brew bundle)

# Install global agent skills (requires npm/npx from brew bundle).
if command -v npx > /dev/null && [[ -f "$DOTFILES/skills.txt" ]]; then
  grep -v '^#' "$DOTFILES/skills.txt" | grep -v '^$' | while read -r skill; do
    npx skills add "$skill" -g -y
  done
else
  echo "Skipped agent skills install — npx not found. Install Node and run:"
  echo "  grep -v '^#' skills.txt | grep -v '^\$' | while read -r s; do npx skills add \"\$s\" -g -y; done"
fi
