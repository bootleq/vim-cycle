" Functions for 'ambi_pair' (ambiguous sub_pair member) group option.
"
" Currently the ambi_pair items have some assumptions:
" 1. can only contain 1 character
" 2. end_items (has `begin_with`) were searched BEFORE begin_items items

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
    let [result, pos] = Tester(a:text, a:options)
    if result != 0
      return result > 0
      break
    endif
  endfor

  return 0
endfunction " }}}


" Find the pair position
function! cycle#matcher#default#ambi_pair#find_pair_pos(text, options) abort " {{{
  for name in s:testers_names
    let Tester = s:testers[name]
    let [result, pos] = Tester(a:text, a:options)
    if result == 1
      return pos
      break
    endif
  endfor

  return [0, 0]
endfunction " }}}



" Testers {{{
"
" Each tester function:
" Params:
"   - text: string
"   - options: dict
" Returns:
"   [
"     valid: number,                    - 0: unknown / -1: invalid / valid
"     pos: [line: number, col:number]   - line, col of the found pair (could have value even when invalid)
"   ]


" 'vim_text_objs'
" Try builtin vi' series text objects, if col changed it has pairs recognized.
" This only searches in one line.
function! s:tester_vim_text_objs(text, options) abort " {{{
  let valid = 0
  let pair_pos = [0, 0]

  if index(s:vim_text_obj_chars, a:text) < 0
    return [valid, pair_pos]
  endif

  let saved_pos = getpos('.')
  let [line, col] = saved_pos[1:2]
  let gv_area = [getpos("'<"), getpos("'>")]

  try
    if mode() =~? '^v'
      execute "normal! \<Esc>"
    endif
    execute 'normal! vi' . a:text

    let new_col = col('.')
    if new_col != col
      if new_col > col
        let valid = !empty(get(a:options, 'end_with')) ? 1 : -1
        let pair_pos = [line, new_col + 1]
      else
        let valid = !empty(get(a:options, 'begin_with')) ? 1 : -1
        normal! oh
        let pair_pos = [line, col('.')]
      endif
    endif
  finally
    if mode() =~? '^v'
      execute "normal! \<Esc>"
    endif

    call setpos('.', saved_pos)
    call setpos("'<", gv_area[0])
    call setpos("'>", gv_area[1])
  endtry

  return [valid, pair_pos]
endfunction " }}}


" 'treesitter_range_edge'
" Check treesitter node range, pairs are on the both edges
function! s:tester_treesitter_range_edge(text, options) abort " {{{
  let valid = 0
  let pair_pos = [0, 0]

  if exists('*v:lua.vim.treesitter.get_node')
    let range = luaeval('require("vim_cycle.treesitter").get_node_range()')

    if !empty(range) && range[0] != range[1]
      let [range_begin, range_end] = range
      let pos = getpos('.')[1:2]

      if pos == range_begin
        let opposite = s:char_at_pos(range_end)
        if opposite == a:text
          let valid = !empty(get(a:options, 'end_with')) ? 1 : -1
          let pair_pos = range_end
        endif
      elseif pos == range_end
        let opposite = s:char_at_pos(range_begin)
        if opposite == a:text
          let valid = !empty(get(a:options, 'begin_with')) ? 1 : -1
          let pair_pos = range_begin
        endif
      endif
    endif
  endif

  return [valid, pair_pos]
endfunction " }}}


" 'line_search'
" Try search pairs in current line
" Simulate the logic of vi' text objects, while support other characters.
function! s:tester_line_search(text, options) abort " {{{
  let valid = 0
  let pair_pos = [0, 0]

  if index(s:vim_text_obj_chars, a:text) > -1
    return [valid, pair_pos]
  endif

  let line_text = getline('.')
  let [line, col] = getpos('.')[1:2]

  " Make the pattern to match sides, with care of escaping sequences.
  " For example a " will produce pattern "\%([^"\\]\|\\.\)*"
  " The \%() group first covers [^"\\] - the non-escaping,
  " then covers \\. - any escaped sequences like \" \n \x...
  let esc_text = cycle#util#escape_pattern(a:text)
  let pattern = call('printf', ['%s\%%([^%s\\]\|\\.\)*%s'] + repeat([esc_text], 3))

  let start_idx = 0

  while start_idx < len(line_text)
    let match_begin = match(line_text, pattern, start_idx)
    if match_begin == -1
      break
    endif
    let match_end = matchend(line_text, pattern, start_idx)

    if match_begin + 1 == col && s:char_at_pos([line, match_end]) == a:text
      let valid = !empty(get(a:options, 'end_with')) ? 1 : -1
      let pair_pos = [line, match_end]
    elseif match_end == col && s:char_at_pos([line, match_begin + 1]) == a:text
      let valid = !empty(get(a:options, 'begin_with')) ? 1 : -1
      let pair_pos = [line, match_begin + 1]
    endif

    let start_idx = match_end
  endwhile

  return [valid, pair_pos]
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
