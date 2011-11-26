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
  Original ideas of special features includes visual multi-words, xml tag
  pairs, omni-complete cycling.

- [Cycle.vim][original-cycle] by [Zef][MadeByWiki]  
  Yes, there is already a plugin named 'Cycle'. Maybe I have to rename mine.


TODO
----
[wiki/TODO](https://github.com/bootleq/vim-cycle/wiki/Todo)


[SwapIt.vim]: https://github.com/mjbrownie/swapit
[mjbrownie]: https://github.com/mjbrownie
[original-cycle]: https://github.com/zef/vim-cycle
[MadeByWiki]: http://madebykiwi.com/
