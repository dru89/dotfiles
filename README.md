# dotfiles

It's been a bit since the last iteration of my dotfiles. Here's an attempt at round two.

Ideas forked mostly from https://github.com/sjbarag/dotfiles, but keeping a few of my old configs around.

## Vendored files

- `bash/.bash-preexec.sh` — [bash-preexec](https://github.com/rcaloras/bash-preexec), required for atuin and starship hooks in bash. Check for updates occasionally.

## Installation

```sh
stow --target $HOME bash # or some other package
```

Or just use the quickstart:

```sh
./quickstart.sh
```
