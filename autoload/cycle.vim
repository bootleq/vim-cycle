" Constants: {{{

" Group options:
"   name
"   match_case
"   match_word
"   hard_case
"   restrict_cursor
"   sub_tag
"   sub_pair
"   sub_pairs
"   ambi_pair
"   end_with
"   begin_with
"   matcher
"   changer
"   regex
"   year
"   cond
"
" Sub options for 'regex':
"   to
"   subp

let s:tick = 0

" }}} Constants


" Types {{{
"
" Group: {
"   items: list
"   options: dict
" }
"
"
" TextClass: '.' | '' | 'w' | 'v' | '' | '-'
" . : current cursor char / cchar, might be multibyte (is still 1 character)
" w : current cursor word / cword
" v : visual selection
"   : empty, no above classes matched, can try search in expanded range
" - : dummy, noop
"
"
" Ctext: {
"  text: string
"  line: number
"  col: number
" }
"
"
" Match: {
"   group: Group,
"   pairs: {
"     before: Ctext   - the matched text before change
"     after: Ctext    - expected changed result
"   },
"   index: number     - the index of matched item (before) in the group
" }
"
" }}}


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
          \   "group_name": get(match.group.options, 'name', ''),
          \   "text":       match.pairs.after.text
          \ })
  endfor

  let ctx = {
        \   "class_name": a:class_name,
        \   "matches":    matches,
        \   "sid":        s:sid_prefix(),
        \ }
  return cycle#select#ui(options, ctx)
endfunction "}}}


function! cycle#search(class_name, ...) "{{{
  let s:tick += 1

  let options = a:0 ? a:1 : {}
  let groups = deepcopy(s:groups())
  let direction = get(options, 'direction', 1)
  let l:count = get(options, 'count', 1)
  let matches = []
  let cword = cycle#text#new_cword()
  let cchar = cycle#text#new_cchar()

  " Phased search
  " - for word            : word => char => line  ['w', '']
  " - for multibyte word  : char => word => line  ['.', 'w', '']
  " - for visual selected : visual                ['v']
  if a:class_name == 'w'
    if len(cchar.text) > 1 " multibyte
      let phases = ['.', 'w', '']
    else
      let phases = ['w', '']
    endif
  elseif a:class_name == 'v'
    let phases = ['v']
  else
    let phases = []
  endif

  for phase in phases
    if len(matches)
      if g:cycle_max_conflict <= 1 || len(matches) > g:cycle_max_conflict
        break
      endif
    endif

    let phase_matches = s:phased_search(phase, groups, direction, l:count)

    if !empty(phase_matches)
      call extend(matches, phase_matches)
    endif
  endfor

  return matches
endfunction "}}}


function! s:phased_search(class_name, groups, direction, count) "{{{
  let matches = []
  let search_ctx = {}

  for group in a:groups
    if get(group, '_phase_matched', 0)
      continue
    endif

    if has_key(group.options, 'cond')
      if type(group.options['cond']) == v:t_func
        if !group.options['cond'](group, s:tick)
          continue
        endif
      else
        echoerr "Cycle: Invalid condition (cond) in group:\n  " . string(group)
        return
      endif
    endif

    if len(matches) && g:cycle_max_conflict <= 1 && a:count != '*'
      break
    endif

    let [index, ctext] = s:group_search(group, a:class_name, search_ctx)
    if index >= 0
      if a:count == '*'
        " Grab all group items for CycleSelect
        call extend(matches, s:build_matches(ctext, group, index))
      else
        let new_index = (index + a:direction * a:count) % len(group.items)
        call add(matches, s:build_match(ctext, group, new_index))

        if type(get(group.options, 'ambi_pair')) == type([])
          if index(group.options['ambi_pair'], ctext.text) > -1
            let founds = get(search_ctx, 'ambi_pair_found', [])
            call add(founds, ctext.text)
          endif
        endif
      endif

      let group._phase_matched = 1
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
        \   'context': {},
        \ }

  for Fn in callbacks.before_sub
    call call(Fn, [callback_params])
  endfor

  call setline(
        \   a:before.line,
        \   substitute(
        \     getline(a:before.line),
        \     '\%' . a:before.col . 'c' . cycle#util#escape_pattern(a:before.text) . '\c',
        \     cycle#util#escape_sub_expr(a:after.text),
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
          \   "group_name": get(match.group.options, 'name', ''),
          \   "text":       match.pairs.after.text
          \ })
  endfor

  return cycle#conflict#ui(options, a:ctx)
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
  if m.pairs.before == m.pairs.after
    echohl WarningMsg | echo "Cycle to nothing, aborted." | echohl None
    return
  endif

  call s:substitute(
        \   m.pairs.before,
        \   m.pairs.after,
        \   a:ctx.class_name,
        \   m.group.items,
        \   extend(deepcopy(m.group.options), {'restrict_cursor': 1}),
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
  let pos = cycle#util#getpos()
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


" Test if a group has item match in given text class.
" Params:
"   - group:      Group
"   - class_name: TextClass
"   - search_ctx: dict - arbitrary search info shared during group_search
" Returns:
"   list<matched_col: number, ctext: Ctext>
function! s:group_search(group, class_name, search_ctx) "{{{
  let matcher = get(a:group.options, 'matcher', 0)

  if type(matcher) != type(0)
    let ctx = {'group': a:group, 'class_name': a:class_name}
    return cycle#matcher#dispatch(matcher, 'test', ctx)
  endif

  let result = call('cycle#matcher#default#test', [a:group, a:class_name, a:search_ctx])
  return result
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

  if has_key(options, 'sub_pairs')
    let separator = type(options.sub_pairs) == type(0) ? ':' : options.sub_pairs
    let [begin_items, end_items, ambi_items] = [[], [], []]
    for item in items
      let [begin_item, end_item] = split(item, separator)
      if begin_item == end_item
        if len(begin_item) == 1
          call add(ambi_items, begin_item)
        else
          echohl WarningMsg | echomsg "Cycle: `sub_pairs` can't handle pairs with the same text" | echohl None
        endif
      endif
      call add(begin_items, begin_item)
      call add(end_items, end_item)
    endfor
    unlet options.sub_pairs
    let options.sub_pair = 1
    if !empty(ambi_items)
      let options.ambi_pair = ambi_items
    endif
    " Note that the `end_with` must go before `begin_with`, `ambi_pair` relies
    " on this order to make orphaned behave as the begin part.
    call s:add_group(a:scope, [begin_items, extend(deepcopy(options), {'end_with': end_items})])
    call s:add_group(a:scope, [end_items, extend(deepcopy(options), {'begin_with': begin_items})])
    return
  endif

  if has_key(options, 'year')
    unlet options['year']
    call extend(options, {'matcher': 'year', 'changer': 'year'}, 'keep')
  endif

  if has_key(options, 'regex')
    " Expand from:  #{regex: [foo, bar]}
    "          to:  #{matcher: 'regex', changer: 'regex', regex: {'to: [foo, bar]'}}
    " Expand from:  #{regex: #{to: [foo, bar], subp: [fo, ba]}}
    "          to:  #{matcher: 'regex', changer: 'regex', regex: {'to: [foo, bar]', subp: [fo, ba]}}
    let regex_opts = get(options, 'regex', {})
    if type(regex_opts) == type([])
      let to = regex_opts
      let regex_opts = {'to': to}
    endif
    call extend(options, {'matcher': 'regex', 'changer': 'regex'}, 'keep')
    call extend(options, {'regex': regex_opts}, 'force')
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


" Optional Callbacks: {{{

function! s:sub_tag_pair(params) "{{{
  let before = a:params.before
  let after = a:params.after
  let options = a:params.options
  let timeout = 600
  let pattern_till_tag_end = '\_[^>]*>'
  let ic_flag = get(options, 'match_case') ? '\C' : '\c'
  let pos = cycle#util#getpos()

  " To check if position is inside < and >, might across lines
  let pattern_is_within_tag = '\v\</?\m\%' . before.line . 'l\%' . before.col . 'c' . pattern_till_tag_end . '\C'

  if search(pattern_is_within_tag, 'n')
    let in_closing_tag = search('/\m\%' . before.line . 'l\%' . before.col . 'c\C', 'n')  " search if a '/' exists before position
    let opposite = searchpairpos(
          \   '<' . cycle#util#escape_pattern(before.text) . pattern_till_tag_end,
          \   '',
          \   '</' . cycle#util#escape_pattern(before.text) . '\s*>'
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

      call s:substitute(
            \   ctext,
            \   after,
            \   '-',
            \   [],
            \   {},
            \ )

      if in_closing_tag && ctext.line == after.line
        let offset = strlen(after.text) - strlen(before.text)
        let before.col += offset
        let after.col += offset
      endif
    endif
  endif
endfunction "}}}


" Find target pair for "sub_pair".
" For example when sub {{ foo }}  ->  (( foo ))
"           cursor at: ^
" We have:
" - trigger: {{   ->   ((
" - pair:    }}   ->   ))
" - pair_at: end
function! s:find_pair(params) abort " {{{
  let trigger_before = a:params.before
  let trigger_after = a:params.after
  let options = a:params.options
  let sub_offset = 0
  let timeout = 600
  let ic_flag = get(options, 'match_case') ? '\C' : '\c'

  if type(get(options, 'end_with')) == type([])
    let trigger_at_begin = 1
  elseif type(get(options, 'begin_with')) == type([])
    let trigger_at_begin = 0
  else
    echohl WarningMsg | echo printf('Incomplete sub_pair for %s, missing "begin" or "end" with.', trigger_before.text) | echohl None
    return
  endif

  let pair_at = trigger_at_begin ? 'end' : 'begin'

  let pair_before = deepcopy(trigger_before)
  let pair_before.text = get(
        \   options[pair_at . '_with'],
        \   index(a:params.items, trigger_before.text, 0, ic_flag ==# '\c'),
        \ )

  let pair_after = {}
  let pair_after.text = get(
        \   options[pair_at . '_with'],
        \   index(a:params.items, trigger_after.text, 0, ic_flag ==# '\c'),
        \ )

  let pair_pos = searchpairpos(
        \   cycle#util#escape_pattern(trigger_at_begin ? trigger_before.text : pair_before.text),
        \   '',
        \   cycle#util#escape_pattern(trigger_at_begin ? pair_before.text : trigger_before.text)
        \        . (trigger_at_begin ? '' : '\zs') . ic_flag,
        \   'nW' . (trigger_at_begin ? '' : 'b'),
        \   '',
        \   '',
        \   timeout,
        \ )

  if pair_pos == [0, 0]
    echohl WarningMsg | echo printf("Can't find opposite %s for sub_pair.", pair_before.text) | echohl None
  else
    let pair_before.line = pair_pos[0]
    let pair_before.col = pair_pos[1]
    call extend(pair_after, pair_before, 'keep')

    if trigger_before.line == pair_before.line && trigger_before.line == pair_after.line
      if trigger_at_begin
        let sub_offset =
              \ trigger_after.col + len(trigger_after.text) -
              \ (trigger_before.col + len(trigger_before.text))
      else
        let sub_offset =
              \ pair_after.col + len(pair_after.text) -
              \ (pair_before.col + len(pair_before.text))
      endif
    endif

    let ctx = {
          \   'pair_before': pair_before,
          \   'pair_after': pair_after,
          \   'pair_at': pair_at,
          \   'sub_offset': sub_offset,
          \ }
    call extend(a:params.context, ctx)
  endif
endfunction " }}}


function! s:sub_pair(params) "{{{
  let ctx = get(a:params, 'context', {})
  let pair_before = get(ctx, 'pair_before', {})
  let pair_after = get(ctx, 'pair_after', {})
  let pair_at = get(ctx, 'pair_at', '')
  let sub_offset = get(ctx, 'sub_offset', 0)

  if empty(pair_before) || empty(pair_after) || empty(pair_at)
    return
  endif

  let before = a:params.before
  let after = a:params.after

  if sub_offset
    if pair_at == 'end'
      let pair_before.col += sub_offset
      let pair_after.col += sub_offset
    else
      let before.col += sub_offset
      let after.col += sub_offset
    endif
  endif

  call s:substitute(
        \   pair_before,
        \   pair_after,
        \   '-',
        \   a:params.items,
        \   {},
        \ )

  if sub_offset
    let a:params.context.sub_offset = 0
  endif
endfunction "}}}


function! s:restrict_cursor(params) "{{{
  let before = a:params.before
  let after = a:params.after
  let pos = cycle#util#getpos()
  let end_col = before.col + strlen(after.text) - 1

  if a:params.class_name == 'v' || (after.text =~ '\W' && g:cycle_auto_visual)
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


function! s:parse_callback_options(options) "{{{
  let options = a:options
  let callbacks = {
        \   'before_sub': [],
        \   'after_sub': [],
        \ }

  if get(options, 'sub_tag')
    call add(callbacks.after_sub, function('s:sub_tag_pair'))
  endif

  if get(options, 'sub_pair')
    call add(callbacks.before_sub, function('s:find_pair'))
    call add(callbacks.after_sub, function('s:sub_pair'))
  endif

  if get(options, 'restrict_cursor')
    call add(callbacks.after_sub, function('s:restrict_cursor'))
  endif

  return callbacks
endfunction "}}}

" }}} Optional Callbacks


" Utils: {{{

" Build a Match by matched group item, take responsibility to transform ctext
" by group definition, and make a shaped result structure.
"
" Params:
"   - ctext: Ctext
"   - group: Group
"   - item_idx: number
" Returns:
"   Match
function! s:build_match(ctext, group, item_idx) "{{{
  let ctext = deepcopy(a:ctext)
  let new_text = cycle#text#new_ctext('')
  let changer = get(a:group.options, 'changer', 0)

  if type(changer) != type(0)
    let ctx = {'ctext': deepcopy(ctext), 'group': deepcopy(a:group), 'index': a:item_idx}
    let changed_text = cycle#changer#dispatch(changer, 'change', ctx)
    call extend(new_text, changed_text, 'force')
  else
    let changed_text = call('cycle#changer#default#change', [ctext, a:group, a:item_idx])
    call extend(new_text, changed_text, 'force')
  endif

  return {
        \   'group': a:group,
        \   'pairs': {
        \     'before': deepcopy(ctext),
        \     'after': deepcopy(new_text)
        \   },
        \   'index': a:item_idx
        \ }
endfunction "}}}


" Build a list of Match by matched group item.
" Used to collect expected changed results of every item except of the matched one.
"
" Params:
"   - ctext: Ctext
"   - group: Group
"   - item_idx: number
" Returns:
"   list<Match>
function! s:build_matches(ctext, group, item_idx) "{{{
  let matches = []
  let changer = get(a:group.options, 'changer', 0)

  if type(changer) != type(0)
    let ctx = {'ctext': deepcopy(a:ctext), 'group': deepcopy(a:group), 'index': a:item_idx}
    let matches = cycle#changer#dispatch(changer, 'collect_selections', ctx)
  else
    let matches = call('cycle#changer#default#collect_selections', [deepcopy(a:ctext), a:group, a:item_idx])
  endif

  return matches
endfunction "}}}


function! s:sid_prefix() "{{{
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction "}}}

" }}} Utils
