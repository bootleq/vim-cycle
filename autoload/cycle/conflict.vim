let s:funcs = {}
let s:loaders = {}


" Select UI Loaders: {{{

function! s:loaders.telescope() abort " {{{
  if has('nvim') && exists(':Telescope') == 2
    function! s:TelescopeConflictSelect(...) abort
      return luaeval('require("vim_cycle.telescope").conflict_select(unpack(_A))', a:000)
    endfunction
    let s:funcs['telescope'] = function('s:TelescopeConflictSelect')
  else
    let s:funcs['telescope'] = 'unavailable'
  endif
endfunction " }}}


function! s:loaders.ui_select() abort " {{{
  if has('nvim') && luaeval('vim.ui.select')->type() == v:t_func
    function! s:LuaConflictSelect(...) abort
      return luaeval('require("vim_cycle").conflict_select(unpack(_A))', a:000)
    endfunction
    let s:funcs['ui.select'] = function('s:LuaConflictSelect')
  else
    let s:funcs['ui.select'] = 'unavailable'
  endif
endfunction " }}}


function! s:loaders.inputlist() abort " {{{
  if exists('*inputlist')
    let s:funcs['inputlist'] = function('cycle#select#conflict_inputlist')
  else
    let s:funcs['inputlist'] = 'unavailable'
  endif
endfunction " }}}


function! s:loaders.confirm() abort " {{{
  let s:funcs['confirm'] = function('cycle#select#conflict_confirm')
endfunction " }}}


function! s:loaders._test() abort " {{{
  let s:funcs['_test'] = function('cycle#test#conflict_ui')
endfunction " }}}

" }}}


function! cycle#conflict#ui(options, ctx) abort " {{{
  let pref = get(g:, 'cycle_conflict_ui', '')

  if has_key(s:funcs, pref) && type(s:funcs[pref]) == v:t_func
    return s:funcs[pref](a:options, a:ctx)
  endif

  let prefs = sort(['telescope', 'ui.select', 'inputlist', 'confirm', '_test'], {a, b -> b == pref})

  for key in prefs
    if !has_key(s:funcs, key)
      call s:loaders[tr(key, '.', '_')]()
    endif

    if type(s:funcs[key]) == v:t_func
      return s:funcs[key](a:options, a:ctx)
    endif
  endfor
endfunction " }}}
