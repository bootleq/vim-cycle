" Year changer
"
" Change year to different calendar era systems.
" If converted year is invalid because over its known range (e.g., 昭和99
" doesn't exist) then the item is discarded, try change to next item.


" Params:
"   - ctext:        Ctext
"   - group:        Group
"   - next_index:   number
" Returns:
"   Ctext - the changed text info (might keep old text if no valid result)
function! cycle#changer#year#change(ctext, group, next_index) "{{{
  let old_index = a:next_index == 0 ? len(a:group.items) - 1 : a:next_index - 1
  let old_item = a:group.items[old_index]
  let old_cfg = get(g:cycle_year_config, old_item)

  " Given item might not be valid (e.g., out of range), have to try each
  let seq = range(len(a:group.items))
  let skip_idx = index(seq, old_index)
  let work_seq = extend(slice(seq, skip_idx + 1), slice(seq, 0, skip_idx))

  for idx in work_seq
    let new_text = s:change(a:ctext, a:group, old_index, idx)
    if !empty(new_text)
      break
    endif
  endfor

  if empty(new_text) " no valid result, return ctext unchanged
    return deepcopy(a:ctext)
  endif

  let new_text = {
        \   'text': new_text,
        \   'line': a:ctext.line,
        \   'col': a:ctext.col,
        \ }
  return new_text
endfunction "}}}


" Generate selection candidates from group items.
" The 'current' matched item should be excluded (don't bother user review it).
"
" Params:
"   - ctext: Ctext  - matched text
"   - group: Group  - matched group
"   - index: number - index of matched item.
" Returns:
"   list<Match>
function! cycle#changer#year#collect_selections(ctext, group, index) "{{{
  let matches = []

  for idx in range(len(a:group.items))
    if idx != a:index
      let changed = s:change(a:ctext, a:group, a:index, idx)
      if !empty(changed)
        let after = extend(deepcopy(a:ctext), {'text': changed}, 'force')
        let m = {
              \   'group': a:group,
              \   'pairs': {
              \     'before': a:ctext,
              \     'after': after,
              \   },
              \   'index': idx,
              \ }
        call add(matches, m)
      endif
    endif
  endfor

  return matches
endfunction " }}}


function! s:change(ctext, group, old_index, index) abort " {{{
  let old_item = a:group.items[a:old_index]
  let old_cfg = get(g:cycle_year_config, old_item)

  let new_item = a:group.items[a:index]
  let new_cfg = get(g:cycle_year_config, new_item)

  if new_item == 'CE'
    let offset = old_cfg.begin - 1
    let new_text = substitute(a:ctext.text, old_item . '\s*\v(\d+)', {m -> str2nr(m[1]) + offset}, '')
  else
    if old_item == 'CE'
      let offset = 0 - new_cfg.begin + 1
      let new_text = a:ctext.text
    else
      let offset = old_cfg.begin - new_cfg.begin
      let new_text = strpart(a:ctext.text, len(old_item))
    endif

    let new_text = new_item . new_text
    let new_text = substitute(new_text, '\v(\d+)', {m -> str2nr(m[1]) + offset}, '')
    let result_year = str2nr(matchstr(new_text, '\v-?\d+'))

    if result_year > new_cfg.range[1] || result_year < new_cfg.range[0]
      let new_text = '' " discard this item
    endif
  endif

  return new_text
endfunction " }}}
