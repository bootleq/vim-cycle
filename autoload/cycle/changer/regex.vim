" Regex changer
"
" Change group item by regex.
" Requires a regex:`to` option to define the {sub} list for every group
" item. For exampe group items: ['x(\d)x', 'o(\d)o']  requires settings like
"                           to: ['o\1o',   'x\1x']
"               to change item:   x4x   =>  o4o


" Params:
"   - ctext: Ctext        - matched text
"   - group: Group        - matched group
"   - next_index: number  - index of next item of current match. While we will
"                           go back 1 step because the actual "to" is defined
"                           there without 'cycle to next'
" Returns:
"   Ctext - the changed text info
function! cycle#changer#regex#change(ctext, group, next_index) "{{{
  " Back 1 step because regex item is actually defined at the same position
  let index = a:next_index == 0 ? len(a:group.items) - 1 : a:next_index - 1

  let [replacers, sub_patterns] = s:parse_options(a:group)

  return s:change(a:ctext, a:group, index, replacers, sub_patterns)
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
function! cycle#changer#regex#collect_selections(ctext, group, index) "{{{
  let matches = []
  let ctext = a:ctext
  let last_text = {}
  let [replacers, sub_patterns] = s:parse_options(a:group)

  " For Nth match, the original form (to be skipped) is the previous item
  let idx_to_skip = a:index == 0 ? len(a:group.items) - 1 : a:index - 1

  " Start from matched item, wrap when reaching end (because every change is
  " base on previous changed result)
  let seq = range(len(a:group.items))
  let skip_idx = index(seq, idx_to_skip)
  let work_seq = extend(slice(seq, skip_idx + 1), slice(seq, 0, skip_idx))

  for idx in work_seq
    let iter_text = empty(last_text) ? ctext : last_text
    let changed = s:change(iter_text, a:group, idx, replacers, sub_patterns)
    let m = {
          \   'group': a:group,
          \   'pairs': {
          \     'before': ctext,
          \     'after': changed,
          \   },
          \   'index': idx,
          \ }
    let last_text = deepcopy(changed)
    call add(matches, m)
  endfor

  return matches
endfunction " }}}


" Params:
"   - ctext:        Ctext
"   - group:        Group
"   - index:        number       - index of current match
"   - replacers:    list<string>
"   - sub_patterns: list<string>
" Returns:
"   Ctext - the changed text info
function! s:change(ctext, group, index, replacers, sub_patterns) abort " {{{
  let options = a:group.options
  let col = a:ctext.col
  let index = a:index

  let replacer = a:replacers[index]

  if empty(a:sub_patterns)
    let pattern = a:group.items[index]
  else
    let pattern = a:sub_patterns[index]
  endif

  if type(replacer) == type('')
    let Sub = replacer
  elseif type(replacer) == type({})
    let Sub = function('s:dict_replacer_sub', [replacer])
  endif

  let new_text = substitute(a:ctext.text, pattern, Sub, '')

  let new_text = {
        \   'text': new_text,
        \   'line': a:ctext.line,
        \   'col': col,
        \ }
  return new_text
endfunction " }}}


function! s:parse_options(group) abort " {{{
  let opts = get(a:group.options, 'regex', {})
  let replacers = get(opts, 'to', [])
  let subp = get(opts, 'subp', [])
  if empty(replacers)
    echoerr "Cycle: missing regex 'to' in group:\n  " . string(a:group)
  endif
  return [replacers, subp]
endfunction " }}}


" Limited support of switch.vim nested dict definition.
" The dict key is {pattern} and value is {sub}.
" Replace given text (the whole match) with each pattern/sub pair.
function! s:dict_replacer_sub(cfg, ...) abort " {{{
  let string = a:1[0]

  for [pattern, sub] in items(a:cfg)
    let string = substitute(string, pattern, sub, 'g')
  endfor

  return string
endfunction " }}}
