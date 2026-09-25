// Favorite grid entries, shared across all saves.
// Keys are "<uiSlot>:<stable name>" (see CCUI_FavoriteKey), so favorites are per category
// and survive hair/tattoo mods being added or removed, which shifts indices.
// Persistence comes from Codeware: `persistent` fields of a ScriptableService are
// written to red4ext/plugins/Codeware/Persistent.
module CPUIImprovements.CharacterCreator

public class OptionFavorites extends ScriptableService {
    private persistent let m_keys: array<CName>;

    public static func Get() -> ref<OptionFavorites> {
        return GameInstance.GetScriptableServiceContainer()
            .GetService(n"CPUIImprovements.CharacterCreator.OptionFavorites") as OptionFavorites;
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

    // Favorites in one category (uiSlot).
    public func CountFor(slot: CName) -> Int32 {
        let prefix = NameToString(slot) + ":";
        let n = 0;
        for key in this.m_keys {
            if StrBeginsWith(NameToString(key), prefix) {
                n += 1;
            }
        }
        return n;
    }
}
