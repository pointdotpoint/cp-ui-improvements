# Character Creator UI Improvements 1.0.0: in-game release testing

The offline checks (`scripts/release-check.sh`) cover compilation, compatibility and packaging. These tests need the running game. Use the build from `scripts/deploy.sh` (identical to `dist/CharacterCreatorUIImprovements-1.0.0.zip`), and restart the game after deploying.

Status key: **done** = observed working in the logs or reported during development; **todo** = not yet tested. The "done" rows were verified on the hairstyle-only build (then called Hair Grid), before the rename and before the grid covered more rows.

## General

| # | Scenario | Status | Evidence / notes |
|---|---|---|---|
| 1 | Startup: `[CCUIImprovements] Character Creator UI Improvements 1.0.0 ready` in `gamelog.log`, no redscript error popup | todo | |
| 2 | Pick an entry from a grid, then CONFIRM: finalizes normally | done (hair) / todo | 2026-09-25 13:01: apply #152, then "refinalize complete". Re-check after picking a nose or tattoo. |
| 3 | Favorites: star toggles, favorites sort first, notice fades, header count is per category | done (hair) / todo | A starred nose must not count in the hair header. |
| 4 | Favorites persist after a full quit and relaunch | todo | Codeware writes persistent data on clean exit; also check after an Alt+F4. Hair favorites from the Hair Grid builds reset once because of the rename. |
| 5 | New Game creator, real apartment mirror, ripperdoc, Character Customization Anywhere | mirror via CCA done (hair) / rest todo | |
| 6 | Male V | todo | Morph and switcher counts differ. |
| 7 | Esc closes the grid; Enter/F don't confirm while it's open | todo | |
| 8 | Gamepad: nothing breaks, arrows still work | todo | The grid itself is mouse-only (known limitation). |
| 9 | Tile text: long names end with "…" inside the tile, no overlap | todo | |
| 9b | Paging: one or two pages shows `< PREV` / `NEXT >` only; more than two shows `FIRST` `<<` `>>` `LAST`, and FIRST/LAST jump to the ends | todo | E.g. nose (one page) vs hairstyle (many pages). |
| 10 | Rows *without* a grid (skin tone, hair color, eyes, eyebrows, …) look and behave vanilla | todo | |
| 11 | Uninstall: delete the folder; the game starts and the creator is vanilla | todo | |

## Per row
For each row, check that it shows `◁ ▦ ▷`, then open its grid. The title should match the row, the entry count should be right, and the current entry should be highlighted. Clicking a tile should change the model and the row label; ◁ ▷ should still work afterwards.

| Row | `uiSlot` | Kind | Status |
|---|---|---|---|
| Hairstyle | `hairstyle` | switcher | done (hair-only build) / todo |
| Mouth | `mouth` | morph | todo |
| Nose | `nose` | morph | todo |
| Jaw | `jaw` | morph | todo |
| Ears | `ear` | morph | todo |
| Cyberware | `cyberware_switcher` | switcher | todo |
| Facial tattoos | `facial_tattoo_switcher` | switcher | todo |
| Piercings | `piercings` | switcher | todo |
| Eye makeup | `makeupEyes` | switcher | todo |
