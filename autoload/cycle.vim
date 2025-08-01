" Constants: {{{

let s:OPTIONS = {
      \ 'name': 'name',
      \ 'match_case': 'match_case',
      \ 'match_word': 'match_word',
      \ 'hard_case': 'hard_case',
      \ 'restrict_cursor': 'restrict_cursor',
      \ 'sub_tag': 'sub_tag',
      \ 'sub_pair': 'sub_pair',
      \ 'sub_pairs': 'sub_pairs',
      \ 'end_with': 'end_with',
      \ 'begin_with': 'begin_with',
      \ 'regex': 'regex',
      \ }

" }}} Constants


" Main Functions: {{{

function! cycle#new(class_name, direction, count) "{{{
  let matches = cycle#search(a:class_name, {'direction': a:direction, 'count': a:count})

  if empty(matches)
    return s:fallback(
          \   a:class_name == 'v' ? "'<,'>" : '',
          \   a:direction,
          \   a:count
          \ )
  endif

  let ctx = {
        \   "class_name": a:class_name,
        \   "direction":  a:direction,
        \   "count":      a:count,
        \ }

  if len(matches) > 1 && g:cycle_max_conflict > 1
    call extend(ctx, {
          \   "matches": matches,
          \   "sid":     s:sid_prefix(),
          \ })
    return s:conflict(ctx)
  endif

  let m = matches[0]
  call s:accept_match(m, ctx)
  call s:set_repeat('Cycle', ctx)
endfunction "}}}


function! cycle#select(class_name) "{{{
  let matches = cycle#search(a:class_name, {'count': '*'})

  if empty(matches)
    echohl WarningMsg | echo "No match, aborted." | echohl None
    return
  endif

  let options = []
  for match in matches
    call add(options, {
          \   "group_name": get(match.group.options, s:OPTIONS.name, ''),
          \   "text":       match.pairs.after.text
          \ })
  endfor

  let ctx = {
        \   "class_name": a:class_name,
        \   "matches":    matches,
        \   "sid":        s:sid_prefix(),
        \ }
  return call(s:select_func, [options, ctx])
endfunction "}}}


function! cycle#search(class_name, ...) "{{{
  let options = a:0 ? a:1 : {}
  let groups = s:groups()
  let direction = get(options, 'direction', 1)
  let l:count = get(options, 'count', 1)
  let matches = []
  let cword = s:new_cword()
  let cchar = s:new_cchar()

  if a:class_name == 'w'
    if len(cchar.text) > 1
      let phases = ['.', 'w']
      if cword != cchar
        call add(phases, '')
      endif
    else
      let phases = ['w', '']
    endif
  elseif a:class_name == 'v'
    let phases = ['v']
  else
    let phases = []
  endif

  for phase in phases
    let matches = s:phased_search(phase, groups, direction, l:count)
    if len(matches)
      break
    endif
  endfor

  return matches
endfunction "}}}


function! s:phased_search(class_name, groups, direction, count) "{{{
  let matches = []

  for group in a:groups
    if len(matches) && g:cycle_max_conflict <= 1 && a:count != '*'
      break
    endif

    let [index, ctext] = s:group_search(group, a:class_name)
    if index >= 0
      if a:count == '*'
        " Grab all group items for CycleSelect
        for item_idx in range(len(group.items))
          if item_idx != index
            call add(matches, s:build_match(ctext, group, item_idx))
          endif
        endfor
      else
        let new_index = (index + a:direction * a:count) % len(group.items)
        call add(matches, s:build_match(ctext, group, new_index))
      endif
    endif
  endfor

  return matches
endfunction "}}}


function! s:substitute(before, after, class_name, items, options) "{{{
  let callbacks = s:parse_callback_options(a:options)
  let callback_params = {
        \   'before': a:before,
        \   'after':  a:after,
        \   'class_name': a:class_name,
        \   'items': a:items,
        \   'options': a:options,
        \ }

  call setline(
        \   a:before.line,
        \   substitute(
        \     getline(a:before.line),
        \     '\%' . a:before.col . 'c' . s:escape_pattern(a:before.text),
        \     s:escape_sub_expr(a:after.text),
        \     ''
        \   )
        \ )

  for Fn in callbacks.after_sub
    call call(Fn, [callback_params])
  endfor
endfunction  "}}}


function! s:conflict(ctx) "{{{
  let matches = a:ctx.matches
  if len(matches) > g:cycle_max_conflict
    redraw
    echohl WarningMsg | echomsg "Cycle: Too many matches (" . len(matches) . " found)." | echohl None
    return
  endif

  let options = []
  for match in matches
    call add(options, {
          \   "group_name": get(match.group.options, s:OPTIONS.name, ''),
          \   "text":       match.pairs.after.text
          \ })
  endfor

  return call(s:conflict_select_func, [options, a:ctx])
endfunction "}}}


function! s:on_select(choice, ctx) "{{{
  let m = {}
  if a:choice && a:choice > 0
    let m = a:ctx.matches[a:choice - 1]
    if !empty(m)
      call s:accept_match(m, a:ctx)
      call s:set_repeat('CycleSelect')
    endif
  else
    redraw
    echohl WarningMsg | echo "Aborted." | echohl None
  endif
endfunction "}}}


function! s:on_resolve_conflict(choice, ctx) "{{{
  let m = {}
  if a:choice && a:choice > 0
    let m = a:ctx.matches[a:choice - 1]
    if !empty(m)
      call s:accept_match(m, a:ctx)
      call s:set_repeat('Cycle', a:ctx)
    endif
  else
    redraw
    echohl WarningMsg | echo "Aborted." | echohl None
  endif
endfunction "}}}


function! s:accept_match(match, ctx) "{{{
  let m = a:match
  call s:substitute(
        \   m.pairs.before,
        \   m.pairs.after,
        \   a:ctx.class_name,
        \   m.group.items,
        \   extend(m.group.options, {(s:OPTIONS.restrict_cursor): 1}),
        \ )
endfunction "}}}


function! s:set_repeat(mapping, ...) "{{{
  let ctx = a:0 ? a:1 : {}

  if a:mapping == 'Cycle'
    silent! call repeat#set(
          \   "\<Plug>Cycle" . (ctx.direction > 0 ? "Next" : "Prev"),
          \   ctx.count
          \ )
  elseif a:mapping == 'CycleSelect'
    silent! call repeat#set("\<Plug>CycleSelect")
  endif
endfunction "}}}


function! s:fallback(range, direction, count) "{{{
  let pos = s:getpos()
  let seq = "\<Plug>CycleFallback" . (a:direction > 0 ? "Next" : "Prev")

  execute a:range . "normal " . a:count . seq
  silent! call repeat#set(seq, a:count)

  if !empty(a:range)
    call cursor(line("'<"), pos.col)
  endif
endfunction "}}}

" }}} Main Functions


" Group Operations: {{{1
" Structure of groups:
" g:cycle_groups = [                | => groups, scoped by global or buffer
"   {                               |   =>
"     'items':   ['foo', 'bar'],    |   =>
"     'options': {'hard_case': 1},  |   => a group
"   },                              |   =>
" ],                                |

function! s:groups(...) "{{{
  let groups = []
  for scope in ['b', 'ft', 'g']
    let name = scope == 'ft' ? 'b:cycle_ft_groups' : scope . ':cycle_groups'

    if exists(name)
      let groups += {name}
    endif
  endfor
  return groups
endfunction "}}}


function! s:group_search(group, class_name) "{{{
  let options = a:group.options
  let pos = s:getpos()
  let index = -1
  let ctext = s:new_ctext(a:class_name)

  for item in a:group.items
    if type(get(options, s:OPTIONS.regex)) == type('')
      let pattern = item
      let text_index = match(getline('.'), pattern)
      if text_index >= 0
        let index = index(a:group.items, item)
        let ctext = {
              \   'text': matchstr(getline('.'), pattern),
              \   'line': line('.'),
              \   'col': text_index + 1,
              \ }
        break
      endif
    else
      if get(options, s:OPTIONS.match_word) && a:class_name != 'w'
        continue
      endif

      if a:class_name != ''
        let pattern = join([
              \   '\%' . ctext.col . 'c',
              \   s:escape_pattern(item),
              \   get(options, s:OPTIONS.match_case) ? '\C' : '\c',
              \ ], '')
      else
        let pattern = join([
              \   '\%>' . max([0, pos.col - strlen(item)]) . 'c',
              \   '\%<' . (pos.col + 1) . 'c' . s:escape_pattern(item),
              \   get(options, s:OPTIONS.match_case) ? '\C' : '\c',
              \ ], '')
      endif
      let text_index = match(getline('.'), pattern)

      if a:class_name == 'v' && item != s:new_cvisual().text
        continue
      endif

      if a:class_name == 'w' && item != s:new_cword().text
        continue
      endif

      if text_index >= 0
        let index = index(a:group.items, item)
        let ctext = {
              \   'text': strpart(getline('.'), text_index, len(item)),
              \   'line': line('.'),
              \   'col': text_index + 1,
              \ }
        break
      endif

    endif
  endfor

  return [index, ctext]
endfunction "}}}


function! s:add_group(scope, group_attrs) "{{{
  let items = copy(a:group_attrs[0])
  let options = {}

  for param in a:group_attrs[1:]
    if type(param) == type({})
      call extend(options, param)
    elseif type(param) == type([])
      for option in param
        if type(option) == type({})
          call extend(options, option)
        else
          let options[option] = 1
        endif
        unlet option
      endfor
    else
      for option in split(param)
        let options[option] = 1
      endfor
    endif
    unlet param
  endfor

  if has_key(options, s:OPTIONS.sub_pairs)
    let separator = type(options.sub_pairs) == type(0) ? ':' : options.sub_pairs
    let [begin_items, end_items] = [[], []]
    for item in items
      let [begin_item, end_item] = split(item, separator)
      call add(begin_items, begin_item)
      call add(end_items, end_item)
    endfor
    unlet options.sub_pairs
    let options.sub_pair = 1
    call s:add_group(a:scope, [begin_items, extend(deepcopy(options), {(s:OPTIONS.end_with): end_items})])
    call s:add_group(a:scope, [end_items, extend(deepcopy(options), {(s:OPTIONS.begin_with): begin_items})])
    return
  endif

  let group = {
        \ 'items': items,
        \ 'options': options,
        \ }

  let name = a:scope == 'ft' ? 'b:cycle_ft_groups' : a:scope . ':cycle_groups'
  if !exists(name)
    let {name} = [group]
  else
    call add({name}, group)
  endif
endfunction "}}}


function! cycle#add_group(group_or_items, ...) "{{{
  call s:add_group_to('g', a:group_or_items, a:000)
endfunction "}}}


function! cycle#add_b_group(group_or_items, ...) "{{{
  call s:add_group_to('b', a:group_or_items, a:000)
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


function! s:add_group_to(scope, group_or_items, ...) "{{{
  if type(a:group_or_items[0]) == type([])
    call s:add_group(a:scope, a:group_or_items)
  elseif a:0 > 0
    call s:add_group(a:scope, [a:group_or_items] + a:1)
  endif
endfunction "}}}


function! cycle#reset_b_groups(...) "{{{
  if exists('b:cycle_groups')
    unlet b:cycle_groups
  endif

  if a:0 && !empty(a:1)
    call cycle#add_b_groups(a:1)
  endif
endfunction "}}}


function! cycle#reset_b_groups_by_filetype() "{{{
  " TODO: Remove this deprecated function
  echohl WarningMsg | echomsg "Cycle: `reset_b_groups_by_filetype` is deprecated, please see `reset_ft_groups`." | echohl None

  let var_name = 'g:cycle_default_groups_for_' . &filetype
  call cycle#reset_b_groups(exists(var_name) ? {var_name} : [])
endfunction "}}}


function! cycle#reset_ft_groups() "{{{
  unlet! b:cycle_ft_groups

  let groups = get(g:, 'cycle_default_groups_for_' . &filetype)
  if !empty(groups)
    for group in groups
      call s:add_group_to('ft', group)
    endfor
  endif
endfunction "}}}

" }}} Group Operations


" Text Classes: {{{

function! s:new_ctext(text_class) "{{{
  if a:text_class == 'w'
    let ctext = s:new_cword()
    if ctext.col == 0
      let ctext = s:new_cchar()
    endif
  elseif a:text_class == '.'
    let ctext = s:new_cchar()
  elseif a:text_class == 'v'
    let ctext = s:new_cvisual()
  else
    let ctext = {
          \   "text": '',
          \   'line': 0,
          \   "col": 0,
          \ }
  endif
  return ctext
endfunction "}}}


function! s:new_cword() "{{{
  let ckeyword = expand('<cword>')
  let cchar = s:new_cchar()
  let cword = {
        \   "text": '',
        \   'line': 0,
        \   "col": 0,
        \ }

  if match(ckeyword, s:escape_pattern(cchar.text)) >= 0
    let cword.line = line('.')
    let cword.col = match(
          \   getline('.'),
          \   '\%>' . max([0, cchar.col - strlen(ckeyword) - 1]) . 'c' . s:escape_pattern(ckeyword),
          \ ) + 1
    let cword.text = ckeyword
  endif
  return cword
endfunction "}}}


function! s:new_cvisual() "{{{
  let save_mode = mode()

  call s:save_reg('a')
  silent normal! gv"ay
  let cvisual = {
        \   "text": @a,
        \   "line": getpos('v')[1],
        \   "col": getpos('v')[2],
        \ }

  if save_mode == 'v'
    normal! gv
  endif
  call s:restore_reg('a')

  return cvisual
endfunction "}}}


function! s:new_cchar() "{{{
  call s:save_reg('a')
  normal! "ayl
  let cchar = {
        \   "text": @a,
        \   "line": getpos('.')[1],
        \   "col": getpos('.')[2],
        \ }
  call s:restore_reg('a')
  return cchar
endfunction "}}}


function! s:getpos() "{{{
  let pos = getpos('.')
  return {
        \   "line": pos[1],
        \   "col": pos[2],
        \ }
endfunction "}}}

" }}} Text Classes


" Optional Callbacks: {{{

function! s:sub_tag_pair(params) "{{{
  let before = a:params.before
  let after = a:params.after
  let options = a:params.options
  let timeout = 600
  let pattern_till_tag_end = '\_[^>]*>'
  let ic_flag = get(options, s:OPTIONS.match_case) ? '\C' : '\c'
  let pos = s:getpos()

  if search(
        \ '\v\</?\m\%' . before.line . 'l\%' . before.col . 'c'
        \              . pattern_till_tag_end . '\C',
        \ 'n',
        \ )
    let in_closing_tag = search('/\m\%' . before.line . 'l\%' . before.col . 'c\C', 'n')
    let opposite = searchpairpos(
          \   '<' . s:escape_pattern(before.text) . pattern_till_tag_end,
          \   '',
          \   '</' . s:escape_pattern(before.text) . '\s*>'
          \        . (in_closing_tag ? '\zs' : '') . ic_flag,
          \   'nW' . (in_closing_tag ? 'b' : ''),
          \   '',
          \   '',
          \   timeout,
          \ )

    if opposite != [0, 0]
      let ctext = {
            \   "text": before.text,
            \   "line": opposite[0],
            \   "col": opposite[1] + 1 + !in_closing_tag,
            \ }
      let len_diff = strlen(after.text) - strlen(ctext.text)

      call s:substitute(
            \   ctext,
            \   after,
            \   '-',
            \   [],
            \   s:cascade_options_for_callback(options),
            \ )

      if in_closing_tag && ctext.line == after.line
        let new_col = before.col + len_diff
        if a:params.class_name == 'v'
          normal! "_y
          call cursor(pos.line, new_col)
          normal! vt>
        else
          if pos.col > new_col + strlen(after.text)
            call cursor(pos.line, new_col)
            execute 'normal! t>'
          else
            call cursor(pos.line, pos.col + len_diff)
          endif
        endif
      endif

    endif
  endif
endfunction "}}}


function! s:sub_pair(params) "{{{
  let before = a:params.before
  let after = a:params.after
  let options = a:params.options
  let timeout = 600
  let ic_flag = get(options, s:OPTIONS.match_case) ? '\C' : '\c'

  if type(get(options, s:OPTIONS.end_with)) == type([])
    let at_begin = 1
  elseif type(get(options, s:OPTIONS.begin_with)) == type([])
    let at_begin = 0
  else
    return
  endif
  let pair_at = at_begin ? 'end' : 'begin'

  let pair_before = deepcopy(before)
  let pair_before.text = get(
        \   options[pair_at . '_with'],
        \   index(a:params.items, before.text, 0, ic_flag ==# '\c'),
        \ )
  let pair_after = {}
  let pair_after.text = get(
        \   options[pair_at . '_with'],
        \   index(a:params.items, after.text, 0, ic_flag ==# '\c'),
        \ )

  let opposite = searchpairpos(
        \   s:escape_pattern(at_begin ? before.text : pair_before.text),
        \   '',
        \   s:escape_pattern(at_begin ? pair_before.text : pair_after.text)
        \        . (at_begin ? '' : '\zs') . ic_flag,
        \   'nW' . (at_begin ? '' : 'b'),
        \   '',
        \   '',
        \   timeout,
        \ )
  if opposite != [0, 0]
    let pair_before.line = opposite[0]
    let pair_before.col = opposite[1]
    call extend(pair_after, pair_before, 'keep')
    call s:substitute(
          \   pair_before,
          \   pair_after,
          \   '-',
          \   a:params.items,
          \   s:cascade_options_for_callback(options),
          \ )
  endif
endfunction "}}}


function! s:restrict_cursor(params) "{{{
  let before = a:params.before
  let after = a:params.after
  let pos = s:getpos()
  let end_col = before.col + strlen(after.text) - 1
  if a:params.class_name == 'v' || (after.text =~ '\W' && g:cycle_auto_visual)
    call cursor(before.line, before.col)
    normal! v
    call cursor(after.line, end_col)
  elseif after.line > before.line || end_col < pos.col
    call cursor(after.line, end_col)
  endif
endfunction "}}}


function! s:parse_callback_options(options) "{{{
  let options = a:options
  let callbacks = {
        \   'before_sub': [],
        \   'after_sub': [],
        \ }

  if get(options, s:OPTIONS.restrict_cursor)
    call add(callbacks.after_sub, function('s:restrict_cursor'))
  endif

  if get(options, s:OPTIONS.sub_tag)
    call add(callbacks.after_sub, function('s:sub_tag_pair'))
  endif

  if get(options, s:OPTIONS.sub_pair)
    call add(callbacks.after_sub, function('s:sub_pair'))
  endif

  return callbacks
endfunction "}}}


function! s:cascade_options_for_callback(options, ...) "{{{
  let extras = a:0 ? a:1 : {}
  let filtered =  filter(
        \   deepcopy(a:options),
        \   "index([s:OPTIONS.match_case, s:OPTIONS.hard_case], v:key) >= 0"
        \ )
  return extend(filtered, extras)
endfunction "}}}

" }}} Optional Callbacks


" Utils: {{{

function! s:escape_pattern(pattern) "{{{
  return escape(a:pattern, '.*~\[^$')
endfunction "}}}


function! s:escape_sub_expr(pattern) "{{{
  return escape(a:pattern, '~\&')
endfunction "}}}


" Selection UI {{{
" s:select_func
if (empty(g:cycle_select_ui) || g:cycle_select_ui == 'ui.select') && has('nvim') && luaeval('vim.ui.select')->type() == v:t_func
  function! s:LuaSelect(...) abort
    return luaeval('require("vim_cycle").select(unpack(_A))', a:000)
  endfunction
  let s:select_func = function('s:LuaSelect')
elseif (empty(g:cycle_select_ui) || g:cycle_select_ui == 'inputlist') && exists('*inputlist')
  let s:select_func = function('cycle#select#inputlist')
else
  let s:select_func = function('cycle#select#confirm')
endif
" }}}


" Conflict Selection UI {{{
" s:conflict_select_func
if (empty(g:cycle_conflict_ui) || g:cycle_conflict_ui == 'ui.select') && has('nvim') && luaeval('vim.ui.select')->type() == v:t_func
  function! s:LuaConflictSelect(...) abort
    return luaeval('require("vim_cycle").conflict_select(unpack(_A))', a:000)
  endfunction
  let s:conflict_select_func = function('s:LuaConflictSelect')
elseif (empty(g:cycle_conflict_ui) || g:cycle_conflict_ui == 'inputlist') && exists('*inputlist')
  let s:conflict_select_func = function('cycle#select#conflict_inputlist')
else
  let s:conflict_select_func = function('cycle#select#conflict_confirm')
endif
" }}}


function! s:build_match(ctext, group, item_idx) "{{{
  let item = a:group.items[a:item_idx]
  let ctext = deepcopy(a:ctext)
  let new_text = s:new_ctext('')

  let new_text.text = s:text_transform(
        \   ctext.text,
        \   item,
        \   a:group.options,
        \ )
  let new_text.line = ctext.line
  let new_text.col = ctext.col

  return {
        \   'group': a:group,
        \   'pairs': {
        \     'before': deepcopy(ctext),
        \     'after': deepcopy(new_text)
        \   },
        \ }
endfunction "}}}


function! s:text_transform(before, after, options) "{{{
  let text = a:after

  if type(get(a:options, s:OPTIONS.regex)) == type('')
    let text = matchstr(
          \   a:after,
          \   get(a:options, s:OPTIONS.regex),
          \ )
  endif

  if !get(a:options, s:OPTIONS.hard_case)
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


function! s:save_reg(name) "{{{
  let s:save_reg = [getreg(a:name), getregtype(a:name)]
endfunction "}}}


function! s:restore_reg(name) "{{{
  if exists('s:save_reg')
    call setreg(a:name, s:save_reg[0], s:save_reg[1])
  endif
endfunction "}}}


function! s:sid_prefix() "{{{
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction "}}}

" }}} Utils
