" Naming Convention matcher
"
" Each group item is a "name" of a naming convention. They will be converted
" to regex patterns for search.

" Can use a config dictionary to adjust certain behavior.
" Dictionary key is the convention name, and value is a list with:
" [
"   pattern: string   - to test if a word matched. Don't add \< \>, let phased search handle it.
"   options?: dict    - allow further fine tune. (see below)
" ]
" The `options` dict can have:
" {
"   sub:string   - {sub} expr for internal substitute(). If absent, defaults
"                  applied (defined in 'naming' changer).
" }
if !exists('g:cycle_naming_config')
  let g:cycle_naming_config = {
        \   'snake_case':           ['\v\l%(\l|\d)*%(_%(\l|\d)+)+'],
        \   'camelCase':            ['\v\l%(\l|\d)*%(\u%(\l|\d)*)+'],
        \   'camelCase_1':          ['\v\l%(\l|\d)*%(%(\u|_\d)%(\l|\d)*)+'],
        \   'kebab-case':           ['\v%(\l|\d)+%(-%(\l|\d)+)+'],
        \   'PascalCase':           ['\v%(\u+%(\l|\d)+)%(%(\u|\d)+%(\l|\d)+)*'],
        \   'PascalCase_1':         ['\v%(\u+%(\l|\d)+)%(%(\u|_\d)+%(\l|\d)+)*'],
        \   'SCREAMING_SNAKE_CASE': ['\v\u+%(_%(\u|\d)+)*'],
        \ }
endif


" Params:
"   - group:      Group
"   - class_name: TextClass
" Returns:
"   list<matched_col: number, ctext: Ctext>
function! cycle#matcher#naming#test(group, class_name) abort "{{{
  if get(a:group.options, 'match_word') && a:class_name != 'w'
    return s:not_found(a:class_name)
  endif

  " Never handle '.' phase
  if a:class_name == '.'
    return s:not_found(a:class_name)
  endif

  for item in a:group.items
    let cfg = get(g:cycle_naming_config, item, [])
    if empty(cfg)
      echohl WarningMsg | echomsg printf("Cycle: invalid `naming` item for '%s'", item) | echohl None
      continue
    endif

    let [pattern; rest] = cfg
    " rest is not used in matcher currently

    if a:class_name == 'w'
      let pattern = '\<' . pattern . '\m\>'
    endif

    if a:class_name == 'v'
      let cvisual = cycle#text#new_cvisual()
      let v_begin = cvisual.col
      let v_end = v_begin + len(cvisual.text)
      let pattern = '\%' . v_begin . 'c' . pattern . '\m\%' . v_end . 'c'
    endif

    let [line, col, text] = cycle#matcher#regex#test_pattern(pattern)
    if col > 0
      let index = index(a:group.items, item)
      let ctext = {
            \   'text': text,
            \   'line': line,
            \   'col': col,
            \ }
      if a:class_name == 'v' && ctext != cycle#text#new_cvisual()
        continue
      elseif a:class_name == 'w' && ctext != cycle#text#new_cword()
        continue
      endif
      return [index, ctext]
    endif
  endfor

  return s:not_found(a:class_name)
endfunction "}}}


function! s:not_found(class_name) abort " {{{
  let not_found_ctext = cycle#text#new_ctext(a:class_name)
  return [-1, not_found_ctext]
endfunction " }}}
