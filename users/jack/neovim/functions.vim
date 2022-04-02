"
" Misc small custom functions
"

augroup printDebugMacros
  autocmd!
  " JS/TS: print next line
  autocmd FileType javascript,javascriptreact,typescript,typescriptreact nnoremap <leader>rp "0yiwoconsole.log('<C-R>0', <C-R>0);<ESC>
  autocmd FileType javascript,javascriptreact,typescript,typescriptreact vnoremap <leader>rp "0yoconsole.log('<C-R>0', <C-R>0);<ESC>
  " Python print next line
  autocmd FileType python nnoremap <leader>rp "0yiwoprint('<C-R>0', <C-R>0)<ESC>
  autocmd FileType python vnoremap <leader>rp "0yoprint('<C-R>0', <C-R>0)<ESC>
  " Ruby print next line
  autocmd FileType ruby nnoremap <leader>rp "0yiwoputs '<C-R>0: ' + <C-R>0<ESC>
  autocmd FileType ruby vnoremap <leader>rp "0yoputs '<C-R>0: ' + <C-R>0<ESC>
  " Shell print next line
  autocmd FileType sh nnoremap <leader>rp "0yiwoecho "<C-R>0: $<C-R>0"<ESC>
  autocmd FileType sh vnoremap <leader>rp "0yoecho "<C-R>0: $<C-R>0"<ESC>
  " Rust print next line
  autocmd FileType rust nnoremap <leader>rp "0yiwoprintln!("<C-R>0: {:?}", <C-R>0);<ESC>
  autocmd FileType rust vnoremap <leader>rp "0yoprintln!("<C-R>0: {:?}", <C-R>0);<ESC>
  " vimL print next line
  autocmd FileType vim nnoremap <leader>rp "0yiwoecho '<C-R>0: ' <C-R>0<ESC>
  autocmd FileType vim vnoremap <leader>rp "0yoecho '<C-R>0: ', <C-R>0<ESC>
augroup END

" F12 to fix syntax highlighting when needed https://vim.fandom.com/wiki/Fix_syntax_highlighting
noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>

"
" focus floating window, if exists
"
function ToggleFloatingFocus() abort
  let visible_win_ids = nvim_tabpage_list_wins(0)
  let focused_win_id = nvim_get_current_win()

  for win_id in visible_win_ids
    let win_config = nvim_win_get_config(win_id)
    if win_config.relative ==# ''
      continue
    endif

    if win_id !=# focused_win_id
      call nvim_set_current_win(win_id)
    else
      call nvim_set_current_win(win_config.win)
    endif
  endfor
endfunction

nnoremap <C-w><C-f> :call ToggleFloatingFocus()<CR>
nnoremap <C-w>f :call ToggleFloatingFocus()<CR>


"
" Get the project dir, home dir, or root dir, whichever comes first
" (a project dir is defined by having a .git folder)
"
function GetProjectDir() abort
  let current_dir = expand("%:p")
  let parent_dir = fnamemodify(current_dir, ':h')

  while current_dir != parent_dir
    if isdirectory(current_dir . "/.git") || current_dir == $HOME
      return current_dir
    endif

    let current_dir = parent_dir
    let parent_dir = fnamemodify(current_dir, ':h')
  endwhile
endfunction

"
" Identify hl group under cursor
" see: https://vim.fandom.com/wiki/Identify_the_syntax_highlighting_group_used_at_the_cursor
"
nnoremap <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

