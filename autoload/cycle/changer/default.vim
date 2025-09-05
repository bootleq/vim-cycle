" Params:
"   - ctext: Ctext        - matched text
"   - group: Group        - matched group
"   - next_index: number  - index of next item of current match
" Returns:
"   Ctext - the changed text info
function! cycle#changer#default#change(ctext, group, next_index) "{{{
  let item = a:group.items[a:next_index]
  let new_text = deepcopy(a:ctext)
  let options = get(a:group, 'options', {})

  let new_text.text = s:text_transform(
        \   a:ctext.text,
        \   item,
        \   options,
        \ )

  return new_text
endfunction "}}}


" Params:
"   - ctext: Ctext  - matched text
"   - group: Group  - matched group
"   - index: number - index of matched item.
" Returns:
"   list<Match>
function! cycle#changer#default#collect_selections(ctext, group, index) "{{{
  let matches = []
  let new_text = cycle#text#new_ctext('')

  for idx in range(len(a:group.items))
    if idx != a:index
      let changed_text = call('cycle#changer#default#change', [a:ctext, a:group, idx])
      let new_text = extend(deepcopy(new_text), changed_text, 'force')
      let m = {
            \   'group': a:group,
            \   'pairs': {
            \     'before': deepcopy(a:ctext),
            \     'after': deepcopy(new_text)
            \   },
            \   'index': idx
            \ }
      call add(matches, m)
    endif
  endfor

  return matches
endfunction "}}}


function! s:text_transform(before, after, options) "{{{
  let text = a:after

  if !get(a:options, 'hard_case')
    let text = s:imitate_case(text, a:before)
  endif

  return text
endfunction "}}}


function! s:imitate_case(text, reference) "{{{
  if a:reference =~# '^\u*$'
    return toupper(a:text)
  elseif a:reference =~# '^\U*$'
    return tolower(a:text)
  else
    let uppers = substitute(a:reference, '\U', '0', 'g')
    let new_text = tolower(a:text)
    while uppers !~ '^0\+$'
      let index = match(uppers, '[^0]')
      if len(new_text) < index
        break
      endif
      let new_text = substitute(new_text, '\%' . (index + 1) . 'c[a-z]', toupper(new_text[index]), '')
      let uppers = substitute(uppers, '\%' . (index + 1) . 'c.', '0', '')
    endwhile
    return new_text
  endif
endfunction "}}}
