# nest.vim

Tiny Vim plugins for running your life (or any project) as a **plain-text, git-tracked
folder tree** where every folder's index is its `todo.md`. No wikilinks, no database —
just Markdown path links and a handful of function keys.

Two plugins:

- **[`plugin/nest.vim`](nest.md)** — navigate and reshape the folder/`todo.md` tree.
- **[`plugin/goal.vim`](goal.md)** — declare an hourly/daily goal and *commit* to it.

## Install

Clone, then run the one installer — no plugin manager needed. It symlinks the plugins
and `vimrc` into place and wires up the [`git deliver` alias](goal.md):

```sh
git clone https://github.com/ethankennerly/nest.vim ~/nest.vim
sh ~/nest.vim/install.sh
```

Re-runnable and non-invasive: it never clobbers an existing `~/.vimrc` (or any real file)
without asking — default is to keep what's there; only on a "yes" does it back up and link.
Already-correct symlinks are left alone. Prefer a
plugin manager? `Plug 'ethankennerly/nest.vim'` loads `plugin/*.vim` (then add the alias
yourself, per [goal.md](goal.md#installing-the-git-deliver-alias)).

Deps: `vim` and `git` (required); [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`)
for search; BSD `date` (macOS) for `goal.vim` timestamps. The move/rename helpers use
`git mv` when inside a repo.
