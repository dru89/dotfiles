# ~/.bashrc

export PATH="${HOME}/bin:${HOME}/.local/bin:/opt/homebrew/bin:${PATH}"

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Disable Ctrl-s/Ctrl-q flow control (XOFF/XON) — frees up Ctrl-s
stty -ixon 2>/dev/null

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
# shopt -s globstar

# enable color support of ls on macOS
export CLICOLOR=YES
# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
[ -f "$(brew --prefix)/etc/profile.d/bash_completion.sh" ] && source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
eval "$(fzf --bash)"

if [ -f ~/.config/ripgrep/.rgrc ]; then
    export RIPGREP_CONFIG_PATH=~/.config/ripgrep/.rgrc
fi

[ -f ~/.env.local ] && source ~/.env.local

export EDITOR=nvim

[ -f ~/.aliases ] && source ~/.aliases
test -f ~/.localshell && source ~/.localshell

# go binaries
command -v go > /dev/null && export PATH="$PATH:$(go env GOPATH)/bin"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

eval "$(starship init bash)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm end

# pnpm
export PNPM_HOME="/Users/drew.hays/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

. "$HOME/.atuin/bin/env"
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"

# opencode
export PATH=/Users/drew.hays/.opencode/bin:$PATH

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/drew.hays/.lmstudio/bin"
# End of LM Studio CLI section

. "$HOME/.cargo/env"
command -v sesh &>/dev/null && eval "$(sesh init bash)"
