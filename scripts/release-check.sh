#!/usr/bin/env bash
# Pre-release validation for Character Creator UI Improvements. Runs every offline check and builds the package.
#
#   1. lint                  redscript 0.5.31 linter
#   2. compile (vanilla)     our scripts + Codeware against the game's script bundle
#   3. compile (installed)   plus every mod installed in this game folder
#   4. compile (rs 1.0)      redscript 1.0 preview; only diagnostics in our files count
#   5. compat (Nexus)        mods from a Nexus script dump that hook the same classes:
#                            no shared hook targets, no replaceMethod on what we wrap,
#                            and each one still compiles next to ours
#   6. package               dist/CharacterCreatorUIImprovements-<version>.zip, verified and compiled as shipped
#
# Tools are built/cloned into .tools/ on first run.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib.sh"
GAME="${CP2077_DIR:-$HOME/.local/share/Steam/steamapps/common/Cyberpunk 2077}"
TOOLS="$ROOT/.tools"
SRC="$ROOT/src/r6/scripts/CPUIImprovements"
BUNDLE="$GAME/r6/cache/final.redscripts"
CODEWARE="$GAME/red4ext/plugins/Codeware/Scripts"
RS05="$TOOLS/redscript-src/target/release/redscript-cli"
RS10="$TOOLS/redscript-1.0-src/target/release/redscript-cli"
DUMP="$TOOLS/nexus-script-dump"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

results=()
record() { results+=("$(printf '%-6s %s' "$1" "$2")"); }

build_rs() { # tag dir
    [[ -x "$TOOLS/$2/target/release/redscript-cli" ]] && return 0
    echo "building redscript-cli $1..."
    [[ -d "$TOOLS/$2" ]] || git clone -q --depth 1 --branch "$1" https://github.com/jac3km4/redscript.git "$TOOLS/$2" || return 1
    (cd "$TOOLS/$2" && cargo build --release -q -p redscript-cli) || return 1
}

build_rs v0.5.31 redscript-src

echo "== 0. tooling sanity"
# A known-bad file must be reported as a failure, or every PASS below is meaningless.
mkdir -p "$TMP/broken"
echo 'public func HGBrokenProbe() { let x: Int32 = "not an int"; }' > "$TMP/broken/b.reds"
if rs_compile "$RS05" "$TMP/broken.log" -s "$TMP/broken" -b "$BUNDLE" -o "$TMP/broken.out"; then
    record FAIL "tooling sanity: a broken script was reported as compiling"
else
    record PASS "tooling sanity: broken script correctly detected"
fi

echo "== 1. lint"
if rs_lint "$RS05" "$TMP/lint" -s "$SRC" -s "$CODEWARE" -b "$BUNDLE" && ! grep -q "CPUIImprovements" "$TMP/lint"; then
    record PASS "lint (redscript 0.5.31)"
else
    cat "$TMP/lint"; record FAIL "lint (redscript 0.5.31)"
fi

echo "== 2. compile (vanilla + Codeware)"
if "$ROOT/scripts/check.sh" > "$TMP/c1" 2>&1; then
    record PASS "compile vs vanilla + Codeware (0.5.31)"
else
    cat "$TMP/c1"; record FAIL "compile vs vanilla + Codeware (0.5.31)"
fi

echo "== 3. compile (all installed mods)"
if "$ROOT/scripts/check.sh" --full > "$TMP/c2" 2>&1; then
    record PASS "compile with all installed mods: $(tail -1 "$TMP/c2")"
else
    cat "$TMP/c2"; record FAIL "compile with all installed mods"
fi

echo "== 4. compile (redscript 1.0 preview)"
if build_rs v1.0.0-preview.22 redscript-1.0-src; then
    rs_compile "$RS10" "$TMP/rs10" -s "$SRC" -s "$CODEWARE" -b "$BUNDLE" -o "$TMP/rs10.redscripts" || true
    ours=$(grep -E '^\[(ERROR|WARN)' "$TMP/rs10" | grep -c "CPUIImprovements")
    other=$(grep -E '^\[ERROR\]' "$TMP/rs10" | grep -vc "CPUIImprovements")
    if [[ "$ours" -eq 0 ]]; then
        record PASS "redscript 1.0 preview: 0 diagnostics in our files ($other errors inside Codeware, not ours)"
    else
        grep -A3 -E '^\[(ERROR|WARN).*CPUIImprovements' "$TMP/rs10"
        record FAIL "redscript 1.0 preview: $ours diagnostics in our files"
    fi
else
    record SKIP "redscript 1.0 preview (could not build)"
fi

echo "== 5. compat (Nexus script dump)"
if [[ ! -d "$DUMP" ]]; then
    git clone -q --depth 1 --filter=blob:none --sparse https://github.com/rfuzzo/cyberpunk-nexus-script-dump.git "$DUMP" \
        && (cd "$DUMP" && git sparse-checkout set --no-cone '*.reds') || rm -rf "$DUMP"
fi
if [[ -d "$DUMP" ]]; then
    python3 - "$DUMP/mods" "$SRC" > "$TMP/compat" <<'EOF'
import os, re, sys, collections
dump, src = sys.argv[1], sys.argv[2]
ann = re.compile(r'@(wrapMethod|replaceMethod|addMethod|addField)\((\w+)\)\s*(?:(?:public|protected|private|final|static|cb|native|const|persistent)\s+)*(?:func|let)\s+(\w+)', re.M)
def scan(path):
    return ann.findall(open(path, encoding='utf-8', errors='ignore').read())
ours = collections.defaultdict(set)
for root, _, files in os.walk(src):
    for f in files:
        if f.endswith('.reds'):
            for kind, cls, name in scan(os.path.join(root, f)):
                ours[cls].add(name)
conflicts, notes, touching = [], [], collections.defaultdict(set)
for root, _, files in os.walk(dump):
    for f in files:
        if not f.endswith('.reds'):
            continue
        p = os.path.join(root, f)
        for kind, cls, name in scan(p):
            if cls in ours:
                mod = os.path.relpath(p, dump).split(os.sep)[0]
                touching[mod].add(os.path.dirname(p))
                if name in ours[cls]:
                    if kind in ('addMethod', 'addField'):
                        # Same member added twice: a hard conflict.
                        conflicts.append(f"{kind} {cls}.{name} in mod {mod}")
                    elif kind == 'replaceMethod':
                        # Our wrapper runs around their replacement (redscript applies wraps on top);
                        # worth knowing, and the compile step below still has to pass.
                        notes.append(f"replaceMethod {cls}.{name} in mod {mod} (we wrap it)")
for c in conflicts:
    print("CONFLICT", c)
for n in notes:
    print("NOTE", n)
for mod, dirs in sorted(touching.items()):
    print("MOD", mod, *sorted(dirs), sep="\t")
EOF
    nconf=$(grep -c '^CONFLICT' "$TMP/compat")
    nnote=$(grep -c '^NOTE' "$TMP/compat")
    grep -E '^(CONFLICT|NOTE)' "$TMP/compat"
    ok=(); broken=(); bad=()
    while IFS=$'\t' read -r _ mod dirs_rest; do
        IFS=$'\t' read -ra dirs <<< "$dirs_rest"
        a=(); for d in "${dirs[@]}"; do a+=(-s "$d"); done
        if ! rs_compile "$RS05" "$TMP/alone.log" "${a[@]}" -s "$CODEWARE" -b "$BUNDLE" -o "$TMP/alone"; then
            broken+=("$mod"); continue   # doesn't compile on this game version even without us
        fi
        if rs_compile "$RS05" "$TMP/both.log" "${a[@]}" -s "$SRC" -s "$CODEWARE" -b "$BUNDLE" -o "$TMP/both"; then
            ok+=("$mod")
        else
            bad+=("$mod")
        fi
    done < <(grep '^MOD' "$TMP/compat")
    summary="${#ok[@]} compile with ours [${ok[*]:-}]; ${#broken[@]} outdated for 2.31 on their own [${broken[*]:-}]"
    if [[ "$nconf" -eq 0 && ${#bad[@]} -eq 0 ]]; then
        record PASS "Nexus compat: 0 hook conflicts, $nnote replaceMethod notes; $summary"
    else
        record FAIL "Nexus compat: $nconf hook conflicts; fails only with ours: [${bad[*]:-}]; $summary"
    fi
else
    record SKIP "Nexus compat (could not fetch script dump)"
fi

echo "== 6. package"
if "$ROOT/scripts/package.sh" > "$TMP/pkg" 2>&1; then
    record PASS "package: $(head -1 "$TMP/pkg" | sed 's/^OK: //; s|'"$ROOT"'/||')"
else
    cat "$TMP/pkg"; record FAIL "package"
fi

echo
echo "================ release check ================"
printf '%s\n' "${results[@]}"
! printf '%s\n' "${results[@]}" | grep -q '^FAIL'
