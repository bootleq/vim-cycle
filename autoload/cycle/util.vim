function! cycle#util#save_reg(name) "{{{
  let s:save_reg = [getreg(a:name), getregtype(a:name)]
endfunction "}}}


function! cycle#util#restore_reg(name) "{{{
  if exists('s:save_reg')
    call setreg(a:name, s:save_reg[0], s:save_reg[1])
  endif
endfunction "}}}


function! cycle#util#escape_pattern(pattern) "{{{
  return escape(a:pattern, '.*~\[^$')
endfunction "}}}


function! cycle#util#escape_sub_expr(pattern) "{{{
  return escape(a:pattern, '~\&')
endfunction "}}}
