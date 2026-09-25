# Hair Grid 1.0.0: in-game release testing

The offline checks (`scripts/release-check.sh`) cover compilation, compatibility and packaging. These tests need the running game. Use the build from `scripts/deploy.sh` (identical to `dist/HairGrid-1.0.0.zip`), and restart the game after deploying.

Status key: **done** = observed working in the logs or reported during development; **todo** = not yet tested; **n/a** = known limitation.

| # | Scenario | Status | Evidence / notes |
|---|---|---|---|
| 1 | Startup: `[HairGrid] Hair Grid 1.0.0 ready` in `gamelog.log`, no redscript error popup | todo | The release build changes struct-construction syntax and trims hooks, so this needs one launch. |
| 2 | Mirror (via Character Customization Anywhere): ▦ button shows, grid opens | done | 2026-09-25 13:01: grid opened with 226 styles. |
| 3 | Pick a hair from the grid, then CONFIRM: finalizes normally | done | 13:01:25 apply #152, 13:01:32 "refinalize complete"; repeated at 13:02. |
| 4 | Favorites: star toggles, favorites sort first, notice fades | done / todo | Toggle and sort reported working; the fading notice hasn't been seen in game yet. |
| 5 | Favorites persist after a full quit and relaunch | todo | Codeware writes persistent data on clean exit; also check after an Alt+F4. |
| 6 | New Game character creator (not the mirror) | todo | Uses the same menu class, with `m_updatingFinalizedState = false`. |
| 7 | Real apartment mirror | todo | |
| 8 | Ripperdoc appearance change | todo | |
| 9 | Male V (different hair list) | todo | |
| 10 | Small hair list (vanilla or few CCXL mods): a single page, PREV/NEXT wrap cleanly | todo | |
| 11 | Esc closes the grid; Enter/F don't confirm while it's open | todo | |
| 12 | Gamepad: nothing breaks, arrows still work | todo | The grid itself is mouse-only (known limitation). |
| 13 | Tile text: long names end with "…" inside the tile, no overlap | done / todo | The first styling pass overflowed; the clipped version hasn't been re-screenshotted. |
| 14 | Uninstall: delete the folder; the game starts and the creator is vanilla | todo | |
