function! cycle#callback#restrict_cursor#do(params) "{{{
  let before = a:params.before
  let after = a:params.after
  let pos = cycle#util#getpos()
  let end_col = before.col + strlen(after.text) - 1

  if a:params.class_name == 'v' || (after.text =~ '\W' && g:cycle_auto_visual)
    if mode() =~? '^v'
      execute "normal! \<Esc>"
    endif
    call cursor(before.line, before.col)
    normal! v
    call cursor(after.line, end_col)
  elseif after.line > before.line
    call cursor(after.line, end_col)
  else
    if end_col < pos.col
      call cursor(after.line, end_col)
    elseif pos.col < after.col
      call cursor(after.line, after.col)
    endif
  endif
endfunction "}}}
