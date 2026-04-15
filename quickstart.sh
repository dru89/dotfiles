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
if command -v npx > /dev/null; then
  npx skills add dru89/sesh -g -y
  npx skills add dru89/sift -g -y
  npx skills add stephenturner/skill-deslop -g -y
else
  echo "Skipped agent skills install — npx not found. Install Node and re-run, or run manually:"
  echo "  npx skills add dru89/sesh -g -y"
  echo "  npx skills add dru89/sift -g -y"
  echo "  npx skills add stephenturner/skill-deslop -g -y"
fi
