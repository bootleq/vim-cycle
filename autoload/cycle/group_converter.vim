" Convert switch.vim dict definition to cycle groups

function! cycle#group_converter#regex_dict(dict) "{{{
  let items = []
  let replacers = []

  for [pattern, sub] in items(a:dict)
    call add(items, pattern)
    call add(replacers, sub)
  endfor

  return [items, {
        \   'matcher': 'regex',
        \   'changer': 'regex',
        \   'replacer': replacers,
        \ }]
endfunction "}}}


function! cycle#group_converter#regex_dict_list(dicts) "{{{
  let groups = []
  for dict in a:dicts
    let group = cycle#group_converter#regex_dict(dict)
    call add(groups, group)
  endfor
  return groups
endfunction "}}}
