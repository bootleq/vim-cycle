" Regex matcher
"
" Test group items by regex.
" Each item should be a pattern, and have match at cursor position.


" See `s:group_search()` in autoload/cycle.vim
function! cycle#matcher#regex#test(group, class_name) "{{{
  " Opt-out phased search by only performed in final phase ('' or v)
  if a:class_name != '' && a:class_name != 'v'
    return s:not_found(a:class_name)
  endif

  for item in a:group.items
    let result = s:test_item(item, a:group)
    if type(result) == type([])
      return result
    endif
  endfor

  return s:not_found(a:class_name)
endfunction "}}}


" Returns:
"   list<
"     line: number    - matched line
"     col: number     - matched col
"     text: string    - matched text
"   >
function! cycle#matcher#regex#test_pattern(pattern) "{{{
  let saved_pos = getpos('.')
  let [line, col] = getpos('.')[1:2]
  let pattern = a:pattern
  let text = ''
  let not_found = [0, -1, '']

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
          return not_found
        endif
      endif
    endif
  finally
    call cycle#util#restore_reg('a')
    call setpos('.', saved_pos)
  endtry

  if match_start
    return [line, match_start, text]
  endif

  return not_found
endfunction "}}}


" Returns:
"   list<matched_col: number, ctext: Ctext>
function! s:test_item(item, group) "{{{
  let [line, col, text] = cycle#matcher#regex#test_pattern(a:item)

  if len(text)
    let index = index(a:group.items, a:item)
    let ctext = {
          \   'text': text,
          \   'line': line,
          \   'col': col,
          \ }
    return [index, ctext]
  endif
endfunction "}}}


function! s:not_found(class_name) abort " {{{
  let not_found_ctext = cycle#text#new_ctext(a:class_name)
  return [-1, not_found_ctext]
endfunction " }}}
