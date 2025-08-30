function! cycle#matcher#dispatch(matcher, func, ctx) abort "{{{
  if a:func == 'test'
    return s:dispatch_test(a:matcher, a:ctx)
  endif
endfunction "}}}


function! s:dispatch_test(matcher, ctx) abort " {{{
  let matcher = a:matcher
  let group = get(a:ctx, 'group')
  let class_name = get(a:ctx, 'class_name')
  let index = get(a:ctx, 'index')
  let ctext = get(a:ctx, 'ctext')

  if type(matcher) == type('')
    if matcher == 'regex'
      let args = [deepcopy(group), class_name]
      let result = call('cycle#matcher#regex#test', args)
      return result
    elseif matcher == 'year'
      let args = [deepcopy(group), class_name]
      let result = call('cycle#matcher#' . matcher . '#test', args)
      return result
    else
      echohl WarningMsg | echo printf('Cycle: invalid matcher option %s.', matcher) | echohl None
      return [index, ctext]
    endif
  endif
endfunction " }}}
