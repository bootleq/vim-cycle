function! cycle#callback#sub_tag#sub(params) "{{{
  let before = a:params.before
  let after = a:params.after
  let options = a:params.options
  let timeout = 600
  let pattern_till_tag_end = '\_[^>]*\%(\/\)\@<!>'
  let ic_flag = get(options, 'match_case') ? '\C' : '\c'
  let pos = cycle#util#getpos()

  " To check if position is inside < and >, might across lines
  let pattern_is_within_tag = '\v\</?\m\%' . before.line . 'l\%' . before.col . 'c' . pattern_till_tag_end . '\C'

  if search(pattern_is_within_tag, 'n')
    let in_closing_tag = search('/\m\%' . before.line . 'l\%' . before.col . 'c\C', 'n')  " search if a '/' exists before position
    let opposite = searchpairpos(
          \   '<' . cycle#util#escape_pattern(before.text) . pattern_till_tag_end,
          \   '',
          \   '</' . cycle#util#escape_pattern(before.text) . '\s*>'
          \        . (in_closing_tag ? '\zs' : '') . ic_flag,
          \   'nW' . (in_closing_tag ? 'b' : ''),
          \   '',
          \   '',
          \   timeout,
          \ )

    if opposite != [0, 0]
      let ctext = {
            \   "text": before.text,
            \   "line": opposite[0],
            \   "col": opposite[1] + 1 + !in_closing_tag,
            \ }

      call cycle#substitute(ctext, after, [], [], {})

      if in_closing_tag && ctext.line == after.line
        let offset = strlen(after.text) - strlen(before.text)
        let before.col += offset
        let after.col += offset
      endif
    endif
  endif
endfunction "}}}
