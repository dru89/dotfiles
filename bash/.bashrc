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
[ -n "$(command -v brew)" ] && [ -f "$(brew --prefix)/etc/profile.d/bash_completion.sh" ] && source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
command -v fzf &>/dev/null && eval "$(fzf --bash)"

if [ -f ~/.config/ripgrep/.rgrc ]; then
    export RIPGREP_CONFIG_PATH=~/.config/ripgrep/.rgrc
fi

[ -f ~/.env.local ] && source ~/.env.local

export EDITOR=nvim

[ -f ~/.aliases ] && source ~/.aliases
test -f ~/.localshell && source ~/.localshell
: "${DEVELOPER_DIR:=$HOME/Developer}"

# go binaries
command -v go > /dev/null && export PATH="$PATH:$(go env GOPATH)/bin"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

command -v starship &>/dev/null && eval "$(starship init bash)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm end

# pnpm
if [[ "$(uname)" == "Darwin" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
command -v atuin &>/dev/null && eval "$(atuin init bash)"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
command -v sesh &>/dev/null && eval "$(sesh init bash)"

# Periodically check for missing tools (every 30 days)
_check_missing_tools() {
    local stamp="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles_tool_check"
    local interval_days=30
    local now last
    now=$(date +%s)
    last=$(cat "$stamp" 2>/dev/null || echo 0)
    (( (now - last) / 86400 < interval_days )) && return

    local missing=()
    command -v fzf      &>/dev/null || missing+=("fzf")
    command -v atuin    &>/dev/null || missing+=("atuin")
    command -v starship &>/dev/null || missing+=("starship")
    command -v gh       &>/dev/null || missing+=("gh")
    command -v gum      &>/dev/null || missing+=("gum")
    command -v sesh     &>/dev/null || missing+=("sesh")
    command -v delta    &>/dev/null || missing+=("delta")
    [ -f "$HOME/.cargo/env" ]       || missing+=("rust/cargo")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "dotfiles: missing tools: ${missing[*]}"
    fi

    mkdir -p "$(dirname "$stamp")"
    echo "$now" > "$stamp"
}
_check_missing_tools
unset -f _check_missing_tools
