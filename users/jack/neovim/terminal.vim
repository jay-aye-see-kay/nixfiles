function! s:terminal_config() abort
  " stops terminal side scrolling
  setlocal nonumber norelativenumber signcolumn=no

  " ctrl-c, ctrl-p, ctrl-n, enter should all be passed through from normal mode
  nnoremap <buffer> <C-C> i<C-C><C-\><C-n>
  nnoremap <buffer> <C-P> i<C-P><C-\><C-n>
  nnoremap <buffer> <C-N> i<C-N><C-\><C-n>
  nnoremap <buffer> <CR> i<CR><C-\><C-n>

  " keep 'other' terminal cursor visible when in normal mode
  hi! TermCursorNC ctermfg=15 guifg=#fdf6e3 ctermbg=14 guibg=#5f875f cterm=NONE gui=NONE

  " darker background, used in terminal-insert mode
  hi ActiveTermBg ctermbg=0 guibg=#181818
endfunction

augroup termConfig
  autocmd!
  autocmd TermOpen * call s:terminal_config()

  " darken terminal background when in insert mode
  autocmd TermEnter * set winhighlight=Normal:ActiveTermBg
  autocmd TermLeave * set winhighlight=Normal:Normal
augroup END

" escape from terminal mode
tnoremap <ESC> <C-\><C-n>
