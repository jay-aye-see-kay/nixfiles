let g:fern#default_hidden = 1
let g:fern#disable_default_mappings = 1
let g:fern#hide_cursor = 1
let g:fern#renderer = "nerdfont"

function! s:init_fern() abort
  " make window movements match all other buffer types
  nnoremap <buffer> <C-j> <C-w>j
  nnoremap <buffer> <C-k> <C-w>k
  nnoremap <buffer> <C-h> <C-w>h
  nnoremap <buffer> <C-l> <C-w>l

  nmap <buffer> y <Plug>(fern-action-yank)
  nmap <buffer> gx <Plug>(fern-action-open:system)

  " mark for bulk renamer
  nmap <buffer> m <Plug>(fern-action-mark)
  vmap <buffer> m <Plug>(fern-action-mark)
  nmap <buffer> M <Plug>(fern-action-mark:clear)

  " modify file system
  nmap <buffer> N <Plug>(fern-action-new-path)
  nmap <buffer> D <Plug>(fern-action-trash)
  nmap <buffer> R <Plug>(fern-action-rename)
  nmap <buffer> C <Plug>(fern-action-copy)

  " navigate file tree
  nmap <buffer> h <Plug>(fern-action-collapse)
  nmap <buffer> l <Plug>(fern-action-open-or-expand)
  nmap <buffer> <CR> <Plug>(fern-action-open-or-expand)

  " use H and L to like h and l but change dir too
  nmap <buffer> H <Plug>(fern-action-leave)
  nmap <buffer> L <Plug>(fern-action-enter)

  " open file to [direction] and leave fern split open
  nmap <buffer> oj <Plug>(fern-action-open:below)
  nmap <buffer> ok <Plug>(fern-action-open:above)
  nmap <buffer> oh <Plug>(fern-action-open:left)
  nmap <buffer> ol <Plug>(fern-action-open:right)
endfunction

function! s:init_fern_replacer() abort
  " enter confirms and exits renaming
  nmap <buffer> <cr> <cmd>w<cr>
  imap <buffer> <cr> <cmd>w<cr>

  " covering up a quirk: w writes and closes, so wq closes an extra window
  cnoremap <buffer> wq w
endfunction

augroup fern
  autocmd! *
  autocmd FileType fern call s:init_fern()
  " covering up a quirk: w writes and closes, so wq closes an extra window
  autocmd FileType fern-replacer call s:init_fern_replacer()
augroup END
