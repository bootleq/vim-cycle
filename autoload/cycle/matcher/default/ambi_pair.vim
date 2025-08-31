" ambi_pair (ambiguous sub_pair member)

let s:vim_text_obj_chars = ['"', "'", '`']

let s:testers_names = [
      \   'treesitter_range_edge',
      \   'vim_text_objs',
      \   'line_search',
      \ ]

let s:testers = {}


" Check if a ambi_pair (ambiguous sub_pair member) match is valid.
function! cycle#matcher#default#ambi_pair#test(text, options) abort " {{{
  for name in s:testers_names
    let Tester = s:testers[name]
    let result = Tester(a:text, a:options)
    if result != 0
      return result > 0
      break
    endif
  endfor

  return 0
endfunction " }}}



" Testers {{{
"
" Each tester function:
" Params:
"   - text: string
"   - options: dict
" Returns:
"   number
"        -1 - invalid
"         0 - unknown
"         2 - valid


" 'vim_text_objs'
" Try builtin vi' series text objects, if col changed it has pairs recognized.
" This only searches in one line.
function! s:tester_vim_text_objs(text, options) abort " {{{
  if index(s:vim_text_obj_chars, a:text) < 0
    return 0
  endif

  let saved_pos = getpos('.')
  let [line, col] = saved_pos[1:2]
  try
    " TODO: if start in v mode?
    execute 'normal! vi' . a:text

    let new_col = col('.')
    if new_col != col
      if new_col > col
        return !empty(get(a:options, 'end_with')) ? 1 : -1
      else
        return !empty(get(a:options, 'begin_with')) ? 1 : -1
      endif
    endif
  finally
    execute "normal! \<Esc>"
    call setpos('.', saved_pos)
  endtry

  return 0
endfunction " }}}


" 'treesitter_range_edge'
" Check treesitter node range, pairs are on the both edges
function! s:tester_treesitter_range_edge(text, options) abort " {{{
  if exists('*v:lua.vim.treesitter.get_node')
    let range = luaeval('require("vim_cycle.treesitter").get_node_range()')

    if !empty(range) && range[0] != range[1]
      let [range_begin, range_end] = range
      let pos = getpos('.')[1:2]

      if pos == range_begin
        let opposite = s:char_at_pos(range_end)
        if opposite == a:text
          return !empty(get(a:options, 'end_with')) ? 1 : -1
        endif
      elseif pos == range_end
        let opposite = s:char_at_pos(range_begin)
        if opposite == a:text
          return !empty(get(a:options, 'begin_with')) ? 1 : -1
        endif
      endif
    endif
  endif

  return 0
endfunction " }}}


" 'line_search'
" Try search paris in current line
" Simulate the logic of vi' text objects, while support other characters.
function! s:tester_line_search(text, options) abort " {{{
  if index(s:vim_text_obj_chars, a:text) > -1
    return 0
  endif

  let line_text = getline('.')
  let [line, col] = getpos('.')[1:2]
  let pattern = printf('%s\%%([^%s\\]\|\\.\)*%s', a:text, a:text, a:text)
  let start_idx = 0

  while start_idx < len(line_text)
    let match_begin = match(line_text, pattern, start_idx)
    if match_begin == -1
      break
    endif
    let match_end = matchend(line_text, pattern, start_idx)

    if match_begin + 1 == col && s:char_at_pos([line, match_end]) == a:text
      return !empty(get(a:options, 'end_with')) ? 1 : -1
    elseif match_end == col && s:char_at_pos([line, match_begin + 1]) == a:text
      return !empty(get(a:options, 'begin_with')) ? 1 : -1
    endif

    let start_idx = match_end
  endwhile

  return 0
endfunction " }}}


function! s:char_at_pos(pos) abort " {{{
  let [line, col] = a:pos
  let char = strpart(getline(line), col - 1, 1, v:true)
  return char
endfunction " }}}

" Setup testers
for name in s:testers_names
  let fullname = 's:tester_' . name
  let s:testers[name] = function(fullname)
endfor
unlet name


" }}}
