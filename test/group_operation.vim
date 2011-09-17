function! Print(obj)
  if exists('*PP')
    PP a:obj
  else
    echomsg string(a:obj)
  endif
endfunction


let g:cycle_groups = []
call cycle#add_group( ['foo', 'bar'], 'match_case' )
call cycle#add_group( ['foo', 'bar'], {'name': 'test'}, 'match_case' )
call cycle#add_group( ['foo', 'bar'], 'match_case' )
call cycle#add_group( [['foo', 'bar'], 'match_case'] )

call Print(g:cycle_groups)
