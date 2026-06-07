# nest.vim

Tiny Vim plugins for running your life (or any project) as a **plain-text, git-tracked
folder tree** where every folder's index is its `todo.md`. No wikilinks, no database —
just Markdown path links and a handful of function keys.

Two plugins:

- **[`plugin/nest.vim`](nest.md)** — navigate and reshape the folder/`todo.md` tree.
- **[`plugin/goal.vim`](goal.md)** — declare an hourly/daily goal and *commit* to it.

## Install

With [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'ethankennerly/nest.vim'
```

Or drop the files in by hand / symlink them:

```sh
ln -s ~/nest.vim/plugin/nest.vim ~/.vim/plugin/nest.vim
ln -s ~/nest.vim/plugin/goal.vim ~/.vim/plugin/goal.vim
```

Needs [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) for search; the move/rename
helpers use `git mv` when inside a repo. `goal.vim`'s timestamps use BSD `date` (macOS).
For `goal.vim`'s commit coupling, also add the
[`git deliver` alias](goal.md#installing-the-git-deliver-alias).
