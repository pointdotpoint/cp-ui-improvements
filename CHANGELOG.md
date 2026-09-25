# Changelog

## Character Creator UI Improvements 1.0.0

First release. Developed as "Hair Grid", which was never published.

- A grid picker for 9 character-creator rows: hairstyle, mouth, nose, jaw, ears, cyberware, facial tattoos, piercings and eye makeup.
  - Each row gets a vanilla-style `◁ ▦ ▷` layout; the middle button opens a paged grid (3×9) of every entry, modded CCXL entries included.
  - Clicking a tile applies it immediately. The grid opens on the page with the current entry.
- Favorites: a star toggle on each tile pins that entry to the front of its category.
  - Stored by internal name per category and shared across saves (Codeware persistent service).
  - A fading notice confirms each add or remove.
- Styled with the game's MainColors palette; long names are clipped to the tile.
- While a grid is open, Esc closes it, and confirm/randomize input is blocked.
