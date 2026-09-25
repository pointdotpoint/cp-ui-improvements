# Shared helpers for the check/package scripts. Source, don't run.
#
# redscript-cli 0.5.31 exits 0 even when compilation or linting fails,
# so success is judged by its output instead of the exit code.

# rs_compile <cli> <log> <compile args...>
# Runs a compile, writes the full output to <log>, fails unless the bundle was written.
rs_compile() {
    local cli="$1" log="$2"
    shift 2
    "$cli" compile "$@" > "$log" 2>&1
    local status=$?
    sed -i 's/\x1b\[[0-9;]*m//g' "$log"
    [[ $status -eq 0 ]] && grep -q "Output successfully saved" "$log"
}

# rs_lint <cli> <log> <lint args...>
rs_lint() {
    local cli="$1" log="$2"
    shift 2
    "$cli" lint "$@" > "$log" 2>&1
    local status=$?
    [[ $status -eq 0 ]] && grep -q "Lint successful" "$log"
}
