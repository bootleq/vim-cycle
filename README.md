Cycle.vim
=========

Cycle text within predefined candidates.

  - `yes` =&gt; `no` =&gt; `yes`
  - `January` =&gt; `February` =&gt; `March`
  - `trUe` =&gt; `faLse` &nbsp; keep case by default
  - `"` =&gt; `'` &nbsp; can handle non-keywords
  - 可`是` =&gt; 可`否` &nbsp; multibyte is fine
  - `Rails Metal` =&gt; `Thrash` =&gt; `Technical Death` &nbsp; handle multi-words by visual selection, or smart auto search
  - `<em>`important`</em>` =&gt; `<strong>`important`</strong>` &nbsp; tag pairs cycle together
  - `「`quoted`」` =&gt; `『`quoted`』` &nbsp; special pairs cycle together


Configuration Example
---------------------

```vim
let g:cycle_no_mappings = 1
let g:cycle_max_conflict = 14
let g:cycle_select_ui = 'ui.select'
let g:cycle_conflict_ui = 'confirm'
let g:cycle_phased_search = 1

nmap <silent> <LocalLeader>a <Plug>CycleNext
vmap <silent> <LocalLeader>a <Plug>CycleNext
nmap <silent> <Leader>a <Plug>CyclePrev
vmap <silent> <Leader>a <Plug>CyclePrev
nmap <silent> <LocalLeader>ga <Plug>CycleSelect
vmap <silent> <LocalLeader>ga <Plug>CycleSelect

let g:cycle_default_groups = [
      \   [['true', 'false']],
      \   [['yes', 'no']],
      \   [['on', 'off']],
      \   [['+', '-']],
      \   [['>', '<']],
      \   [['"', "'"]],
      \   [['==', '!=']],
      \   [['0', '1']],
      \   [['and', 'or']],
      \   [['next', 'previous', 'prev']],
      \   [['asc', 'desc']],
      \   [['是', '否']],
      \   [['，', '。', '、']],
      \   [['✓', '✗', '◯', '✕', '✔', '✘', '⭕', '✖']],
      \   [['lat', 'lon']],
      \   [['latitude', 'longitude']],
      \   [['ancestor', 'descendant']],
      \   [['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      \     'Friday', 'Saturday'], ['hard_case', {'name': 'Days'}]],
      \   [['(:)', '（:）', '「:」', '『:』'], 'sub_pairs'],
      \ ]

" For fileType "ruby" only
let g:cycle_default_groups_for_ruby = [
      \   [['stylesheet_link_tag', 'javascript_include_tag']],
      \ ]

" For HTML, but here just blindly add to global groups
let g:cycle_default_groups += [
      \   [['h1', 'h2', 'h3', 'h4'], 'sub_tag'],
      \   [['ul', 'ol'], 'sub_tag'],
      \   [['em', 'strong', 'small'], 'sub_tag'],
      \ ]

let g:cycle_default_groups += [
      \   [['日', '一', '二', '三', '四', '五', '六']],
      \   [['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']],
      \   [['January', 'February', 'March', 'April', 'May', 'June', 'July',
      \     'August', 'September', 'October', 'November', 'December']],
      \   [['portrait', 'landscape']],
      \ ]
```


Similar Projects
----------------

- [SwapIt][SwapIt.vim] by [Michael Brown][mjbrownie]  
  Original ideas of special features including visual multi-words, xml tag
  pairs, omni-complete cycling.

- [Cycle.vim][original-cycle] by [Zef][MadeByWiki]  
  Yes, there is already a plugin named 'Cycle'. Maybe I have to rename mine.

- [switch.vim][] by [AndrewRadev][Andrew's Blog]  
  Supports more complicated patterns like ruby `:a => 'b'` to `a: 'b'`, which
  is generally unable to achieve by alternative projects.

- [vim-clurin][] by [syngan][]  
  Another early implementation, seems to have custom pattern and replace
  function features, but lacks documentation.

- [toggle.vim][] by [Timo Teifel][tteifel]  
  Maybe the very first plugin that introduced this idea.


Blog Posts
----------

- In 繁體中文:

  - [開發背景](https://bootleq.blogspot.com/2011/09/vim-plugin-cycle.html "Vim plugin - cycle 開發背景 - 沒穿方服") (2011)
  - [簡易使用說明](https://bootleq.blogspot.com/2011/09/cyclevim.html "cycle.vim 簡易使用說明 - 沒穿方服") (2011)
  - [Group 設定簡介](https://bootleq.blogspot.com/2011/10/cyclevim-group.html "cycle.vim - group 設定簡介 - 沒穿方服") (2011)


TODO
----
[wiki/TODO](https://github.com/bootleq/vim-cycle/wiki/Todo)


[toggle.vim]: https://www.vim.org/scripts/script.php?script_id=895
[tteifel]: http://www.teifel.net/
[SwapIt.vim]: https://github.com/mjbrownie/swapit
[mjbrownie]: https://github.com/mjbrownie
[Andrew's Blog]: http://andrewradev.com/
[original-cycle]: https://github.com/zef/vim-cycle
[vim-increx]: https://github.com/itchyny/vim-increx
[switch.vim]: https://github.com/AndrewRadev/switch.vim
[MadeByWiki]: http://madebykiwi.com/
[vim-clurin]: https://github.com/syngan/vim-clurin
[syngan]: https://github.com/syngan
