function! cycle#select#inputlist(options) "{{{
  let index = 0
  let candidates = []
  let max_length = max(map(copy(a:options), 'strlen(v:val.text)'))
  for option in a:options
    let group = get(option, 'group_name', '')
    let line = printf(
          \   '%2S => %-*S %S',
          \   index + 1,
          \   max_length,
          \   option.text,
          \   len(group) ? printf(' (%s)', group) : ''
          \ )
    call add(candidates, line)
    let index += 1
  endfor
  let list = ["Cycle to:"]
  call extend(list, candidates)
  " Example output:
  "
  "Cycle to:
  " 1 => bar    (foobar)
  " 2 => poooo  (pupu)
  " 3 => gOO
  let choice = inputlist(list)
  if choice > index
    let choice = -1
  endif
  return choice
endfunction "}}}


function! cycle#select#confirm(options) "{{{
  let index = 0
  let captions = []
  let candidates = []
  let max_length = max(map(copy(a:options), 'strlen(v:val.text)'))
  for option in a:options
    let caption = nr2char(char2nr('A') + index)
    let group = get(option, 'group_name', '')
    let line = printf(
          \   ' %2S) => %-*S %S',
          \   caption,
          \   max_length,
          \   option.text,
          \   len(group) ? printf(' (%s)', group) : ''
          \ )
    call add(candidates, line)
    call add(captions, '&' . caption)
    let index += 1
  endfor
  " Example output:
  "
  "Cycle to:
  "
  "  A) => bar    (foobar)
  "  B) => poooo  (pupu)
  "  C) => gOO
  "
  "(A), (B), (C):
  redraw
  return confirm("Cycle to:\n\n" . join(candidates, "\n") . "\n", join(captions, "\n"), 0)
endfunction "}}}
