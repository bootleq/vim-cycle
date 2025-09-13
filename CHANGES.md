CHANGES
=======

## 1.4.0 (2025-09-13)

* Add `regex` group option, can cycle more complicated patterns like switch.vim (https://github.com/AndrewRadev/switch.vim)

* New group options: `matcher` and `changer`. In fact "regex" feature is made up by these mechanisms together.

* Add `year` group option, cycle between calendar era systems.

* Add `naming` group option, cycle between naming conventions.

* Add `hints` group option, display a static hint for each item in select or conflict UI.

* `sub_pairs` now supports using an identical character on both begin and end sides.

* `Cycle()` and `CycleSelect()` functions now accept extra groups argument,
  allow to use ad-hoc groups instead of ordinary added groups. This is useful
  to setup different mappings for another set of groups.

* Add another selection UI type `telescope` which opens a telescope.nvim picker.

* Add `cycle_filetype_links` option; to define certain filetypes to share other types' groups.

* Add events (User autocmd), to be listened by user.

* Change the phased search for multibyte character, fix a problem when cword is equal to cchar.

* Optional callbacks were moved to autoload functions.

## 1.0.0 (2025-08-27)

* Fix various `sub_pairs` / `sub_tag` cursor offset bugs.

* Change phased search behavior, do not skip final "search" phase even if there were already matches in previous phases.  
  This ensures defined groups were searched, instead of silently omitted by rules hard to reason.  
  This doesn't affect the case when `g:cycle_max_conflict` is 1 (still skip any further searches).

* Show warning message if `sub_pairs` can't find opposite counterpart.

* Add tests.

* Remove unused `g:cycle_phased_search` option.

## 0.6.0 (2025-08-14)

* Add `cond` group option, a way to dynamically toggle a group.

* Fix mistakenly modify `g:cycle_group` with `restrict_cursor` extended.

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
