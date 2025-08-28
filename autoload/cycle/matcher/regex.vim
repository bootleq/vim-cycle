" Regex matcher
"
" Test group items by regex.
" Each item should be a pattern, and have match at cursor position.


" See `s:group_search()` in autoload/cycle.vim
function! cycle#matcher#regex#test(group, class_name) "{{{
  " Opt-out phased search by only performed in final phase ('' or v)
  if a:class_name != '' && a:class_name != 'v'
    return [-1, {}]
  endif

  for item in a:group.items
    let result = s:test_item(item, a:group)
    if type(result) == type([])
      return result
    endif
  endfor

  let not_found_ctext = cycle#text#new_ctext(a:class_name)
  return [-1, not_found_ctext]
endfunction "}}}


function! s:test_item(item, group) "{{{
  let saved_pos = getpos('.')
  let [line, col] = getpos('.')[1:2]
  let pattern = a:item
  let text = ''

  try
    call cycle#util#save_reg('a')

    " The clever search() detection method is inspired from AndrewRadev/switch.vim
    let match_start = search(pattern, 'bcW', line)
    if match_start > 0
      let match_start = col('.')

      silent normal! ma
      let match_end = search(pattern, 'cWe', line)
      if match_end > 0
        silent normal! v`a"ay
        let text = @a

        if match_start + strlen(text) <= col
          return
        endif
      endif
    endif
  finally
    call cycle#util#restore_reg('a')
    call setpos('.', saved_pos)
  endtry

  if len(text)
    let index = index(a:group.items, a:item)
    let ctext = {
          \   'text': text,
          \   'line': line,
          \   'col': match_start,
          \ }
    return [index, ctext]
  endif
endfunction "}}}
