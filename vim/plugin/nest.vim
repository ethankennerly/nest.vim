" nest.vim — folder/todo.md monorepo helpers (markdown path links, no wikilinks)
" Convention: every folder has todo.md. Forward link in parent: - [ ] [name](name/todo.md)
" Backlink first line of child: - [..](../todo.md)
" Keys: F6 add (name/=folder node, name=leaf .txt) + link  F7 fuzzy find  F8 expand  F9 move
"       F10 go-up (parent node)  F11 rename (node or leaf)  F12 grep <cword> -> quickfix
"       <CR> (markdown) follow first link on the line
" Commands: :NestAdd {name} :NestExpand :NestMove {destdir} :NestUp :NestRename {name} :Rg {args}
" Remove this file to undo everything. Does not modify ~/.vimrc.

if exists('g:loaded_nest') | finish | endif
let g:loaded_nest = 1

" the one global behavior change (delete if unwanted): fuzzy cmdline popup menu
set wildmenu wildoptions=pum,fuzzy

function! s:Root() abort
  let l:dir = expand('%:p:h')
  let l:top = systemlist('git -C ' . shellescape(l:dir) . ' rev-parse --show-toplevel')
  return (v:shell_error == 0 && len(l:top) > 0) ? l:top[0] : l:dir
endfunction

function! s:InGit() abort
  call system('git -C ' . shellescape(expand('%:p:h')) . ' rev-parse --is-inside-work-tree')
  return v:shell_error == 0
endfunction

" 1. add node + bidirectional link. Trailing / => folder node; else => leaf (.txt default; type .md/.tsv/.csv to override).
function! s:Add(...) abort
  let l:raw = a:0 && !empty(a:1) ? a:1 : trim(input('New (name=leaf, name/=folder): '))
  if empty(l:raw) | return | endif
  let l:base = expand('%:p:h')
  if l:raw =~# '/$'
    let l:name = substitute(l:raw, '/\+$', '', '')
    let l:dir = l:base . '/' . l:name
    let l:child = l:dir . '/todo.md'
    if filereadable(l:child) | execute 'edit' fnameescape(l:child) | return | endif
    call append(line('.'), '- [ ] [' . l:name . '](' . l:name . '/todo.md)')
    silent write
    call mkdir(l:dir, 'p')
    call writefile(['# ' . l:name, '', '- [..](../todo.md)', ''], l:child)
    execute 'edit' fnameescape(l:child)
    normal! G
  else
    let l:fname = l:raw =~# '\.\w\+$' ? l:raw : l:raw . '.txt'
    let l:disp = fnamemodify(l:fname, ':r')
    let l:path = l:base . '/' . l:fname
    if filereadable(l:path) | execute 'edit' fnameescape(l:path) | return | endif
    call append(line('.'), '- [ ] [' . l:disp . '](' . l:fname . ')')
    silent write
    call writefile(['# ' . l:disp, ''], l:path)
    execute 'edit' fnameescape(l:path)
    normal! G
  endif
endfunction
command! -nargs=? NestAdd call s:Add(<f-args>)
nnoremap <silent> <F6> :call <SID>Add()<CR>

" 2. search-nested-or-fuzzy: fuzzy :find across the repo (type chars then <Tab>).
function! s:Find() abort
  let &l:path = '.,' . s:Root() . '/**'
  call feedkeys(":find ", 'n')
endfunction
nnoremap <silent> <F7> :call <SID>Find()<CR>

" content search via ripgrep -> quickfix (upgrades :silent grep {x} **/*)
" with grepprg set, plain `:grep foo` recurses + respects .gitignore (no **/* needed),
" and `:grep -tcs foo` / `:grep -tmd foo` scope by filetype reusably.
set grepprg=rg\ --vimgrep\ --smart-case
set grepformat=%f:%l:%c:%m

" :Rg {ripgrep args} -> quickfix.  Reusable filetype scoping via rg types (vs brittle **/*.cs):
"   :Rg foo        :Rg -tcs foo        :Rg -tmd todo        (`rg --type-list` shows all types)
command! -nargs=+ Rg call s:Rg(<q-args>)
function! s:Rg(args) abort
  let l:out = systemlist('rg --vimgrep --smart-case ' . a:args . ' ' . shellescape(s:Root()))
  call setqflist([], ' ', {'lines': l:out, 'efm': '%f:%l:%c:%m', 'title': 'rg ' . a:args})
  copen
endfunction

" F12: ripgrep the word under cursor in this folder + its subfolders, open quickfix
function! s:GrepWord() abort
  let l:word = expand('<cword>')
  if empty(l:word) | return | endif
  let l:out = systemlist('rg --vimgrep --smart-case --fixed-strings ' . shellescape(l:word) . ' ' . shellescape(expand('%:p:h')))
  call setqflist([], ' ', {'lines': l:out, 'efm': '%f:%l:%c:%m', 'title': 'rg <cword>: ' . l:word})
  copen
endfunction
nnoremap <silent> <F12> :call <SID>GrepWord()<CR>

" 3. expand-file-to-folder: foo.md -> foo/todo.md, fix parent link, add backlink
function! s:Expand() abort
  if expand('%:t') ==? 'todo.md' | echo 'already a folder index' | return | endif
  if &modified | silent write | endif
  let l:cur = expand('%:p')
  let l:dir = expand('%:p:h')
  let l:name = expand('%:t:r')
  let l:newdir = l:dir . '/' . l:name
  let l:new = l:newdir . '/todo.md'
  let l:parent = l:dir . '/todo.md'
  if isdirectory(l:newdir) | echo 'folder exists: ' . l:newdir | return | endif
  call mkdir(l:newdir, 'p')
  if s:InGit()
    call system('git -C ' . shellescape(l:dir) . ' mv ' . shellescape(l:cur) . ' ' . shellescape(l:new))
  endif
  if filereadable(l:cur) && !filereadable(l:new)
    call rename(l:cur, l:new)
  endif
  " normalize to: heading, blank, backlink, blank, body  (heading-first per convention)
  let l:body = readfile(l:new)
  let l:title = '# ' . l:name
  if !empty(l:body) && l:body[0] =~# '^#\s'
    let l:title = l:body[0] | call remove(l:body, 0)
  endif
  while !empty(l:body) && l:body[0] =~# '^\s*$'
    call remove(l:body, 0)
  endwhile
  call filter(l:body, 'v:val !~# "(\\.\\./todo\\.md)"')
  let l:out = [l:title, '', '- [..](../todo.md)', '']
  if !empty(l:body) | let l:out += l:body | endif
  call writefile(l:out, l:new)
  if filereadable(l:parent)
    let l:p = readfile(l:parent)
    call map(l:p, 'substitute(v:val, "(\\V' . l:name . '.md)", "(' . l:name . '/todo.md)", "g")')
    call writefile(l:p, l:parent)
  endif
  execute 'edit' fnameescape(l:new)
  echo 'expanded -> ' . l:new
endfunction
command! NestExpand call s:Expand()
nnoremap <silent> <F8> :call <SID>Expand()<CR>

" 4. move: in a todo.md -> move the folder (node) + fix parent links + surface stray refs;
"    in a leaf -> file that leaf into a target folder (repo-relative) + add its link there.
function! s:Move(...) abort
  if expand('%:t') ==? 'todo.md'
    let l:src = expand('%:p:h')
    let l:oldparent = fnamemodify(l:src, ':h')
    let l:name = fnamemodify(l:src, ':t')
    let l:rawdest = a:0 && !empty(a:1) ? a:1 : trim(input('Move folder [' . l:name . '] into dir (relative to here): ', '', 'dir'))
    if empty(l:rawdest) | return | endif
    let l:destparent = l:rawdest =~# '^/' ? l:rawdest : simplify(l:src . '/' . l:rawdest)
    if l:destparent ==# l:oldparent | echo 'already there' | return | endif
    let l:dest = l:destparent . '/' . l:name
    if isdirectory(l:dest) | echo 'dest exists' | return | endif
    call mkdir(l:destparent, 'p')
    if s:InGit()
      call system('git -C ' . shellescape(s:Root()) . ' mv ' . shellescape(l:src) . ' ' . shellescape(l:dest))
    endif
    if isdirectory(l:src) && !isdirectory(l:dest)
      call rename(l:src, l:dest)
    endif
    let l:op = l:oldparent . '/todo.md'
    if filereadable(l:op)
      let l:lines = readfile(l:op)
      call filter(l:lines, 'v:val !~ "](' . l:name . '/todo.md)"')
      call writefile(l:lines, l:op)
    endif
    let l:np = l:destparent . '/todo.md'
    if filereadable(l:np)
      call writefile(readfile(l:np) + ['- [ ] [' . l:name . '](' . l:name . '/todo.md)'], l:np)
    endif
    execute 'edit' fnameescape(l:dest . '/todo.md')
    execute 'lcd' fnameescape(expand('%:p:h'))
    let l:out = systemlist('rg --vimgrep --fixed-strings ' . shellescape(l:name . '/todo.md') . ' ' . shellescape(s:Root()))
    call setqflist([], ' ', {'lines': l:out, 'efm': '%f:%l:%c:%m', 'title': 'stray refs to ' . l:name})
    if !empty(l:out) | copen | wincmd p | endif
    echo 'moved folder -> ' . l:dest
  else
    let l:src = expand('%:p')
    let l:fname = expand('%:t')
    let l:label = expand('%:t:r')
    let l:raw = a:0 && !empty(a:1) ? a:1 : trim(input('File leaf into dir (relative to here): ', '', 'dir'))
    if empty(l:raw) | return | endif
    let l:destdir = l:raw =~# '^/' ? l:raw : simplify(expand('%:p:h') . '/' . l:raw)
    call mkdir(l:destdir, 'p')
    let l:dest = l:destdir . '/' . l:fname
    if filereadable(l:dest) | echo 'dest exists: ' . l:dest | return | endif
    if s:InGit()
      call system('git -C ' . shellescape(s:Root()) . ' mv ' . shellescape(l:src) . ' ' . shellescape(l:dest))
    endif
    if filereadable(l:src) && !filereadable(l:dest)
      call rename(l:src, l:dest)
    endif
    let l:idx = l:destdir . '/todo.md'
    if filereadable(l:idx)
      call writefile(readfile(l:idx) + ['- [ ] [' . l:label . '](' . l:fname . ')'], l:idx)
    endif
    execute 'edit' fnameescape(l:dest)
    execute 'lcd' fnameescape(expand('%:p:h'))
    echo 'filed leaf -> ' . l:dest
  endif
endfunction
command! -nargs=? NestMove call s:Move(<f-args>)
nnoremap <silent> <F9> :call <SID>Move()<CR>

" 5. go-to-parent (up one node). From a leaf -> its folder's todo.md; from todo.md -> parent's.
function! s:GoUp() abort
  let l:target = expand('%:t') ==? 'todo.md' ? expand('%:p:h:h') . '/todo.md' : expand('%:p:h') . '/todo.md'
  if filereadable(l:target)
    execute 'edit' fnameescape(l:target)
    execute 'lcd' fnameescape(expand('%:p:h'))
  else
    echo 'at root (no parent node)'
  endif
endfunction
command! NestUp call s:GoUp()
nnoremap <silent> <F10> :call <SID>GoUp()<CR>

" 6. rename: in a todo.md -> rename the folder node (dir + parent edge + heading);
"    in a leaf -> rename the file (new name may change kebab + extension) + relink in todo.md.
function! s:Rename(...) abort
  if expand('%:t') ==? 'todo.md'
    let l:dir = expand('%:p:h')
    let l:old = fnamemodify(l:dir, ':t')
    let l:parentdir = fnamemodify(l:dir, ':h')
    let l:new = a:0 && !empty(a:1) ? a:1 : trim(input('Rename node [' . l:old . '] to: ', l:old))
    if empty(l:new) || l:new ==# l:old | return | endif
    let l:newdir = l:parentdir . '/' . l:new
    if isdirectory(l:newdir) | echo 'exists: ' . l:newdir | return | endif
    let l:rel = strpart(expand('%:p'), len(l:dir))
    if s:InGit()
      call system('git -C ' . shellescape(s:Root()) . ' mv ' . shellescape(l:dir) . ' ' . shellescape(l:newdir))
    endif
    if isdirectory(l:dir) && !isdirectory(l:newdir)
      call rename(l:dir, l:newdir)
    endif
    let l:pf = l:parentdir . '/todo.md'
    if filereadable(l:pf)
      let l:lines = readfile(l:pf)
      call map(l:lines, 'substitute(v:val, "\\[" . l:old . "\\](" . l:old . "/todo.md)", "[" . l:new . "](" . l:new . "/todo.md)", "g")')
      call writefile(l:lines, l:pf)
    endif
    let l:nf = l:newdir . '/todo.md'
    if filereadable(l:nf)
      let l:nlines = readfile(l:nf)
      if !empty(l:nlines) && l:nlines[0] ==# '# ' . l:old
        let l:nlines[0] = '# ' . l:new
        call writefile(l:nlines, l:nf)
      endif
    endif
    execute 'edit' fnameescape(l:newdir . l:rel)
    execute 'lcd' fnameescape(expand('%:p:h'))
    let l:out = systemlist('rg --vimgrep --fixed-strings ' . shellescape(l:old . '/todo.md') . ' ' . shellescape(s:Root()))
    call setqflist([], ' ', {'lines': l:out, 'efm': '%f:%l:%c:%m', 'title': 'stray refs to ' . l:old})
    if !empty(l:out) | copen | wincmd p | endif
    echo 'renamed node ' . l:old . ' -> ' . l:new
  else
    let l:dir = expand('%:p:h')
    let l:old = expand('%:t')
    let l:new = a:0 && !empty(a:1) ? a:1 : trim(input('Rename leaf [' . l:old . '] to: ', l:old))
    if empty(l:new) || l:new ==# l:old | return | endif
    let l:newpath = l:dir . '/' . l:new
    if filereadable(l:newpath) | echo 'exists: ' . l:new | return | endif
    if &modified | silent write | endif
    let l:src = expand('%:p')
    if s:InGit()
      call system('git -C ' . shellescape(l:dir) . ' mv ' . shellescape(l:src) . ' ' . shellescape(l:newpath))
    endif
    if filereadable(l:src) && !filereadable(l:newpath)
      call rename(l:src, l:newpath)
    endif
    let l:idx = l:dir . '/todo.md'
    if filereadable(l:idx)
      let l:ol = fnamemodify(l:old, ':r')
      let l:nl = fnamemodify(l:new, ':r')
      let l:lines = readfile(l:idx)
      call map(l:lines, 'substitute(v:val, "\\V[" . l:ol . "](" . l:old . ")", "[" . l:nl . "](" . l:new . ")", "g")')
      call writefile(l:lines, l:idx)
    endif
    execute 'edit' fnameescape(l:newpath)
    execute 'lcd' fnameescape(expand('%:p:h'))
    echo 'renamed leaf ' . l:old . ' -> ' . l:new
  endif
endfunction
command! -nargs=? NestRename call s:Rename(<f-args>)
nnoremap <silent> <F11> :call <SID>Rename()<CR>

" 7. follow the first markdown link on the current line (cursor anywhere on the line).
" Mapped to <CR> in markdown buffers, like gf used to "just work" on a todo.txt line.
function! s:Follow() abort
  let l:m = matchlist(getline('.'), '](\([^)]\+\))')
  if empty(l:m)
    execute "normal! \<CR>"
    return
  endif
  let l:t = l:m[1]
  if l:t =~# '^https\?://'
    call system('open ' . shellescape(l:t))
  else
    execute 'edit' fnameescape(simplify(expand('%:p:h') . '/' . l:t))
    execute 'lcd' fnameescape(expand('%:p:h'))
  endif
endfunction
command! NestFollow call s:Follow()
autocmd FileType markdown nnoremap <buffer> <silent> <CR> :call <SID>Follow()<CR>
