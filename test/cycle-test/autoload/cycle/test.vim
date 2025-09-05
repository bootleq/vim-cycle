function! cycle#test#reset_default_groups(...) "{{{
  let settings = a:0 ? a:1 : []

  call cycle#test#clear_all_groups()
  if !empty(settings)
    let g:cycle_default_groups = settings
  endif
  call cycle#test#reinitialize_groups()
endfunction "}}}


function! cycle#test#clear_all_groups() "{{{
  unlet! g:cycle_groups
  unlet! b:cycle_groups
  unlet! b:cycle_ft_groups

  unlet! g:cycle_default_groups
endfunction "}}}


function! cycle#test#reinitialize_groups() "{{{
  let s:scope = themis#helper('scope')
  let s:cycle_plugin = s:scope.funcs('plugin/cycle.vim')
  call s:cycle_plugin.initialize_groups()
endfunction "}}}


function! cycle#test#reset_script_vars() "{{{
  let s:scope = themis#helper('scope')

  let changer_naming = s:scope.funcs('autoload/cycle/changer/naming.vim')
  call changer_naming.reset_transformers()
endfunction "}}}


function! cycle#test#select_ui(options, ctx) "{{{
  let candidates = []
  for option in a:options
    let text = option.text
    call add(candidates, text)
  endfor

  " Set global var for test assertion
  let g:cycle_test_select = {
        \   'items': candidates,
        \ }
  return
endfunction "}}}


function! cycle#test#conflict_ui(options, ctx) "{{{
  let candidates = []
  for option in a:options
    let text = option.text
    call add(candidates, text)
  endfor

  " Set global var for test assertion
  let g:cycle_test_conflict = {
        \   'items': candidates,
        \ }
  return
endfunction "}}}


function! cycle#test#capture(command) abort " {{{
  try
    redir => out
    silent execute a:command
  finally
    redir END
  endtry
  return substitute(out, '\n', '', '')
endfunction " }}}
