#!/usr/bin/env bash
# Offline compile check against the installed game's vanilla script bundle.
#   scripts/check.sh          our sources + Codeware
#   scripts/check.sh --full   also every installed r6/scripts mod and RED4ext plugin scripts
#                             (catches conflicts with other mods hooking the same methods)
#   scripts/check.sh --log    show HairGrid-related lines from the game's last redscript log
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="${CP2077_DIR:-$HOME/.local/share/Steam/steamapps/common/Cyberpunk 2077}"
CLI="$ROOT/.tools/redscript-src/target/release/redscript-cli"
SRC="$ROOT/src/r6/scripts/CPUIImprovements"

if [[ "${1:-}" == "--log" ]]; then
    LOG="$GAME/r6/logs/redscript_rCURRENT.log"
    grep -nE "ERROR|WARN|CPUIImprovements|HairGrid" "$LOG" || echo "no errors or HairGrid lines in $LOG"
    exit 0
fi

if [[ ! -x "$CLI" ]]; then
    echo "building redscript-cli v0.5.31 (matches the game's scc.exe)..."
    mkdir -p "$ROOT/.tools"
    [[ -d "$ROOT/.tools/redscript-src" ]] || \
        git clone -q --depth 1 --branch v0.5.31 https://github.com/jac3km4/redscript.git "$ROOT/.tools/redscript-src"
    (cd "$ROOT/.tools/redscript-src" && cargo build --release -p redscript-cli)
fi

OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

args=(-s "$SRC" -s "$GAME/red4ext/plugins/Codeware/Scripts")
if [[ "${1:-}" == "--full" ]]; then
    args=(-s "$GAME/r6/scripts")
    for d in "$GAME"/red4ext/plugins/*/Scripts; do args+=(-s "$d"); done
    # Include ours from the source tree, not a possibly stale deployed copy.
    if [[ -d "$GAME/r6/scripts/CPUIImprovements" ]]; then
        echo "note: --full compiles the deployed copy in r6/scripts; run deploy.sh first" >&2
    else
        args+=(-s "$SRC")
    fi
fi

if [[ "${1:-}" != "--full" ]]; then
    "$CLI" compile "${args[@]}" -b "$GAME/r6/cache/final.redscripts" -o "$OUT/final.redscripts"
    exit
fi

# Some installed mods fail offline (the game resolves extra script paths at launch),
# so only report diagnostics that point at our files.
"$CLI" compile "${args[@]}" -b "$GAME/r6/cache/final.redscripts" -o "$OUT/final.redscripts" \
    > "$OUT/log" 2>&1 || true
ours="$(grep -A4 -E "(ERROR|WARN).*CPUIImprovements" "$OUT/log" || true)"
others="$(grep -E "ERROR.*At " "$OUT/log" | grep -vc CPUIImprovements || true)"
if [[ -n "$ours" ]]; then
    echo "$ours"
    exit 1
fi
echo "no diagnostics in CPUIImprovements ($others errors from other mods ignored)"
