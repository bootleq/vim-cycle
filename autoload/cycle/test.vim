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
