// Version and logging for Hair Grid.
// scripts/package.sh reads HG_Version() to name the release archive.
module CPUIImprovements.HairGrid

public func HG_Version() -> String = "1.0.0"

// Flip to true for verbose [HairGrid] lines (clicks, applies, confirm flow)
// in bin/x64/plugins/cyber_engine_tweaks/gamelog.log.
public func HG_DebugLogging() -> Bool = false

// Verbose diagnostics; silent unless HG_DebugLogging() is on.
public func HG_Log(msg: String) {
    if HG_DebugLogging() {
        ModLog(n"HairGrid", msg);
    }
}

// Always written: startup line and anything a bug report needs.
public func HG_Info(msg: String) {
    ModLog(n"HairGrid", msg);
}
