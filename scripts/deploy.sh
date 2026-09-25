#!/usr/bin/env bash
# Copy the mod's scripts into the game. The game compiles them on next launch.
#   scripts/deploy.sh              install / update
#   scripts/deploy.sh --uninstall  remove
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="${CP2077_DIR:-$HOME/.local/share/Steam/steamapps/common/Cyberpunk 2077}"
DEST="$GAME/r6/scripts/CPUIImprovements"

if [[ ! -d "$GAME/r6/scripts" ]]; then
    echo "game not found at $GAME (set CP2077_DIR)" >&2
    exit 1
fi

rm -rf "$DEST"
if [[ "${1:-}" == "--uninstall" ]]; then
    echo "removed $DEST"
    exit 0
fi

cp -r "$ROOT/src/r6/scripts/CPUIImprovements" "$DEST"
echo "installed to $DEST:"
find "$DEST" -name '*.reds' | sed "s|$GAME/||"
