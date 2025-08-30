function! cycle#changer#dispatch(changer, func, ctx) abort "{{{
  if a:func == 'change'
    return s:dispatch_change(a:changer, a:ctx)
  endif
endfunction "}}}


function! s:dispatch_change(changer, ctx) " {{{
  let changer = a:changer
  let changer_type = type(changer)
  let ctext = get(a:ctx, 'ctext')
  let group = get(a:ctx, 'group')
  let index = get(a:ctx, 'index')
  let args = [ctext, group, index]

  if changer_type == type('')
    if index(['regex', 'year'], changer) >= 0
      let result = call('cycle#changer#' . changer . '#change', args)
      return result
    else
      call s:invalid_change_option(group)
      return ctext
    endif
  elseif changer_type == type({})
    let Fn = get(changer, 'change')
    if index([v:t_func, v:t_string], type(Fn)) >= 0
      let result = call(Fn, args)
      if type(result) != type({})
        echoerr printf('Cycle: invalid change result of group\n  ', string(group))
        return ctext
      endif
      return result
    endif
  endif

  call s:invalid_change_option(group)
  return ctext
endfunction " }}}


function! s:invalid_change_option(group) abort " {{{
  echoerr "Cycle: Invalid changer :change in group:\n  " . string(a:group)
endfunction " }}}
