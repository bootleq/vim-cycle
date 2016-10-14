function! Print(obj)
  if exists('*PP')
    PP a:obj
  else
    echomsg string(a:obj)
  endif
endfunction


let g:cycle_groups = []
call cycle#add_group( ['foo', 'bar'])
call cycle#add_group( ['foo', 'bar'], 'match_case' )
call cycle#add_group( ['foO', 'baR'], 'hard_case' )
call cycle#add_group( ['foo', 'bar'], {'name': 'test'}, 'match_case' )
call cycle#add_group( ['foo', 'bar'], 'match_case' )
call cycle#add_group( [['foo', 'bar'], 'match_case'] )

call cycle#add_groups([
      \   [['\big(:\big)', '\Big(:\Big)', '\bigg(:\bigg)', '\Bigg(:\Bigg)'], 'sub_pairs', 'hard_case', 'match_case'],
      \   [['\big[:\big]', '\Big[:\Big]', '\bigg[:\bigg]', '\Bigg[:\Bigg]'], 'sub_pairs', 'hard_case', 'match_case'],
      \   [['\big\l:\big\r', '\Big\l:\Big\r', '\bigg\l:\bigg\r', '\Bigg\l:\Bigg\r'], 'sub_pairs', 'hard_case', 'match_case']
      \ ])
call cycle#add_group([
      \ ['\langle:\rangle', '\lfloor:\rfloor', '\lVert:\rVert', '\lceil:\rceil'],
      \ 'sub_pairs', 'hard_case', 'match_case'])

call Print(g:cycle_groups)
