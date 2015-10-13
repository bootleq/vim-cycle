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


Similar Projects
================

- [SwapIt][SwapIt.vim] by [Michael Brown][mjbrownie]  
  Original ideas of special features including visual multi-words, xml tag
  pairs, omni-complete cycling.

- [Cycle.vim][original-cycle] by [Zef][MadeByWiki]  
  Yes, there is already a plugin named 'Cycle'. Maybe I have to rename mine.

- [switch.vim][] by [AndrewRadev][Andrew's Blog]  
  Supports more complicated patterns like ruby `:a => 'b'` to `a: 'b'`, which
  is generally unable to achieve by alternative projects.


TODO
----
[wiki/TODO](https://github.com/bootleq/vim-cycle/wiki/Todo)


[SwapIt.vim]: https://github.com/mjbrownie/swapit
[mjbrownie]: https://github.com/mjbrownie
[Andrew's Blog]: http://andrewradev.com/
[original-cycle]: https://github.com/zef/vim-cycle
[vim-increx]: https://github.com/itchyny/vim-increx
[switch.vim]: https://github.com/AndrewRadev/switch.vim
[MadeByWiki]: http://madebykiwi.com/
