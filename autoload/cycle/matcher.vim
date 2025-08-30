function! cycle#matcher#dispatch(matcher, func, ctx) abort "{{{
  if a:func == 'test'
    return s:dispatch_test(a:matcher, a:ctx)
  endif
endfunction "}}}


function! s:dispatch_test(matcher, ctx) " {{{
  let Matcher = a:matcher
  let matcher_type = type(Matcher)
  let group = get(a:ctx, 'group')
  let class_name = get(a:ctx, 'class_name')
  let index = get(a:ctx, 'index')
  let ctext = get(a:ctx, 'ctext')
  let args = [deepcopy(group), class_name]

  if matcher_type == type('')
    if index(['regex', 'year'], Matcher) >= 0
      let result = call('cycle#matcher#' . Matcher . '#test', args)
      return result
    elseif Matcher[0] == '*'
      let result = call(Matcher[1:], args)
      if type(result) != type([])
        echoerr printf('Cycle: invalid matcher result of "%s"', Matcher)
        return [0, ctext]
      endif
      return result
    else
      echohl WarningMsg | echo printf('Cycle: invalid matcher option "%s".', Matcher) | echohl None
      return [index, ctext]
    endif
  elseif matcher_type == v:t_func
    let result = call(Matcher, args)
    if type(result) != type([])
      echoerr printf('Cycle: invalid matcher result of "%s"', Matcher)
      return [0, ctext]
    endif
    return result
  else
    echoerr printf("Cycle: invalid matcher: %s", string(Matcher))
  endif
endfunction " }}}
