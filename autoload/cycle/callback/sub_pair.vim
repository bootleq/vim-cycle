" Callback Params:
"
" params: {
"   before:     Ctext
"   after:      Ctext
"   class_name: TextClass
"   items:      list<string>
"   options:    dict
"   context:    dict          - mutable data payload shared around callbacks
" }


" Find target pair for "sub_pair".
" For example when sub {{ foo }}  ->  (( foo ))
"           cursor at: ^
" We have:
" - trigger: {{   ->   ((
" - pair:    }}   ->   ))
" - pair_at: end
"
" Found pair will be added to 'context' with:
" {
"   pair_before:  Ctext
"   pair_after:   Ctext
"   pair_at:      'begin' | 'end'   - the side of pair_after
"   sub_offset:   number            - expected col offset after substitute
" }
function! cycle#callback#sub_pair#find(params) abort " {{{
  let trigger_before = a:params.before
  let trigger_after = a:params.after
  let options = a:params.options
  let sub_offset = 0
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

  let ambi_pair = get(options, 'ambi_pair', [])
  if index(ambi_pair, trigger_before.text) > -1
    " TODO: find by other methods
    " let pair_pos =
  else
    let pair_pos = s:find_by_searchpairpos(trigger_before, pair_before, trigger_at_begin, options)
  endif

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


function! cycle#callback#sub_pair#sub(params) "{{{
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

  call cycle#substitute(
        \   pair_before,
        \   pair_after,
        \   [],
        \   a:params.items,
        \   {},
        \ )

  if sub_offset
    let a:params.context.sub_offset = 0
  endif
endfunction "}}}


function! s:find_by_searchpairpos(trigger_before, pair_before, trigger_at_begin, options) abort " {{{
  let ic_flag = get(a:options, 'match_case') ? '\C' : '\c'
  let timeout = 600

  let pair_pos = searchpairpos(
        \   cycle#util#escape_pattern(a:trigger_at_begin ? a:trigger_before.text : a:pair_before.text),
        \   '',
        \   cycle#util#escape_pattern(a:trigger_at_begin ? a:pair_before.text : a:trigger_before.text)
        \        . (a:trigger_at_begin ? '' : '\zs') . ic_flag,
        \   'nW' . (a:trigger_at_begin ? '' : 'b'),
        \   '',
        \   '',
        \   timeout,
        \ )

  return pair_pos
endfunction " }}}
