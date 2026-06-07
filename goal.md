# goal.vim — make your hourly goal the subject of your next commit

[← back to README](README.md)

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

## Installing the `git deliver` alias

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
