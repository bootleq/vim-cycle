" Year matcher
"
" Each group item is a calendar era system, cursor is match as long as:
" - in continuous digits looks like CE (Common Era) year, e.g., 2024
" - in digits with 'item' itself prefixed, e.g., 昭和40
"
" Example group items:
"   ['民國', 'พ.ศ.', 'CE']
" Note the 'CE' must be put as last item to avoid overshadow others.

let g:cycle_year_config = {
      \   '民國': {'range': [1,  200], 'begin': 1912},
      \   '令和': {'range': [1,  200], 'begin': 2019},
      \   '平成': {'range': [1,   31], 'begin': 1989, 'end': 2019},
      \   '昭和': {'range': [1,   64], 'begin': 1926, 'end': 1989},
      \   '大正': {'range': [1,   15], 'begin': 1912, 'end': 1926},
      \   '明治': {'range': [1,   45], 'begin': 1868, 'end': 1912},
      \   'พ.ศ.': {'range': [1, 2700], 'begin': -543},
      \   'CE':   {},
      \ }

" See `s:group_search()` in autoload/cycle.vim
function! cycle#matcher#year#test(group, class_name) abort "{{{
  " Opt-out phased search by only performed in final phase ('' or v)
  if a:class_name != '' && a:class_name != 'v'
    return s:not_found(a:class_name)
  endif

  let target_ce_sizes = s:prepare_ce_range(a:group.items)

  for item in a:group.items
    if item == 'CE'
      let pattern = join([
            \   '\<\d\{' . printf('%s,%s', target_ce_sizes[0], target_ce_sizes[1]) . '}\>'
            \ ], '')
    else
      let cfg = get(g:cycle_year_config, item)
      if empty(cfg)
        echoerr "Cycle: invalid year item: " . string(item)
      endif

      let len_cfg_range = [len(string(cfg.range[0])), len(string(cfg.range[1]))]
      let pattern = join([
            \   item . '\s*',
            \   '\<\d\{' . printf('%s,%s', len_cfg_range[0], len_cfg_range[1]) . '}\>'
            \ ], '')
    endif

    let [line, col, text] = cycle#matcher#regex#test_pattern(pattern)

    if col > 0
      let index = index(a:group.items, item)
      let ctext = {
            \   'text': text,
            \   'line': line,
            \   'col': col,
            \ }
      return [index, ctext]
    endif
  endfor

  return s:not_found(a:class_name)
endfunction "}}}


" Try narrow down CE pattern by check only valid year ranges.
" For example if the only other item is one with CE range in [10, 100] then
" the CE patten can only match 2~3 digits, here returns [2, 3].
function! s:prepare_ce_range(items) abort " {{{
  let ce_range = [-1, -1]

  for item in a:items
    if item == 'CE'
      continue
    endif
    let cfg = get(g:cycle_year_config, item)
    if type(cfg) == type({})
      let cfg_max = cfg.begin + cfg.range[1]
      let ce_range[0] = ce_range[0] < 0 ? cfg.begin : min([ce_range[0], cfg.begin])
      let ce_range[1] = ce_range[1] < 0 ? cfg_max : max([ce_range[1], cfg_max])
    endif
  endfor
  let target_ce_sizes = [len(string(ce_range[0])), len(string(ce_range[1]))]

  return target_ce_sizes
endfunction " }}}


function! s:not_found(class_name) abort " {{{
  let not_found_ctext = cycle#text#new_ctext(a:class_name)
  return [-1, not_found_ctext]
endfunction " }}}
