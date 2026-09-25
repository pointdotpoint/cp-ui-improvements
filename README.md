# cp-ui-improvements

Cyberpunk 2077 UI tweaks. The first mod here is **Character Creator UI Improvements**. It adds a paged, clickable grid with favorites to the character creator's option rows, so you don't have to step through hundreds of entries one at a time with ◁ ▷.

## Character Creator UI Improvements

### Rows with a grid
The rows are listed in `CCUI_IsGridSlot` in `GridTargets.reds`:

| Row | `uiSlot` | Entries come from |
|---|---|---|
| Hairstyle | `hairstyle` | `gameuiSwitcherInfo.options` |
| Cyberware | `cyberware_switcher` | `gameuiSwitcherInfo.options` |
| Facial tattoos | `facial_tattoo_switcher` | `gameuiSwitcherInfo.options` |
| Piercings | `piercings` | `gameuiSwitcherInfo.options` |
| Eye makeup | `makeupEyes` | `gameuiSwitcherInfo.options` |
| Mouth | `mouth` | `gameuiMorphInfo.morphNames` |
| Nose | `nose` | `gameuiMorphInfo.morphNames` |
| Jaw | `jaw` | `gameuiMorphInfo.morphNames` |
| Ears | `ear` | `gameuiMorphInfo.morphNames` |

### What it does
- Each of those rows gets the same `◁ ▦ ▷` layout as Skin Tone and Hair Color, using the vanilla gallery art. The middle ▦ opens the grid for that row. Rows with only one entry are left alone.
- It works in the New Game creator and in edit mode (mirrors and ripperdocs).
- **The grid** opens on the right, over the option list, so the model stays visible. It shows 27 entries per page (3×9), titled with the row's name (e.g. "NOSE").
  - Each tile shows the display name, the index and the internal name, so modded entries that share a display name can be told apart.
  - It opens on the page with the current entry, which is highlighted in cyan.
  - Clicking a tile applies it right away, and the grid stays open so you can try several in a row.
- **Favorites:** click the star in a tile's top-right corner to favorite or unfavorite it.
  - Favorites are listed first, gold-starred, and counted per category in the header.
  - They're keyed as `<uiSlot>:<internal name>`, so they survive mods being added or removed, and they're shared across all saves (Codeware persistent storage).
  - A star button in the footer, before CLOSE, favorites or unfavorites the entry currently applied. It's gold when that entry is a favorite.
  - Clicking the star doesn't apply the entry. A short notice ("Added to favorites: …" / "Removed from favorites: …") appears above the buttons and fades out.
- **Minimize rows:** every row (including voice tone) gets a small `[–]` left of its name. Minimizing collapses the row to a single bare line with its name and value (no frame); `[+]` expands it again. The collapsed row's arrows and buttons are disabled, so it can't be changed by accident. Minimized rows are remembered across sessions and saves, keyed by the option's internal name (`voice_tone` for the voice switcher). Color-swatch rows show only their name while minimized.
- **Paging:** with one or two pages, `< PREV` / `NEXT >` (wrapping around). With more than two pages the footer becomes `FIRST` `‹` `›` `LAST` (drawn chevrons; the game font has no ‹ › glyphs). **CLOSE**, or Esc, closes the grid.
- While a grid is open, confirm and randomize inputs are blocked so a stray click can't finish character creation.
- The vanilla ◁ ▷ arrows keep working.
- Not supported yet: thumbnails, gamepad navigation in the grid, hotkeys.

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
scripts/package.sh         # just build + verify dist/CharacterCreatorUIImprovements-<version>.zip
```
`release-check.sh` runs, in order:
0. **Tooling sanity:** a deliberately broken script must be reported as failing. redscript-cli 0.5.31 exits 0 even on failed builds, so `scripts/lib.sh` judges success by the compiler's output.
1. **Lint** with redscript 0.5.31.
2. **Compile** against the vanilla bundle plus Codeware.
3. **Compile** with every mod installed in the game folder. Only diagnostics in our files count.
4. **Compile** with the redscript 1.0 preview. Our files must be clean; Codeware 1.19 itself has errors under 1.0.
5. **Nexus compatibility:** mods in [rfuzzo/cyberpunk-nexus-script-dump](https://github.com/rfuzzo/cyberpunk-nexus-script-dump) that annotate the same classes. Duplicate `@addMethod`/`@addField` names on the classes we touch fail the check. A `@replaceMethod` on a method we wrap is reported as a note, since our wrapper runs around the replacement. Each of those mods is then compiled next to ours. Mods that don't compile on the current game version even without ours are reported separately.
6. **Package:** builds the zip, checks it contains exactly `r6/scripts/CPUIImprovements/CharacterCreator/*.reds`, and compiles the extracted copy. It refuses to package if debug logging is on.

Release docs: `CHANGELOG.md`, `docs/nexus-description.bbcode` (paste into the Nexus description, which uses BBCode) and `docs/release-testing.md` (in-game test sheet). Bump the version in `ModInfo.reds` (`CCUI_Version()`).

### Compile check (offline, no game launch)
```sh
scripts/check.sh          # our scripts + Codeware against the vanilla bundle
scripts/check.sh --full   # plus every installed mod (reports only our diagnostics)
scripts/check.sh --log    # errors / mod lines from the game's last compile log
```
The first run builds `redscript-cli` v0.5.31 into `.tools/`. That version matches the game's `scc.exe`.

### Code (`src/r6/scripts/CPUIImprovements/CharacterCreator/`)
- `GridTargets.reds`: which rows get a grid, plus adapters that read switcher and morph entries (count, label, internal name, favorite key, title).
- `MenuHooks.reds`: hooks on `characterCreationBodyMorphMenu`:
  - `InitializeList`, `CreateEntry`, `OnOptionUpdated`, `OnButtonRelease`, `ConfirmCustomizedCharacter`
  - `CCUI_OpenFor(option)` and `CCUI_Apply(index)`. The latter mirrors vanilla `OnSliderChange` → `ApplyChangeToOption`.
- `SelectorGallery.reds`: restyles a `Selector` row (`characterCreationBodyMorphOption`) with the gallery art and adds the middle button, which opens that row's own option.
- `OptionGridOverlay.reds`: the Codeware `inkCustomController` overlay, one instance reused for every row.
- `OptionFavorites.reds`: the favorites store, a `ScriptableService` with a `persistent` `array<CName>`.
- `RowCollapse.reds`: the minimize toggle. It wraps `CreateVoiceOverSwitcher` for the voice row; other rows attach from the `CreateEntry` wrap. `RowLayoutStore` is a persistent service holding the minimized rows.
- `ModInfo.reds`: version constant and log switches.

Logging uses Codeware `ModLog(n"CCUIImprovements", ...)`, which writes to `<game>/bin/x64/plugins/cyber_engine_tweaks/gamelog.log` (flushed with a delay while the game runs). Release builds log one line at startup (`Character Creator UI Improvements <version> ready`). Set `CCUI_DebugLogging()` to `true` in `ModInfo.reds` for verbose open, apply and confirm lines.

The in-game test sheet is `docs/release-testing.md`.

## License
MIT, see `LICENSE`.
