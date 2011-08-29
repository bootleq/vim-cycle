" Main Functions: {{{

function! cycle#new(class_name, direction, count) "{{{
  let s:direction = a:direction
  let s:count = a:count

  let matches = cycle#search(a:class_name, {'direction': a:direction, 'count': a:count})
  
  if empty(matches) && g:cycle_phased_search
    let matches = cycle#search('', {'direction': a:direction, 'count': a:count})
  endif

  if empty(matches)
    return s:fallback()
  endif

  if len(matches) > 1 && g:cycle_max_conflict > 1
    let choice = s:conflict(matches)
    if choice
      let matches = [matches[choice - 1]]
    else
      echohl WarningMsg | echo "Aborted." | echohl None
      return
    endif
  endif

  if len(matches)
    call s:substitute(
          \   matches[0].group,
          \   matches[0].pairs.before,
          \   matches[0].pairs.after,
          \   a:class_name,
          \ )
  else
    call s:fallback()
  endif
endfunction "}}}

function! cycle#search(class_name, ...) "{{{
  let options = a:0 ? a:1 : {}
  let groups = s:groups()
  let direction = get(options, 'direction', 1)
  let l:count = get(options, 'count', 1)
  let matches = []
  let new_text = s:new_ctext('')
  let new_index = -1

  for group in groups
    if len(matches) && g:cycle_max_conflict <= 1
      break
    endif

    let [index, ctext] = s:group_search(group, a:class_name)
    if index >= 0
      let new_index = (index + direction * l:count) % len(group.items)
      let new_text.text = s:text_transform(
            \   ctext.text,
            \   group.items[new_index],
            \   group.options,
            \ )
      let new_text.col = ctext.col
      call add(matches, {
            \   'group': group,
            \   'pairs': {'before': deepcopy(ctext), 'after': deepcopy(new_text)},
            \ })
    endif
  endfor

  return matches
endfunction "}}}

function! s:substitute(group, before, after, class_name) "{{{
  let pos = s:getpos()
  let end_col = a:before.col + strlen(a:after.text) - 1
  " TODO: substitute with difference ways by group options. (e.g. xml tag pairs)
  call setline('.',
        \   substitute(
        \     getline('.'),
        \     '\%' . a:before.col . 'c' . s:escape_pattern(a:before.text),
        \     s:escape_sub_expr(a:after.text),
        \     ''
        \   )
        \ )

  if a:class_name == 'v' || (a:after.text =~ '\W' && g:cycle_auto_visual)
    call cursor('.', a:before.col)
    normal v
    call cursor('.', end_col)
  elseif end_col < pos.col
    call cursor('.', end_col)
  endif
endfunction  "}}}

function! s:conflict(matches) "{{{
  if len(a:matches) > g:cycle_max_conflict
    redraw
    echohl WarningMsg | echomsg "Cycle: Too many matches (" . len(a:matches) . " found)." | echohl None
    return
  endif

  let index = 0
  let candidates = []
  let captions = []
  for match in a:matches
    let caption = nr2char(char2nr('A') + index)
    call add(candidates, join([
          \   ' ' . caption . ') ',
          \   get(match.group.options, 'name', '') . " => ",
          \   match.pairs.after.text
          \ ], ''))
    call add(captions, '&' . caption)
    let index += 1
  endfor
  return confirm("Cycle with:\n" . join(candidates, "\n"), join(captions, "\n"), 0)
endfunction "}}}

function! s:fallback() "{{{
  " TODO: test for visual mode
  execute "normal " . s:count . "\<Plug>CycleFallback" . (s:direction > 0 ? 'Next' : 'Prev')
endfunction "}}}

" }}} Main Functions


" Group Operations: {{{1
" Structure of groups:
" g:cycle_groups = [                | => a group, scoped by global or buffer
"   {                               |   =>
"     'items':   ['foo', 'bar'],    |   =>
"     'options': {'hard_case': 1},  |   => a group
"   },                              |   =>
" ],                                |

function! s:groups(...) "{{{
  " TODO: optional parse items from omni-complete function
  let groups = []
  for scope in ['b', 'g']
    let name = scope . ':cycle_groups'
    if exists(name)
      let groups += {name}
    endif
  endfor
  return groups
endfunction "}}}

function! s:group_search(group, ...) "{{{
  let options = a:group.options
  let class_name = a:0 ? a:1 : ''
  let pos = s:getpos()
  let index = -1
  let ctext = s:new_ctext(class_name)

  for item in a:group.items
    if type(get(options, 'regex')) == type('')
      let pattern = item
      let text_index = match(getline('.'), pattern)
      if text_index >= 0
        let index = index(a:group.items, item)
        let ctext = {
              \   'text': matchstr(getline('.'), pattern),
              \   'col': text_index + 1,
              \ }
        break
      endif
    else
      " TODO: handle multibyte characters
      if class_name != ''
        let pattern = join([
              \   '\%' . ctext.col . 'c',
              \   s:escape_pattern(item),
              \   get(options, 'match_case') ? '\C' : '\c',
              \ ], '')
      else
        let pattern = join([
              \   '\%>' . max([0, pos.col - strlen(item)]) . 'c',
              \   '\%<' . (pos.col + strlen(item)) . 'c' . s:escape_pattern(item),
              \   get(options, 'match_case') ? '\C' : '\c',
              \ ], '')
      endif
      let text_index = match(getline('.'), pattern)
      if text_index >= 0
        let index = index(a:group.items, item)
        let ctext = {
              \   'text': strpart(getline('.'), text_index, len(item)),
              \   'col': text_index + 1,
              \ }
        break
      endif
    endif
  endfor

  return [index, ctext]
endfunction "}}}

function! s:text_transform(before, after, options) "{{{
  let text = a:after

  if type(get(a:options, 'regex')) == type('')
    let text = matchstr(
          \   a:after,
          \   get(a:options, 'regex'),
          \ )
  endif

  if !get(a:options, 'hard_case')
    let text = s:imitate_case(text, a:before)
  endif

  return text
endfunction "}}}

function! s:add_group(scope, group_attrs) "{{{
  let options = {}

  if len(a:group_attrs) > 1
    if type(a:group_attrs[1]) == type({})
      call extend(options, a:group_attrs[1])
    elseif type(a:group_attrs[1]) == type([])
      for option in a:group_attrs[1]
        if type(option) == type({})
          call extend(options, option)
        else
          let options[option] = 1
        endif
        unlet option
      endfor
    else
      for option in split(a:group_attrs[1])
        let options[option] = 1
      endfor
    endif
  endif

  let group = {
        \ 'items': a:group_attrs[0],
        \ 'options': options,
        \ }

  let name = a:scope . ':cycle_groups'
  if !exists(name)
    let {name} = [group]
  else
    call add({name}, group)
  endif
endfunction "}}}

function! cycle#add_group(group_or_attr, ...) "{{{
  call s:add_group_to('g', a:group_or_attr, a:000)
endfunction "}}}

function! cycle#add_b_group(group_or_attr, ...) "{{{
  call s:add_group_to('b', a:group_or_attr, a:000)
endfunction "}}}

function! cycle#add_groups(groups) "{{{
  for group in a:groups
    call cycle#add_group(group)
  endfor
endfunction "}}}

function! cycle#add_b_groups(groups) "{{{
  for group in a:groups
    call cycle#add_b_group(group)
  endfor
endfunction "}}}

function! s:add_group_to(scope, group_or_attr, ...) "{{{
  if type(a:group_or_attr) == type([])
    call s:add_group(a:scope, a:group_or_attr)
  elseif a:0 > 0
    call s:add_group(a:scope, [a:group_or_attr] + a:1)
  endif
endfunction "}}}

" }}} Group Operations


" Text Classes: {{{

function! s:new_ctext(text_class)
  if a:text_class == 'w'
    let ctext = s:new_cword()
    if ctext.col == 0
      let ctext = s:new_cchar()
    endif
  elseif a:text_class == 'v'
    let ctext = s:new_cvisual()
  else
    let ctext = {
          \   "text": '',
          \   "col": 0,
          \ }
  endif
  return ctext
endfunction

function! s:new_cword()
  let ckeyword = expand('<cword>')
  let cchar = s:new_cchar()
  let cword = {
        \   "text": '',
        \   "col": 0,
        \ }

  if match(ckeyword, cchar.text) >= 0
    let cword.col = match(
          \   getline('.'),
          \   '\%>' . max([0, cchar.col - strlen(ckeyword) - 1]) . 'c' . ckeyword,
          \ ) + 1
    let cword.text = ckeyword
  endif
  return cword
endfunction

function! s:new_cvisual()
  let save_mode = mode()

  call s:save_reg('a')
  normal gv"ay
  let cvisual = {
        \   "text": @a,
        \   "col": getpos('v')[2],
        \ }

  if save_mode == 'v'
    normal gv
  endif
  call s:restore_reg('a')

  return cvisual
endfunction

function! s:new_cchar()
  call s:save_reg('a')
  normal "ayl
  let cchar = {
        \   "text": @a,
        \   "col": getpos('.')[2],
        \ }
  call s:restore_reg('a')
  return cchar
endfunction

function! s:getpos()
  let pos = getpos('.')
  return {
        \   "line": pos[1],
        \   "col": pos[2],
        \ }
endfunction

" }}} Text Classes


" Utils: {{{

function! s:escape_pattern(pattern) "{{{
  return escape(a:pattern, '~\[^$')
endfunction "}}}

function! s:escape_sub_expr(pattern) "{{{
  return escape(a:pattern, '~\&')
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

function! s:save_reg(name) "{{{
  let s:save_reg = [getreg(a:name), getregtype(a:name)]
endfunction "}}}

function! s:restore_reg(name) "{{{
  if exists('s:save_reg')
    call setreg(a:name, s:save_reg[0], s:save_reg[1])
  endif
endfunction "}}}

" }}} Utils
