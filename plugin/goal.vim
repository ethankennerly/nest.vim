" goal.vim — F2 hourly / F5 daily goal. Both log to the nearest
" goals/<kind>-goal.tsv. The HOURLY goal (F2) is also coupled to git: it becomes
" the subject of your next commit, so when you deliver, the commit is literally
" labelled with the goal you set. The DAILY goal (F5) only logs — a day spans
" many commits, so it isn't tied to any single one.
" Companion to nest.vim. Remove this file (and the `git deliver` alias) to undo.
"
" Model (focus, not bookkeeping):
"   F2 makes NO commit. It writes the goal into <repo>/.git/FOCUS_GOAL — the
"   pending subject for your next delivery. You commit with `git deliver` (a
"   one-line git alias: git add -A, then commit using FOCUS_GOAL as the subject,
"   then clear it — so one delivery = one hourly goal, and the goal's own tsv row
"   is included). Plain `git commit` stays vanilla.
"   - Pivot (relabel WIP, nothing delivered yet): press again -> the pending
"     message is just overwritten. No commit, no amend, no force-push.
"   - Expand (previous goal delivered): your delivery commit consumed the old
"     goal as its subject; the new goal becomes the next pending subject.
"   - The commit timestamp is your real delivery time, not when you set the goal.
"   Subject only, never a body. <=50 chars (also the git subject budget).
"   Inspired by implementation intentions + XP "commit often" + Pomodoro.
"
" Convention: a goals/ folder (this dir or any ancestor) with TSVs headed
"   Due Time<TAB>Goal<TAB>Distraction
" F2 hourly due = now + 75 min, rounded to the hour. F5 daily due = today 15:00.
" One row per due time: pressing again for the same hour/day replaces that row.
"
" The hourly git coupling needs the `git deliver` alias (see README):
" goal.vim only writes the pending message; `git deliver` turns it into the subject.

if exists('g:loaded_goal') | finish | endif
let g:loaded_goal = 1

" Finding a global goals/ when none is in an ancestor, so F2/F5 work from any repo.
" No hardcoded path: g:goal_search is a list of globs, searched in order, and the
" newest matching file wins — so it discovers ~/life/goals or ~/Documents/goals on
" its own. g:goal_dir is an optional exact-path override that beats the search.
if !exists('g:goal_dir')    | let g:goal_dir = ''                          | endif
if !exists('g:goal_search') | let g:goal_search = ['~/goals', '~/*/goals'] | endif

" nearest goals/<name>: ancestor walk (per-project) -> g:goal_dir -> g:goal_search
function! s:NearestGoalFile(name) abort
  let l:dir = expand('%:p:h')
  while 1
    let l:cand = l:dir . '/goals/' . a:name
    if filereadable(l:cand) | return l:cand | endif
    let l:up = fnamemodify(l:dir, ':h')
    if l:up ==# l:dir | break | endif
    let l:dir = l:up
  endwhile
  if !empty(g:goal_dir)
    let l:g = expand(g:goal_dir) . '/' . a:name
    if filereadable(l:g) | return l:g | endif
  endif
  " search the global locations; newest matching file wins
  let l:best = '' | let l:bestt = -1
  for l:pat in g:goal_search
    let l:base = l:pat =~# '^\~' ? expand('~') . strpart(l:pat, 1) : l:pat
    for l:d in glob(l:base, 0, 1)
      let l:cand = l:d . '/' . a:name
      if filereadable(l:cand) && getftime(l:cand) > l:bestt
        let l:best = l:cand | let l:bestt = getftime(l:cand)
      endif
    endfor
  endfor
  return l:best
endfunction

" upsert a Due-Time<TAB>Goal row: replace the row for a:due if present, else append
function! s:Upsert(file, due, goal) abort
  let l:lines = filereadable(a:file) ? readfile(a:file) : []
  let l:row = a:due . "\t" . a:goal
  let l:i = 0
  while l:i < len(l:lines)
    if stridx(l:lines[l:i], a:due . "\t") == 0
      let l:lines[l:i] = l:row
      call writefile(l:lines, a:file)
      return
    endif
    let l:i += 1
  endwhile
  call writefile(l:lines + [l:row], a:file)
endfunction

" stage the goal as the pending subject of the working repo's next commit
function! s:Pend(goal) abort
  let l:dir = expand('%:p:h')
  let l:gd = systemlist('git -C ' . shellescape(l:dir) . ' rev-parse --absolute-git-dir')
  if v:shell_error != 0 || empty(l:gd)
    return 'logged (not in a git repo)'
  endif
  call writefile([a:goal], l:gd[0] . '/FOCUS_GOAL')
  return 'pending subject of next commit in ' . fnamemodify(fnamemodify(l:gd[0], ':h'), ':t')
endfunction

function! s:SetGoal(kind, name, due, commit) abort
  let l:file = s:NearestGoalFile(a:name)
  if empty(l:file)
    echohl ErrorMsg | echo 'no goals/' . a:name . ' in an ancestor or g:goal_dir' | echohl NONE
    return
  endif
  let l:goal = trim(input(a:kind . ' goal by ' . a:due . ' (<=50): '))
  if empty(l:goal) | redraw | echo 'cancelled' | return | endif
  if strchars(l:goal) > 50
    let l:goal = strcharpart(l:goal, 0, 50)
    echohl WarningMsg | echo 'truncated to 50 chars' | echohl NONE
  endif
  call s:Upsert(l:file, a:due, l:goal)
  if expand('%:p') ==# l:file | silent edit! | endif
  " only the hourly goal is coupled to a commit; the daily goal just logs
  let l:where = a:commit ? s:Pend(l:goal) : 'logged'
  redraw
  echo a:kind . ' goal: ' . l:goal . '  (' . l:where . ')'
endfunction

function! s:Hourly() abort
  call s:SetGoal('Hourly', 'hourly-goal.tsv', trim(system("date -v+75M '+%Y-%m-%d %H:00'")), 1)
endfunction
function! s:Daily() abort
  call s:SetGoal('Daily', 'daily-goal.tsv', trim(system("date '+%Y-%m-%d 15:00'")), 0)
endfunction

command! GoalHourly call s:Hourly()
command! GoalDaily call s:Daily()
nnoremap <silent> <F2> :call <SID>Hourly()<CR>
nnoremap <silent> <F5> :call <SID>Daily()<CR>
