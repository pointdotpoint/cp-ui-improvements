# Character Creator UI Improvements 1.0.0: in-game release testing

The offline checks (`scripts/release-check.sh`) cover compilation, compatibility and packaging. These tests need the running game. Use the build from `scripts/deploy.sh` (identical to `dist/CharacterCreatorUIImprovements-1.0.0.zip`), and restart the game after deploying.

Status key: **done** = observed working in the logs or reported during development; **todo** = not yet tested. The "done" rows were verified on the hairstyle-only build (then called Hair Grid), before the rename and before the grid covered more rows.

## General

| # | Scenario | Status | Evidence / notes |
|---|---|---|---|
| 1 | Startup: `[CCUIImprovements] Character Creator UI Improvements 1.0.0 ready` in `gamelog.log`, no redscript error popup | done | 2026-09-25 13:53:19: `[CCUIImprovements] Character Creator UI Improvements 1.0.0 ready`, no error popup. |
| 2 | Pick an entry from a grid, then CONFIRM: finalizes normally | done | Hair: 13:01 apply then "refinalize complete". Other rows reported working by the user ("it all works well"). |
| 3 | Favorites: star toggles, favorites sort first, notice fades, header count is per category | done | Nose and cyberware favorites stored per category (`nose:h042`, `cyberware_switcher:cyberware_07`); reported working. |
| 4 | Favorites persist after a full quit and relaunch | done | Keys present in Codeware's `ScriptableServiceContainer.dat` after a clean exit (14:00:10) and reported working after relaunch. Old Hair Grid favorites were lost to the pre-release rename (not a user-facing issue). |
| 5 | New Game creator, real apartment mirror, ripperdoc, Character Customization Anywhere | mirror via CCA done (hair) / rest todo | |
| 6 | Male V | todo | Morph and switcher counts differ. |
| 7 | Esc closes the grid; Enter/F don't confirm while it's open | todo | |
| 8 | Gamepad: nothing breaks, arrows still work | todo | The grid itself is mouse-only (known limitation). |
| 9 | Tile text: long names end with "…" inside the tile, no overlap | todo | |
| 9b | Paging: one or two pages shows `< PREV` / `NEXT >` only; more than two shows `FIRST` `<<` `>>` `LAST`, and FIRST/LAST jump to the ends | todo | E.g. nose (one page) vs hairstyle (many pages). |
| 9c | Minimize: `[–]` on voice tone and on a normal row collapses it to a bare line (no frame) with name and value; `[+]` restores it. The collapsed row's arrows don't respond. The state survives reopening the menu and a restart. The list scrolls correctly with rows collapsed. Mirrors with Appearance Change Unlocker, which removes the voice row, still work | partly done | Collapse, expand and persistence work (user, 14:15). Reworked to a bare 60-unit line after feedback; re-check the look and the list scrolling. |
| 10 | Rows *without* a grid (skin tone, hair color, eyes, eyebrows, …) look and behave vanilla | todo | |
| 11 | Uninstall: delete the folder; the game starts and the creator is vanilla | todo | |

## Per row
For each row, check that it shows `◁ ▦ ▷`, then open its grid. The title should match the row, the entry count should be right, and the current entry should be highlighted. Clicking a tile should change the model and the row label; ◁ ▷ should still work afterwards.

| Row | `uiSlot` | Kind | Status |
|---|---|---|---|
| Hairstyle | `hairstyle` | switcher | done |
| Mouth | `mouth` | morph | done (user-reported) |
| Nose | `nose` | morph | done (user-reported) |
| Jaw | `jaw` | morph | done (user-reported) |
| Ears | `ear` | morph | done (user-reported) |
| Cyberware | `cyberware_switcher` | switcher | done (user-reported) |
| Facial tattoos | `facial_tattoo_switcher` | switcher | done (user-reported) |
| Piercings | `piercings` | switcher | done (user-reported) |
| Eye makeup | `makeupEyes` | switcher | done (user-reported) |
