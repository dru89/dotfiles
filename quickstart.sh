#!/usr/bin/env bash
command -v brew > /dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
command -v stow > /dev/null || brew install stow
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
