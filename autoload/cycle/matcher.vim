function! cycle#matcher#dispatch(matcher, func, ctx) abort "{{{
  if a:func == 'test'
    return s:dispatch_test(a:matcher, a:ctx)
  endif
endfunction "}}}


function! s:dispatch_test(matcher, ctx) " {{{
  let matcher = a:matcher
  let matcher_type = type(matcher)
  let group = get(a:ctx, 'group')
  let class_name = get(a:ctx, 'class_name')
  let index = get(a:ctx, 'index')
  let ctext = get(a:ctx, 'ctext')
  let args = [deepcopy(group), class_name]

  if matcher_type == type('')
    if index(['regex', 'year'], matcher) >= 0
      let result = call('cycle#matcher#' . matcher . '#test', args)
      return result
    else
      call s:invalid_test_option(group)
      return [index, ctext]
    endif
  elseif matcher_type == type({})
    let Fn = get(matcher, 'test')
    if index([v:t_func, v:t_string], type(Fn)) >= 0
      let result = call(Fn, args)
      if type(result) != type([])
        echoerr printf('Cycle: invalid test result of group\n  ', string(group))
        return [0, ctext]
      endif
      return result
    endif
  endif

  call s:invalid_test_option(group)
  return [index, ctext]
endfunction " }}}


function! s:invalid_test_option(group) abort " {{{
  echoerr "Cycle: Invalid matcher :test in group:\n  " . string(a:group)
endfunction " }}}
