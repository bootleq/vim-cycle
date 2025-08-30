function! cycle#changer#dispatch(changer, func, ctx) abort "{{{
  if a:func == 'change'
    return s:dispatch_change(a:changer, a:ctx)
  endif
endfunction "}}}


function! s:dispatch_change(changer, ctx) " {{{
  let Changer = a:changer
  let changer_type = type(Changer)
  let ctext = get(a:ctx, 'ctext')
  let group = get(a:ctx, 'group')
  let index = get(a:ctx, 'index')
  let args = [ctext, group, index]

  if changer_type == type('')
    if index(['regex', 'year'], Changer) >= 0
      let result = call('cycle#changer#' . Changer . '#change', args)
      return result
    elseif Changer[0] == '*'
      let result = call(Changer[1:], args)
      if type(result) != type({})
        echoerr printf('Cycle: invalid changer result of "%s"', Changer)
        return ctext
      endif
      return result
    else
      echohl WarningMsg | echo printf('Cycle: invalid changer option "%s".', Changer) | echohl None
    endif
  elseif changer_type == v:t_func
    let result = call(Changer, args)
    if type(result) != type({})
      echoerr printf('Cycle: invalid changer result of "%s"', Changer)
      return ctext
    endif
    return result
  else
    echoerr "Cycle: Invalid changer in group:\n  " . string(group)
  endif
endfunction " }}}
