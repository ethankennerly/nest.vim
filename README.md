# nest.vim

Tiny Vim plugins for running your life (or any project) as a **plain-text, git-tracked
folder tree** where every folder's index is its `todo.md`. No wikilinks, no database —
just Markdown path links and a handful of function keys.

Two plugins:

- **`plugin/nest.vim`** — navigate and reshape the folder/`todo.md` tree.
- **`plugin/goal.vim`** — declare an hourly/daily goal and *commit* to it.

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
For `goal.vim`'s commit coupling, also add the [`git deliver` alias](#installing-the-git-deliver-alias).

## nest.vim — the tree

Convention: every folder has a `todo.md`. Line order = priority.
Forward link (parent → child): `- [ ] [name](name/todo.md)`. Leaf file: `- [ ] [name](name.txt)`.
Backlink, first line of a child: `- [..](../todo.md)`.

| key | does |
|-----|------|
| `F6` | add node (`name/` = folder, `name` = leaf `.txt`) + bidirectional link |
| `F7` | fuzzy `:find` across the repo |
| `F8` | promote leaf → folder (`foo.md` → `foo/todo.md`, fix links) |
| `F9` | move (folder or leaf) relative to here, fix links, surface stray refs |
| `F10`| go up to the parent node |
| `F11`| rename node or leaf, relink |
| `F12`| ripgrep the word under the cursor → quickfix |
| `<CR>`| (markdown) follow the first link on the line |

Commands: `:NestAdd :NestExpand :NestMove :NestUp :NestRename :Rg`. `:grep` is ripgrep-powered
(`-tcs`, `-tmd` type filters). Remove `plugin/nest.vim` to undo everything; it never edits `~/.vimrc`.

## goal.vim — make your hourly goal the subject of your next commit

An **implementation intention** ("by `HH:00` I will `<goal>`") becomes the subject of your
**next** commit — so when you deliver, the commit is literally labelled with the goal you set.
Inspired by implementation intentions, XP's "commit often", and the Pomodoro habit of
declaring one intention per block. Handy for externalizing intent (and for ADHD focus).

| key | does |
|-----|------|
| `F2` | prompt a ≤50-char **hourly** goal (due = now + 75 min, rounded to the hour) — **commit-coupled** |
| `F5` | prompt a ≤50-char **daily** goal (due = today 15:00) — **logged only** |

50 chars because that's also the git subject-line budget. Both keys upsert one row (per due
time) in the nearest `goals/<kind>-goal.tsv` — a TSV headed `Due Time⇥Goal⇥Distraction`.
**Neither makes a commit.**

It finds the goals file in three steps, so F2/F5 work from any repo without a hardcoded path:

1. walk up from the file you're editing for an ancestor `goals/<kind>-goal.tsv` (per-project);
2. else `g:goal_dir` if you set an exact override;
3. else **search** the globs in `g:goal_search` (default `['~/goals', '~/*/goals']`) — the
   newest matching file wins, so it discovers `~/life/goals` *or* `~/Documents/goals` on its own.

Add a location by extending the list, e.g. `let g:goal_search += ['~/work/*/goals']`. When the
goals file lives outside the repo you're editing, the row is logged there while the pending
subject / `git deliver` commit lands in the repo you're working in.

Only the **hourly** goal is coupled to git: F2 also writes the goal to `<repo>/.git/FOCUS_GOAL`,
the pending subject for your next delivery. You deliver with **`git deliver`** — it `git add -A`
(so the goal's own `goals/*.tsv` row and the rest of your working tree land in the commit — one
unit of progress), commits with `FOCUS_GOAL` as the subject, then clears it (one delivery per
hourly goal). With no pending goal, `git deliver` does nothing (and stages nothing). Plain
`git commit` is untouched. The commit's timestamp is your real delivery time, not when you set
the goal. The **daily** goal (F5) is just logged — a day spans
many commits, so it isn't tied to any one of them.

- **Pivot** (relabel WIP, nothing delivered yet): press F2 again → the pending subject is just
  overwritten. No commit, no amend, no force-push.
- **Expand** (previous hourly goal delivered): `git deliver` consumed the old goal as its
  subject; the new goal becomes the next pending subject → naturally the next delivery.

Commands: `:GoalHourly :GoalDaily`. Remove `plugin/goal.vim` and the alias to undo.

### Installing the `git deliver` alias

The alias lives in this repo's [`gitconfig`](gitconfig). Include it from your global config —
no hooks, no machine-wide config, `git commit` untouched:

```sh
git config --global --add include.path "$PWD/gitconfig"
```

Then deliver with `git deliver` (flags pass through, e.g. `git deliver -a`). Undo by removing
that `include.path` line from `~/.gitconfig`.

## Tests

```sh
bash test/goal.test.sh
```

Covers F2/F5 logging, hourly pivot (one row per hour), and `git deliver` (subject from the
goal, cleared after; no-op without a pending goal). Needs `vim` and `git`.

## License

MIT
