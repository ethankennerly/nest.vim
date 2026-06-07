set ruler
set et ts=4 sw=4
set clipboard=unnamed
set hls
set noswapfile
set autoindent
set ignorecase

" F2 hourly-goal / F5 daily-goal live in plugin/goal.vim (log the goal + commit it)
" goal.vim auto-discovers goals/ via g:goal_search (~/goals, ~/*/goals) — finds
" ~/life/goals or ~/Documents/goals with no hardcoded path.

" Go to file and change local directory
nnoremap <F3> :lcd %:p:h:pwd
nnoremap <F4> gf:lcd %:p:h:pwd

filetype plugin indent on
syntax on

colorscheme desert
set colorcolumn=100
hi ColorColumn ctermbg=black guibg=black

" Unity YAML
autocmd! BufNewFile,BufRead *.preab set ft=yaml

" TypeScript syntax with React triggered a slow redraw.
autocmd! BufNewFile,BufRead *.ts,*.tsx syntax off | setlocal ts=2 sw=2

" TSV
set list
set listchars=tab:▸\ ,trail:·
highlight SpecialKey ctermfg=darkgray guifg=#444444
autocmd! BufNewFile,BufRead *.tsv setlocal noet ts=4

" gx — open URL under cursor in default browser (uses macOS 'open')
let g:netrw_browsex_viewer = 'open'
