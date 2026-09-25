# cp-ui-improvements

Cyberpunk 2077 UI tweaks. First one: **Hair Grid**. It adds a paged, clickable grid of every hairstyle to the character creator, so you don't have to step through them one at a time with the left/right switcher.

## Hair Grid (MVP)

- The **HAIRSTYLE** row gets the same `< ▦ >` layout as Skin Tone / Hair Color. The middle ▦ button opens the grid. It works in New Game and in edit mode (mirror/ripperdoc).
- The grid opens on the right, over the option list, so the model stays visible. It shows 30 styles per page (3×10). Each tile shows its index, the display name and the internal option name, so CCXL hairs that share a display name can be told apart.
- The current style is highlighted. Clicking a tile applies it right away, and the grid stays open so you can try several styles in a row.
- **PREV/NEXT** change page. **CLOSE**, or the game's back key (Esc), closes the grid.
- While the grid is open, confirm and randomize inputs are blocked so a stray click can't finish character creation.
- The vanilla left/right switcher is untouched.
- Not in the MVP: thumbnails, gamepad navigation, hotkey.

### Requirements
redscript and Codeware. Tested setup: patch 2.31, redscript 0.5.31, Codeware 1.19.0.

### Install / uninstall
```sh
scripts/deploy.sh              # copies src/r6/scripts/CPUIImprovements -> <game>/r6/scripts/
scripts/deploy.sh --uninstall
```
Set `CP2077_DIR` if the game isn't at `~/.local/share/Steam/steamapps/common/Cyberpunk 2077`.

### Compile check (offline, no game launch)
```sh
scripts/check.sh          # our scripts + Codeware against the vanilla bundle
scripts/check.sh --full   # plus every installed mod (reports only our diagnostics)
scripts/check.sh --log    # errors / HairGrid lines from the game's last compile log
```
The first run builds `redscript-cli` v0.5.31 into `.tools/`. That version matches the game's `scc.exe`.

### Code
- `src/r6/scripts/CPUIImprovements/HairGrid/MenuHooks.reds`: hooks on `characterCreationBodyMorphMenu`:
  - `InitializeList`, `CreateEntry`, `OnOptionUpdated`, `OnButtonRelease`
  - `HG_Apply`, which mirrors vanilla `OnSliderChange` → `ApplyChangeToOption`
- `src/r6/scripts/CPUIImprovements/HairGrid/SelectorGallery.reds`: restyles the hairstyle `Selector` row (`characterCreationBodyMorphOption`) with the gallery art and adds the middle button.
- `src/r6/scripts/CPUIImprovements/HairGrid/HairGridOverlay.reds`: the Codeware `inkCustomController` overlay.

Debug lines are written with Codeware `ModLog(n"HairGrid", ...)`.

## In-game test checklist
1. Deploy, then launch. If redscript shows an error popup, run `scripts/check.sh --log`.
2. New Game → appearance step: the HAIRSTYLE row shows `< ▦ >` like HAIR COLOR, and hovering the middle highlights it.
3. Open it. The tile count should equal the number of hairstyles, including CCXL ones, and the current one should be highlighted.
4. Click a few tiles. The hair should change on the model, and the vanilla hairstyle selector label should follow.
5. Check PREV/NEXT wrap-around, then CLOSE, then Esc.
6. While the grid is open, press Enter/space: character creation should *not* advance.
7. Finish the creator and confirm the chosen hair persists.
8. Repeat in edit mode (mirror or ripperdoc).
