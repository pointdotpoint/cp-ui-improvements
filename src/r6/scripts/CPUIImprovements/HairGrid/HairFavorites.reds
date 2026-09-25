// Favorite hairstyles, shared across all saves.
// Stored by the option's internal name (e.g. "wingdeer_bonnie_wa"), not its index,
// because indices shift whenever hair mods are added or removed.
// Persistence comes from Codeware: `persistent` fields of a ScriptableService are
// written to red4ext/plugins/Codeware/Persistent.
module CPUIImprovements.HairGrid

public class HairFavorites extends ScriptableService {
    private persistent let m_keys: array<CName>;

    public static func Get() -> ref<HairFavorites> {
        return GameInstance.GetScriptableServiceContainer()
            .GetService(n"CPUIImprovements.HairGrid.HairFavorites") as HairFavorites;
    }

    public func Has(key: CName) -> Bool {
        return IsNameValid(key) && ArrayContains(this.m_keys, key);
    }

    // Returns the new state.
    public func Toggle(key: CName) -> Bool {
        if !IsNameValid(key) {
            return false;
        }
        if ArrayContains(this.m_keys, key) {
            ArrayRemove(this.m_keys, key);
            return false;
        }
        ArrayPush(this.m_keys, key);
        return true;
    }

    public func Count() -> Int32 {
        return ArraySize(this.m_keys);
    }
}

// Stable identity for a hairstyle option.
public func HG_HairKey(entry: gameuiSwitcherOption) -> CName {
    if ArraySize(entry.names) > 0 {
        return entry.names[0];
    }
    return StringToName(entry.localizedName);
}
