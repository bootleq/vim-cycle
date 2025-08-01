if exists('g:loaded_cycle')
  finish
endif
let g:loaded_cycle = 1
let s:save_cpo = &cpoptions
let s:groups_initialzed = 0
set cpoptions&vim


" Default Options: {{{

function! s:set_default(name, value)
  if !exists(a:name)
    execute 'let ' . a:name . ' = ' . string(a:value)
  endif
endfunction

call s:set_default('g:cycle_no_mappings', 0)
call s:set_default('g:cycle_max_conflict', 1)
call s:set_default('g:cycle_select_ui', '')
call s:set_default('g:cycle_conflict_ui', 'confirm')
call s:set_default('g:cycle_auto_visual', 0)
call s:set_default('g:cycle_phased_search', 0)

function! s:initialize_groups()
  if !exists('g:cycle_default_groups')
    call cycle#add_groups([
          \   [['true', 'false']],
          \   [['yes', 'no']],
          \   [['on', 'off']],
          \ ])
  endif

  if exists('g:cycle_default_groups')
    call cycle#add_groups(g:cycle_default_groups)
  endif

  let s:groups_initialzed = 1
endfunction

" }}} Default Options


" Interface: {{{

nnoremap <silent> <Plug>CycleNext   :<C-U>call Cycle('w',  1, v:count1)<CR>
nnoremap <silent> <Plug>CyclePrev   :<C-U>call Cycle('w', -1, v:count1)<CR>
nnoremap <silent> <Plug>CycleSelect :<C-U>call CycleSelect('w')<CR>
vnoremap <silent> <Plug>CycleNext   :<C-U>call Cycle('v',  1, v:count1)<CR>
vnoremap <silent> <Plug>CyclePrev   :<C-U>call Cycle('v', -1, v:count1)<CR>
vnoremap <silent> <Plug>CycleSelect :<C-U>call CycleSelect('v')<CR>

if !g:cycle_no_mappings
  silent! nmap <silent> <unique> <Leader>a <Plug>CycleNext
  silent! vmap <silent> <unique> <Leader>a <Plug>CycleNext
endif

function! Cycle(class_name, direction, count)
  if !s:groups_initialzed
    call s:initialize_groups()
  endif

  call cycle#new(a:class_name, a:direction, a:count)
endfunction

function! CycleSelect(class_name)
  if !s:groups_initialzed
    call s:initialize_groups()
  endif

  call cycle#select(a:class_name)
endfunction

augroup cycle
  autocmd!
  autocmd FileType * call cycle#reset_ft_groups()
augroup END

" }}} Interface


" Finish:  {{{

let &cpoptions = s:save_cpo
unlet s:save_cpo

" }}} Finish


" modeline {{{
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
