# Changelog

## Hair Grid 1.0.0

First release.

- The hairstyle row gets a vanilla-style `◁ ▦ ▷` layout; the middle button opens a paged grid (3×9) of every hairstyle, CCXL hairs included.
- Clicking a tile applies the hair immediately; the grid opens on the page with the current hair.
- Favorites: a star toggle on each tile pins that hair to the front. Stored by internal option name and shared across saves (Codeware persistent service). A fading notice confirms each add or remove.
- Styled with the game's MainColors palette; long names are clipped to the tile.
- While the grid is open, Esc closes it, and confirm/randomize input is blocked.
