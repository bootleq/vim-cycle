" SwapIt Compatibility
function! cycle#swapit#try_compatible()
  command! -nargs=* SwapList call AddSwapList(<q-args>)
  command! -nargs=0 ClearSwapList call ClearSwapList()
  command! -nargs=0 SwapIdea call OpenSwapFileType()
  command! -nargs=0 SwapListLoadFT call LoadFileTypeSwapList()
  command! -nargs=+ SwapXmlMatchit call AddSwapXmlMatchit(<q-args>)
endfunction


" List Maintenance Functions {{{

if exists('*ClearSwapList') "{{{
  call s:warn('Function "ClearSwapList" has already defined. Cycle.vim has stopped overwriting it.')
else
  function ClearSwapList()
    for scope in ['b', 'g']
      if exists({scope}:cycle_groups)
        let {scope}:cycle_groups = []
      endif
    endfor
  endfunction
endif "}}}

if exists('*AddSwapList') "{{{
  call s:warn('Function "AddSwapList" has already defined. Cycle.vim has stopped overwriting it.')
else
  function AddSwapList(list)
    let list = split(a:list, '\s\+')
    if len(list) < 3
      call s:warn("Usage :SwapList <list_name> <member1> <member2> ... <memberN>")
      return
    endif

    let name = remove(list, 0)
    call cycle#add_group(list, {'name': name})
  endfunction
endif "}}}

if exists('*AddSwapXmlMatchit') "{{{
  call s:warn('Function "AddSwapXmlMatchit" has already defined. Cycle.vim has stopped overwriting it.')
else
  function AddSwapXmlMatchit(list)
    " TODO: implement or provide alternates
    call s:warn('Function "AddSwapXmlMatchit" is not compatible with Cycle.vim.')
  endfunction
endif "}}}

if exists('*LoadFileTypeSwapList') "{{{
  call s:warn('Function "LoadFileTypeSwapList" has already defined. Cycle.vim has stopped overwriting it.')
else
  function LoadFileTypeSwapList()
    " TODO: implement or provide alternates
    " load filetype specified configures from scripts in runtimepath
    call s:warn('Function "LoadFileTypeSwapList" is not compatible with Cycle.vim.')
  endfunction
endif "}}}

if exists('*OpenSwapFileType') "{{{
  call s:warn('Function "OpenSwapFileType" has already defined. Cycle.vim has stopped overwriting it.')
else
  function OpenSwapFileType()
    " TODO: implement or provide alternates
    " edit filetype specified configures scripts from runtimepath
    call s:warn('Function "LoadFileTypeSwapList" is not compatible with Cycle.vim.')
  endfunction
endif "}}}

" List Maintenance Functions {{{


" Utils: {{{
  
function! s:warn(msg)
  redraw
  echohl WarningMsg | echomsg a:msg | echohl None
endfunction

" }}} Utils
