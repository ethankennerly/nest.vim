#!/bin/sh
# nest.vim installer — one script, no plugin manager.
# Symlinks the plugins (and this repo's vimrc) into place and wires up the
# `git deliver` alias. Re-runnable: existing real files are backed up, existing
# symlinks are repointed. Undo by deleting the links and the include.path line.
#
#   sh install.sh
#
# Minimal deps (vs the vim-plug route, which also needs the plugin manager):
#   vim, git  — required
#   rg        — ripgrep, for F7/F12/:Rg/:grep search (warn if missing)
#   BSD date  — goal.vim timestamps assume macOS `date -v` (warn if GNU date)
set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"

# prompt on the tty; default No (keep what's there). non-interactive => No.
confirm() {
  printf '%s [y/N] ' "$1" >&2
  if [ -r /dev/tty ]; then read ans </dev/tty || ans=; else ans=; fi
  case "$ans" in [yY]*) return 0 ;; *) return 1 ;; esac
}

# symlink $1 -> ... at $2. Already correct => skip. Anything else present =>
# ask (default keep); a real file we replace is backed up first.
link() {
  src="$1"; dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "already linked $dst"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if ! confirm "overwrite existing $dst?"; then
      echo "kept existing $dst (skipped)"
      return
    fi
    if [ -L "$dst" ]; then
      rm "$dst"
    else
      bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$bak"
      echo "backed up $dst -> $bak"
    fi
  fi
  ln -s "$src" "$dst"
  echo "linked $dst -> $src"
}

# --- deps -------------------------------------------------------------------
miss=
for c in vim git; do
  command -v "$c" >/dev/null 2>&1 || miss="$miss $c"
done
if [ -n "$miss" ]; then
  echo "error: missing required:$miss" >&2
  exit 1
fi
command -v rg >/dev/null 2>&1 || \
  echo "warning: ripgrep (rg) not found — F7/F12/:Rg/:grep search won't work"
date -v+1M >/dev/null 2>&1 || \
  echo "warning: 'date -v' (BSD/macOS) not found — goal.vim F2/F5 timestamps may fail on GNU date"

# --- plugins ----------------------------------------------------------------
mkdir -p "$HOME/.vim/plugin"
link "$REPO/plugin/nest.vim" "$HOME/.vim/plugin/nest.vim"
link "$REPO/plugin/goal.vim" "$HOME/.vim/plugin/goal.vim"

# --- vimrc ------------------------------------------------------------------
link "$REPO/vimrc" "$HOME/.vimrc"

# --- git deliver alias ------------------------------------------------------
if git config --global --get-all include.path 2>/dev/null | grep -Fxq "$REPO/gitconfig"; then
  echo "git include.path already set -> $REPO/gitconfig"
else
  git config --global --add include.path "$REPO/gitconfig"
  echo "added git include.path -> $REPO/gitconfig (enables 'git deliver')"
fi

echo "done. open vim: F6-F12 nest, F2/F5 goals; deliver with 'git deliver'."
