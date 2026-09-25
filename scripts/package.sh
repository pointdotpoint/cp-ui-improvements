#!/usr/bin/env bash
# Build the Nexus release archive and verify it.
#   scripts/package.sh   ->  dist/HairGrid-<version>.zip
#
# The zip's root mirrors the game folder (r6/scripts/...), which is what
# Vortex and manual "extract into the game folder" installs expect.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
GAME="${CP2077_DIR:-$HOME/.local/share/Steam/steamapps/common/Cyberpunk 2077}"
CLI="$ROOT/.tools/redscript-src/target/release/redscript-cli"
MOD_REL="r6/scripts/CPUIImprovements/HairGrid"
SRC="$ROOT/src/$MOD_REL"

VERSION="$(sed -nE 's/^public func HG_Version\(\) -> String = "([^"]+)".*/\1/p' "$SRC/HairGridInfo.reds")"
[[ -n "$VERSION" ]] || { echo "could not read HG_Version() from HairGridInfo.reds" >&2; exit 1; }
if grep -qE '^public func HG_DebugLogging\(\) -> Bool = true' "$SRC/HairGridInfo.reds"; then
    echo "refusing to package: HG_DebugLogging() is true" >&2
    exit 1
fi

OUT="$ROOT/dist/HairGrid-$VERSION.zip"
mkdir -p "$ROOT/dist"
rm -f "$OUT"

python3 - "$ROOT/src" "$MOD_REL" "$OUT" <<'EOF'
import sys, zipfile, pathlib
src, rel, out = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
files = sorted((src / rel).glob("*.reds"))
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for f in files:
        z.write(f, f.relative_to(src).as_posix())
EOF

# ---- verify the archive ----
fail() { echo "FAIL: $*" >&2; exit 1; }
listing="$(python3 -c 'import sys,zipfile; print("\n".join(zipfile.ZipFile(sys.argv[1]).namelist()))' "$OUT")"
[[ -n "$listing" ]] || fail "archive is empty"
while read -r entry; do
    [[ "$entry" == "$MOD_REL/"*.reds ]] || fail "unexpected entry '$entry' (everything must be $MOD_REL/*.reds)"
done <<< "$listing"
expected="$(cd "$ROOT/src" && ls "$MOD_REL"/*.reds | sort)"
[[ "$(sort <<< "$listing")" == "$expected" ]] || fail "archive contents differ from $SRC"

# Compile exactly what ships, as a user would have it: extracted files + Codeware.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
python3 -c 'import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$OUT" "$TMP/extract"
rs_compile "$CLI" "$TMP/log" -s "$TMP/extract/r6/scripts" -s "$GAME/red4ext/plugins/Codeware/Scripts" \
    -b "$GAME/r6/cache/final.redscripts" -o "$TMP/final.redscripts" \
    || { cat "$TMP/log"; fail "packaged scripts do not compile"; }

echo "OK: $OUT ($(wc -l <<< "$listing") files, $(du -h "$OUT" | cut -f1))"
sed 's/^/  /' <<< "$listing"
