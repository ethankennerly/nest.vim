#!/bin/bash
# Tests for goal.vim (F2 hourly / F5 daily) and the `git deliver` alias.
# Convention: prints "ok"/"FAIL" per case; exits non-zero if any fail.
# Requires: vim, git. Run: bash test/goal.test.sh
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$REPO/plugin/goal.vim"
pass=0; fail=0

assert_eq(){ # <expected> <actual> <description>
  if [ "$1" = "$2" ]; then pass=$((pass+1)); printf 'ok   - %s\n' "$3"
  else fail=$((fail+1)); printf 'FAIL - %s\n        expected: %s\n        actual:   %s\n' "$3" "$1" "$2"; fi
}
assert_absent(){ # <path> <description>
  if [ ! -e "$1" ]; then pass=$((pass+1)); printf 'ok   - %s\n' "$2"
  else fail=$((fail+1)); printf 'FAIL - %s (exists: %s)\n' "$2" "$1"; fi
}

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
git -C "$T" init -q
git -C "$T" config user.email t@t
git -C "$T" config user.name t
git -C "$T" config include.path "$REPO/gitconfig"     # provides `git deliver`
mkdir -p "$T/goals" "$T/area"
printf 'Due Time\tGoal\tDistraction\n' > "$T/goals/hourly-goal.tsv"
printf 'Due Time\tGoal\tDistraction\n' > "$T/goals/daily-goal.tsv"
printf 'note\n' > "$T/area/note.txt"
git -C "$T" add -A; git -C "$T" commit -qm "init"

# set_goal <GoalHourly|GoalDaily> <goal text>  (edits area/note.txt in $T)
set_goal(){ printf '%s\n' "$2" | vim -es -u NONE -N \
  -c "so $PLUGIN" -c "e $T/area/note.txt" -c "$1" -c 'qa!' >/dev/null 2>&1; }

last_goal(){ tail -n1 "$1" | cut -f2; }   # goal column of last tsv row
rows(){ grep -c . "$1"; }                  # non-empty line count

# 1. F2 hourly: logs a row + stages the pending subject
set_goal GoalHourly "write the parser"
assert_eq "write the parser" "$(last_goal "$T/goals/hourly-goal.tsv")" "F2 logs hourly goal row"
assert_eq "write the parser" "$(cat "$T/.git/FOCUS_GOAL" 2>/dev/null)" "F2 writes FOCUS_GOAL"

# 2. Pivot: same hour replaces the row (not appended) + overwrites pending subject
set_goal GoalHourly "pivot to the tests"
assert_eq "2" "$(rows "$T/goals/hourly-goal.tsv")" "pivot keeps one hourly row (header+1)"
assert_eq "pivot to the tests" "$(cat "$T/.git/FOCUS_GOAL")" "pivot overwrites FOCUS_GOAL"

# 3. git deliver: stages EVERYTHING (incl. the unstaged goal tsv), commits with
#    the goal as subject, clears FOCUS_GOAL. NOTE: no pre-staging here on purpose.
printf 'more\n' >> "$T/area/note.txt"               # an unstaged working-tree change
git -C "$T" deliver -q
assert_eq "pivot to the tests" "$(git -C "$T" log -1 --pretty=%s)" "deliver uses goal as subject"
assert_absent "$T/.git/FOCUS_GOAL" "deliver clears FOCUS_GOAL"
assert_eq "" "$(git -C "$T" status --porcelain)" "deliver commits the whole tree (incl. goal tsv)"

# 4. git deliver with no pending goal: no commit, nothing staged, change preserved
before="$(git -C "$T" rev-list --count HEAD)"
printf 'bb\n' >> "$T/area/note.txt"                 # unstaged
git -C "$T" deliver >/dev/null 2>&1 || true
assert_eq "$before" "$(git -C "$T" rev-list --count HEAD)" "deliver with no goal makes no commit"
assert_eq " M area/note.txt" "$(git -C "$T" status --porcelain)" "deliver with no goal stages nothing"

# 5. F5 daily: logs only, not coupled to a commit
rm -f "$T/.git/FOCUS_GOAL"
set_goal GoalDaily "clean, reply, browse 3 studios"
assert_eq "clean, reply, browse 3 studios" "$(last_goal "$T/goals/daily-goal.tsv")" "F5 logs daily goal row"
assert_absent "$T/.git/FOCUS_GOAL" "F5 does NOT write FOCUS_GOAL"

# 6. Global discovery via g:goal_search glob (no hardcoded path): F2 from a repo with
#    no ancestor goals/ finds the goals file; the subject lands in the working repo.
GBASE="$(mktemp -d)"; W2="$(mktemp -d)"; trap 'rm -rf "$T" "$GBASE" "$W2"' EXIT
mkdir -p "$GBASE/life/goals"
printf 'Due Time\tGoal\tDistraction\n' > "$GBASE/life/goals/hourly-goal.tsv"
git -C "$W2" init -q; git -C "$W2" config user.email t@t; git -C "$W2" config user.name t
printf 'code\n' > "$W2/main.txt"; git -C "$W2" add -A; git -C "$W2" commit -qm "init"
discover(){ printf '%s\n' "$2" | vim -es -u NONE -N \
  -c "let g:goal_search=['$GBASE/*/goals']" -c "so $PLUGIN" -c "e $W2/main.txt" -c "$1" -c 'qa!' >/dev/null 2>&1; }
discover GoalHourly "discovered via search"
assert_eq "discovered via search" "$(last_goal "$GBASE/life/goals/hourly-goal.tsv")" "F2 discovers goals via g:goal_search glob"
assert_eq "discovered via search" "$(cat "$W2/.git/FOCUS_GOAL" 2>/dev/null)" "F2 writes FOCUS_GOAL to the working repo"

# 7. Newest matching file wins (not alphabetical) when several locations match
mkdir -p "$GBASE/Documents/goals"
printf 'Due Time\tGoal\tDistraction\n' > "$GBASE/Documents/goals/hourly-goal.tsv"
touch -t 200001010000 "$GBASE/Documents/goals/hourly-goal.tsv"   # Documents = old
touch "$GBASE/life/goals/hourly-goal.tsv"                        # life = newest
discover GoalHourly "newest wins"
assert_eq "newest wins" "$(last_goal "$GBASE/life/goals/hourly-goal.tsv")" "newest matching goals file wins"
assert_eq "Due Time	Goal	Distraction" "$(tail -n1 "$GBASE/Documents/goals/hourly-goal.tsv")" "older location left untouched"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
