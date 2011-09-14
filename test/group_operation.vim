let g:cycle_groups = []
call cycle#add_group( ['foo', 'bar'], 'match_case' )
call cycle#add_group( ['foo', 'bar'], {'name': 'test'}, 'match_case' )
call cycle#add_group( ['foo', 'bar'], 'match_case' )
call cycle#add_group( [['foo', 'bar'], 'match_case'] )

if exists('*PP')
  PP g:cycle_groups
else
  echomsg string(g:cycle_groups)
endif
