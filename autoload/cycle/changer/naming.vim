" Naming Convention changer
"
" Transform text into target naming convention.

let s:transformers = {}
let s:builtin_names = [
      \   'snake_case',
      \   'camelCase',
      \   'camelCase_1',
      \   'kebab-case',
      \   'PascalCase',
      \   'PascalCase_1',
      \   'SCREAMING_SNAKE_CASE',
      \ ]

function! s:get_transformer(name) abort " {{{
  " From cache
  let Sub = get(s:transformers, a:name, 0)
  if type(Sub) == v:t_func
    return Sub
  endif

  " From config
  let cfg = get(g:cycle_naming_config, a:name, [])
  if !empty(cfg)
    let [pattern; rest] = cfg
    let item_cfg = len(rest) > 0 ? rest[0] : {}
    if has_key(item_cfg, 'sub')
      let Sub = get(item_cfg, 'sub', 0)

      if type(Sub) == type('')
        try
          let Sub = function(Sub)
        catch /^Vim\%((\a\+)\)\=:E700:/
          let Sub = 0
        endtry
      endif
    endif
  endif

  " From builtin
  if type(Sub) == type(0) && index(s:builtin_names, a:name) > -1
    let Sub = function('s:sub_to_' . tr(a:name, '-', '_'))
  endif

  if type(Sub) == v:t_func
    let s:transformers[a:name] = Sub
  endif
  return Sub
endfunction " }}}


" Internal transformers {{{

function! s:sub_to_snake_case(w) abort " {{{
  let words = s:split_words(a:w)
  let ret = join(words, '_')
  return ret
endfunction " }}}

function! s:sub_to_camelCase(w) abort " {{{
  let words = s:split_words(a:w)
  let head = words[0]
  let tail = map(words[1:], 'toupper(v:val[0]) . v:val[1:]')
  let ret = head . join(tail, '')
  return ret
endfunction " }}}

function! s:sub_to_camelCase_1(w) abort " {{{
  let words = s:split_words(a:w)
  let head = words[0]
  let tail = map(words[1:], 'toupper(v:val[0]) . v:val[1:]')
  call map(tail, { _, v -> v[0] =~# '\d' ? ('_' . v) : v })
  let ret = head . join(tail, '')
  return ret
endfunction " }}}

function! s:sub_to_kebab_case(w) abort " {{{
  let words = s:split_words(a:w)
  let ret = join(words, '-')
  return ret
endfunction " }}}

function! s:sub_to_PascalCase(w) abort " {{{
  let words = s:split_words(a:w)
  call map(words, { _, v -> toupper(v[0]) . v[1:] })
  let ret = join(words, '')
  return ret
endfunction " }}}

function! s:sub_to_PascalCase_1(w) abort " {{{
  let words = s:split_words(a:w)
  call map(words, { _, v -> toupper(v[0]) . v[1:] })
  call map(words, { _, v -> v[0] =~# '\d' ? ('_' . v) : v })
  let ret = join(words, '')
  return ret
endfunction " }}}

function! s:sub_to_SCREAMING_SNAKE_CASE(w) abort " {{{
  let words = s:split_words(a:w)
  call map(words, 'toupper(v:val)')
  let ret = join(words, '_')
  return ret
endfunction " }}}

" }}}


" Params:
"   - ctext:        Ctext
"   - group:        Group
"   - next_index:   number
" Returns:
"   Ctext - the changed text info (might keep old text if no valid result)
function! cycle#changer#naming#change(ctext, group, next_index) "{{{
  let new_text = s:change(a:ctext, a:group, a:next_index)
  if empty(new_text)
    return deepcopy(a:ctext) " invalid, return ctext unchanged
  endif

  let new_ctext = {
        \   'text': new_text,
        \   'line': a:ctext.line,
        \   'col': a:ctext.col,
        \ }
  return new_ctext
endfunction "}}}


" Params:
"   - ctext: Ctext  - matched text
"   - group: Group  - matched group
"   - index: number - index of matched item.
" Returns:
"   list<Match>
function! cycle#changer#naming#collect_selections(ctext, group, index) "{{{
  let matches = []

  for idx in range(len(a:group.items))
    if idx != a:index
      let changed = s:change(a:ctext, a:group, idx)
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


function! s:change(ctext, group, index) abort " {{{
  let new_item = a:group.items[a:index]
  let Sub = s:get_transformer(new_item)

  if type(Sub) == v:t_func
    let new_text = Sub(a:ctext.text)
  else
    echohl WarningMsg | echomsg printf("Cycle: invalid 'sub' in `naming` item '%s'", new_item) | echohl None
    let new_text = ''
  endif

  return new_text
endfunction " }}}


function! s:split_words(text) abort " {{{
  let text = a:text

  if text =~# '\u' && text =~# '\l'
    " split at 'Xxx*' while keep continuous 'XX'
    let text = substitute(text, '\v(\u@<!\u\U*)', '_\1', 'g')
  endif

  let text = tolower(text)
  let text = tr(text, '-', '_')
  let words = split(text, '_\+')
  return words
endfunction " }}}


" Mainly for test usage
function! s:reset_transformers() abort " {{{
  let s:transformers = {}
endfunction " }}}
