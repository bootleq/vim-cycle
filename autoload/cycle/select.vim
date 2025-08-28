let s:funcs = {}
let s:loaders = {}


" Select UI Loaders: {{{

function! s:loaders.ui_select() abort " {{{
  if has('nvim') && luaeval('vim.ui.select')->type() == v:t_func
    function! s:LuaSelect(...) abort
      return luaeval('require("vim_cycle").select(unpack(_A))', a:000)
    endfunction
    let s:funcs['ui.select'] = function('s:LuaSelect')
  else
    let s:funcs['ui.select'] = 'unavailable'
  endif
endfunction " }}}


function! s:loaders.inputlist() abort " {{{
  if exists('*inputlist')
    let s:funcs['inputlist'] = function('cycle#select#inputlist')
  else
    let s:funcs['inputlist'] = 'unavailable'
  endif
endfunction " }}}


function! s:loaders.confirm() abort " {{{
  let s:funcs['confirm'] = function('cycle#select#confirm')
endfunction " }}}


function! s:loaders._test() abort " {{{
  let s:funcs['_test'] = function('cycle#test#select_ui')
endfunction " }}}

" }}}


function! cycle#select#ui(options, ctx) abort " {{{
  let pref = get(g:, 'cycle_select_ui', '')

  if has_key(s:funcs, pref) && type(s:funcs[pref]) == v:t_func
    return s:funcs[pref](a:options, a:ctx)
  endif

  let prefs = sort(['ui.select', 'inputlist', 'confirm', '_test'], {a, b -> b == pref})

  for key in prefs
    if !has_key(s:funcs, key)
      call s:loaders[tr(key, '.', '_')]()
    endif

    if type(s:funcs[key]) == v:t_func
      return s:funcs[key](a:options, a:ctx)
    endif
  endfor
endfunction " }}}


" UI implementations: {{{

function! s:open_inputlist(options) "{{{
  let index = 0
  let candidates = []
  let max_length = max(map(copy(a:options), 'strlen(v:val.text)'))
  for option in a:options
    let group = get(option, 'group_name', '')
    let line = printf(
          \   '%2S => %-*S %S',
          \   index + 1,
          \   max_length,
          \   option.text,
          \   len(group) ? printf(' (%s)', group) : ''
          \ )
    call add(candidates, line)
    let index += 1
  endfor
  let list = ["Cycle to:"]
  call extend(list, candidates)
  " Example output:
  "
  "Cycle to:
  " 1 => bar    (foobar)
  " 2 => poooo  (pupu)
  " 3 => gOO
  let choice = inputlist(list)
  if choice > index
    let choice = -1
  endif

  return choice
endfunction "}}}


function! s:open_confirm(options) "{{{
  let index = 0
  let captions = []
  let candidates = []
  let max_length = max(map(copy(a:options), 'strlen(v:val.text)'))
  for option in a:options
    let caption = nr2char(char2nr('A') + index)
    let group = get(option, 'group_name', '')
    let line = printf(
          \   ' %2S) => %-*S %S',
          \   caption,
          \   max_length,
          \   option.text,
          \   len(group) ? printf(' (%s)', group) : ''
          \ )
    call add(candidates, line)
    call add(captions, '&' . caption)
    let index += 1
  endfor
  " Example output:
  "
  "Cycle to:
  "
  "  A) => bar    (foobar)
  "  B) => poooo  (pupu)
  "  C) => gOO
  "
  "(A), (B), (C):
  redraw
  let choice = confirm("Cycle to:\n\n" . join(candidates, "\n") . "\n", join(captions, "\n"), 0)
  return choice
endfunction "}}}

" }}}


" Implementation dispatchers, including conflict UI: {{{

function! cycle#select#inputlist(options, ctx) "{{{
  let choice = s:open_inputlist(a:options)
  call call(a:ctx.sid .. 'on_select', [choice, a:ctx])
endfunction "}}}


function! cycle#select#conflict_inputlist(options, ctx) "{{{
  let choice = s:open_inputlist(a:options)
  call call(a:ctx.sid .. 'on_resolve_conflict', [choice, a:ctx])
endfunction "}}}


function! cycle#select#confirm(options, ctx) "{{{
  let choice = s:open_confirm(a:options)
  call call(a:ctx.sid .. 'on_select', [choice, a:ctx])
endfunction "}}}


function! cycle#select#conflict_confirm(options, ctx) "{{{
  let choice = s:open_confirm(a:options)
  call call(a:ctx.sid .. 'on_resolve_conflict', [choice, a:ctx])
endfunction "}}}

" }}}
