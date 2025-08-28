" TextClass: '.' | '' | 'w' | 'v' | '' | '-'
" . : current cursor char / cchar, might be multibyte (is still 1 character)
" w : current cursor word / cword
" v : visual selection
"   : empty, no above classes matched, can try search in expanded range
" - : dummy, noop
"
" These functions returns 'Ctext' dict for certain 'TextClass' context.

function! cycle#text#new_ctext(text_class) "{{{
  if a:text_class == 'w'
    let ctext = cycle#text#new_cword()
    if ctext.col == 0
      let ctext = cycle#text#new_cchar()
    endif
  elseif a:text_class == '.'
    let ctext = cycle#text#new_cchar()
  elseif a:text_class == 'v'
    let ctext = cycle#text#new_cvisual()
  else
    let ctext = {
          \   "text": '',
          \   'line': 0,
          \   "col": 0,
          \ }
  endif
  return ctext
endfunction "}}}


function! cycle#text#new_cword() "{{{
  let ckeyword = expand('<cword>')
  let cchar = cycle#text#new_cchar()
  let cword = {
        \   "text": '',
        \   'line': 0,
        \   "col": 0,
        \ }

  if match(ckeyword, cycle#util#escape_pattern(cchar.text)) >= 0
    let cword.line = line('.')
    let cword.col = match(
          \   getline('.'),
          \   '\%>' . max([0, cchar.col - strlen(ckeyword) - 1]) . 'c' . cycle#util#escape_pattern(ckeyword),
          \ ) + 1
    let cword.text = ckeyword
  endif
  return cword
endfunction "}}}


function! cycle#text#new_cvisual() "{{{
  let save_mode = mode()

  call cycle#util#save_reg('a')
  silent normal! gv"ay
  let cvisual = {
        \   "text": @a,
        \   "line": getpos('v')[1],
        \   "col": getpos('v')[2],
        \ }

  if save_mode == 'v'
    normal! gv
  endif
  call cycle#util#restore_reg('a')

  return cvisual
endfunction "}}}


function! cycle#text#new_cchar() "{{{
  call cycle#util#save_reg('a')
  normal! "ayl
  let cchar = {
        \   "text": @a,
        \   "line": getpos('.')[1],
        \   "col": getpos('.')[2],
        \ }
  call cycle#util#restore_reg('a')
  return cchar
endfunction "}}}
