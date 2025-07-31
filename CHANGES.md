CHANGES
=======

## 0.5.0 (2025-07-31)

* New `CycleSelect` function, list all candidates to choose from. (#3)

* Provide alternative selection prompt UI types: `vim.ui.select` (nvim) / `inputlist` / `confirm`.

* Change the content of conflict selection UI, especially, show "expected result" first, "group name" later.

## 0.4.0 (2018-10-24)

* Change: remove `0`/`1`, `+`/`-` and `>`/`<` from plugin defaults (thanks to @kiryph, #12).

* Fix incorrect jump in fallback mapping (after any visual change).

* Support repeat of fallback mapping.

## 0.3.2 (2018-10-19)

* Enhance fallback mapping behavior on multi-line selection (thanks to @kiryph, #11).

* Fix generating unnecessary messages during internal yanking.

## 0.3.1 (2017-12-25)

* Defer group initialization to improve Vim startup time (thanks to @fourjay, #10).

## 0.3.0 (2017-04-02)

* No longer reset `b:cycle_groups` when filetype change.

* Deprecate `cycle#reset_b_groups_by_filetype` function since we no longer use `b:cycle_groups` to hold filetype-specified groups.

## 0.2.1 (2016-10-15)

* Fix misleading doc about default value of `hard_case` and `match_case` (#4).

* Fix `sub_pair` does not find item case-sensitively when `match_case` is set.

## 0.2.0 (2015-10-12)

* Add `match_word` group option, restrict item matching only on whole word.

## 0.1.1 (2011-11-26)

* Stable release.
