# cp-ui-improvements

Cyberpunk 2077 UI tweaks. First one: **Hair Grid**. It adds a paged, clickable grid of every hairstyle to the character creator, so you don't have to step through them one at a time with the left/right switcher.

## Hair Grid (MVP)

- The **HAIRSTYLE** row gets the same `< ▦ >` layout as Skin Tone / Hair Color. The middle ▦ button opens the grid. It works in New Game and in edit mode (mirror/ripperdoc).
- The grid opens on the right, over the option list, so the model stays visible. It shows 30 styles per page (3×10). Each tile shows its index, the display name and the internal option name, so CCXL hairs that share a display name can be told apart.
- The current style is highlighted. Clicking a tile applies it right away, and the grid stays open so you can try several styles in a row.
- **Favorites:** click the star in a tile's top-right corner to favorite or unfavorite it. Favorites are listed first, gold-starred. They're keyed by the internal hair name, so they survive hair mods being added or removed, and they're shared across all saves (Codeware persistent storage). Clicking the star doesn't apply the hair. A short notice ("Added to favorites: …" / "Removed from favorites: …") appears above the buttons and fades out.
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

### Release
```sh
scripts/release-check.sh   # every offline check below, then builds the package; exits non-zero on any FAIL
scripts/package.sh         # just build + verify dist/HairGrid-<version>.zip
```
`release-check.sh` runs, in order:
0. **Tooling sanity:** a deliberately broken script must be reported as failing. redscript-cli 0.5.31 exits 0 even on failed builds, so `scripts/lib.sh` judges success by the compiler's output.
1. **Lint** with redscript 0.5.31.
2. **Compile** against the vanilla bundle plus Codeware.
3. **Compile** with every mod installed in the game folder. Only diagnostics in our files count.
4. **Compile** with the redscript 1.0 preview. Our files must be clean; Codeware 1.19 itself has errors under 1.0.
5. **Nexus compatibility:** mods in [rfuzzo/cyberpunk-nexus-script-dump](https://github.com/rfuzzo/cyberpunk-nexus-script-dump) that annotate the same classes. The check looks for conflicting `@replaceMethod`/`@addMethod`/`@addField` on what we touch, then compiles each of those mods next to ours. Mods that don't compile on the current game version even without ours are reported separately.
6. **Package:** builds the zip, checks it contains exactly `r6/scripts/CPUIImprovements/HairGrid/*.reds`, and compiles the extracted copy. It refuses to package if debug logging is on.

Release docs: `CHANGELOG.md` and `docs/nexus-description.bbcode` (paste into the Nexus description, which uses BBCode). Bump the version in `HairGridInfo.reds` (`HG_Version()`).

### Compile check (offline, no game launch)
```sh
scripts/check.sh          # our scripts + Codeware against the vanilla bundle
scripts/check.sh --full   # plus every installed mod (reports only our diagnostics)
scripts/check.sh --log    # errors / HairGrid lines from the game's last compile log
```
The first run builds `redscript-cli` v0.5.31 into `.tools/`. That version matches the game's `scc.exe`.

### Code
- `src/r6/scripts/CPUIImprovements/HairGrid/MenuHooks.reds`: hooks on `characterCreationBodyMorphMenu`:
  - `InitializeList`, `CreateEntry`, `OnOptionUpdated`, `OnButtonRelease`, `ConfirmCustomizedCharacter`
  - `HG_Apply`, which mirrors vanilla `OnSliderChange` → `ApplyChangeToOption`
- `src/r6/scripts/CPUIImprovements/HairGrid/SelectorGallery.reds`: restyles the hairstyle `Selector` row (`characterCreationBodyMorphOption`) with the gallery art and adds the middle button.
- `src/r6/scripts/CPUIImprovements/HairGrid/HairGridOverlay.reds`: the Codeware `inkCustomController` overlay.
- `src/r6/scripts/CPUIImprovements/HairGrid/HairGridInfo.reds`: version constant and log switches.
- `src/r6/scripts/CPUIImprovements/HairGrid/HairFavorites.reds`: the favorites store, a `ScriptableService` with a `persistent` `array<CName>`.

Logging uses Codeware `ModLog(n"HairGrid", ...)`, which writes to `<game>/bin/x64/plugins/cyber_engine_tweaks/gamelog.log` (flushed with a delay while the game runs). Release builds log one line at startup (`Hair Grid <version> ready`); set `HG_DebugLogging()` to `true` in `HairGridInfo.reds` for verbose click, apply and confirm lines.

## In-game test checklist
1. Deploy, then launch. If redscript shows an error popup, run `scripts/check.sh --log`.
2. New Game → appearance step: the HAIRSTYLE row shows `< ▦ >` like HAIR COLOR, and hovering the middle highlights it.
3. Open it. The tile count should equal the number of hairstyles, including CCXL ones, and the current one should be highlighted.
4. Click a few tiles. The hair should change on the model, and the vanilla hairstyle selector label should follow.
5. Check PREV/NEXT wrap-around, then CLOSE, then Esc.
6. While the grid is open, press Enter/space: character creation should *not* advance.
7. Finish the creator and confirm the chosen hair persists.
8. Repeat in edit mode (mirror or ripperdoc).
