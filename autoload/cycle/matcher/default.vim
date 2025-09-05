" Params:
"   - group:      Group
"   - class_name: TextClass
"   - ctx:        dict - arbitrary search info shared during group_search
" Returns:
"   list<matched_col: number, ctext: Ctext>
function! cycle#matcher#default#test(group, class_name, ctx) abort "{{{
  let options = get(a:group, 'options', {})
  let pos = cycle#util#getpos()
  let index = -1
  let ctext = cycle#text#new_ctext(a:class_name)

  for item in a:group.items
    if get(options, 'match_word') && a:class_name != 'w'
      continue
    endif

    if a:class_name != ''
      let pattern = join([
            \   '\%' . ctext.col . 'c',
            \   cycle#util#escape_pattern(item),
            \   get(options, 'match_case') ? '\C' : '\c',
            \ ], '')
    else
      " No match in other defined classes, try search backward/forward over current col
      let pattern = join([
            \   '\%>' . max([0, pos.col - strlen(item)]) . 'c',
            \   '\%<' . (pos.col + 1) . 'c' . cycle#util#escape_pattern(item),
            \   get(options, 'match_case') ? '\C' : '\c',
            \ ], '')
    endif
    let text_index = match(getline('.'), pattern)

    if a:class_name == 'v' && item != cycle#text#new_cvisual().text
      continue
    endif

    if a:class_name == 'w' && item != cycle#text#new_cword().text
      continue
    endif

    if text_index >= 0
      let text = strpart(getline('.'), text_index, len(item))

      let ambi_pair = get(options, 'ambi_pair')
      if !empty(ambi_pair) && index(ambi_pair, text) > -1
        " For begin pair, if there was no end pair found, accept it as orphan.
        let accept_orphan = !empty(get(options, 'end_with')) && index(get(a:ctx, 'ambi_pair_found', []), text) < 0

        if cycle#matcher#default#ambi_pair#test(text, options)
          let founds = get(a:ctx, 'ambi_pair_found', [])
          let founds = uniq(founds + [text])
          call extend(a:ctx, {'ambi_pair_found': founds}, 'force')
        elseif !accept_orphan
          continue
        endif
      endif

      let index = index(a:group.items, item)
      let ctext = {
            \   'text': text,
            \   'line': line('.'),
            \   'col': text_index + 1,
            \ }
      break
    endif
  endfor

  return [index, ctext]
endfunction " }}}
