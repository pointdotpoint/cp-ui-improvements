// Version and logging for Character Creator UI Improvements.
// scripts/package.sh reads CCUI_Version() to name the release archive.
module CPUIImprovements.CharacterCreator

public func CCUI_Version() -> String = "1.0.0"

// Flip to true for verbose [CCUIImprovements] lines (opens, clicks, applies, confirm flow)
// in bin/x64/plugins/cyber_engine_tweaks/gamelog.log.
public func CCUI_DebugLogging() -> Bool = false

// Verbose diagnostics; silent unless CCUI_DebugLogging() is on.
public func CCUI_Log(msg: String) {
    if CCUI_DebugLogging() {
        ModLog(n"CCUIImprovements", msg);
    }
}

// Always written: startup line and anything a bug report needs.
public func CCUI_Info(msg: String) {
    ModLog(n"CCUIImprovements", msg);
}
