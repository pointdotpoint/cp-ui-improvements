// Which character-creator rows get a grid, and how to read their entries.
// Rows are either switchers (gameuiSwitcherInfo.options) or morphs (gameuiMorphInfo.morphNames);
// both use the vanilla 'Selector' row, so the gallery restyle works for either.
module CPUIImprovements.CharacterCreator

// The single list of rows that get a grid (their uiSlot names).
public func CCUI_IsGridSlot(uiSlot: CName) -> Bool {
    return Equals(uiSlot, n"hairstyle")
        || Equals(uiSlot, n"mouth")
        || Equals(uiSlot, n"nose")
        || Equals(uiSlot, n"jaw")
        || Equals(uiSlot, n"ear")
        || Equals(uiSlot, n"cyberware_switcher")
        || Equals(uiSlot, n"facial_tattoo_switcher")
        || Equals(uiSlot, n"piercings")
        || Equals(uiSlot, n"makeupEyes");
}

public func CCUI_EntryCount(info: ref<gameuiCharacterCustomizationInfo>) -> Int32 {
    let switcher = info as gameuiSwitcherInfo;
    if IsDefined(switcher) {
        return ArraySize(switcher.options);
    }
    let morph = info as gameuiMorphInfo;
    if IsDefined(morph) {
        return ArraySize(morph.morphNames);
    }
    return 0;
}

// Internal name, stable across mod list changes (e.g. "wingdeer_bonnie_wa", "h_nose_03").
public func CCUI_EntryName(info: ref<gameuiCharacterCustomizationInfo>, i: Int32) -> CName {
    let switcher = info as gameuiSwitcherInfo;
    if IsDefined(switcher) && i >= 0 && i < ArraySize(switcher.options) {
        let names = switcher.options[i].names;
        return ArraySize(names) > 0 ? names[0] : StringToName(switcher.options[i].localizedName);
    }
    let morph = info as gameuiMorphInfo;
    if IsDefined(morph) && i >= 0 && i < ArraySize(morph.morphNames) {
        return morph.morphNames[i].morphName;
    }
    return n"None";
}

// Display label, the same text the vanilla row shows.
public func CCUI_EntryLabel(info: ref<gameuiCharacterCustomizationInfo>, i: Int32) -> String {
    let raw = "";
    let switcher = info as gameuiSwitcherInfo;
    let morph = info as gameuiMorphInfo;
    if IsDefined(switcher) && i >= 0 && i < ArraySize(switcher.options) {
        raw = switcher.options[i].localizedName;
    } else if IsDefined(morph) && i >= 0 && i < ArraySize(morph.morphNames) {
        raw = morph.morphNames[i].localizedName;
    }
    let label = GetLocalizedText(raw);
    if StrLen(label) == 0 {
        label = raw;
    }
    if StrLen(label) == 0 {
        label = NameToString(CCUI_EntryName(info, i));
    }
    return label;
}

// Favorites are namespaced per category: "<uiSlot>:<internal name>".
public func CCUI_FavoriteKey(info: ref<gameuiCharacterCustomizationInfo>, i: Int32) -> CName {
    let name = CCUI_EntryName(info, i);
    if !IsNameValid(name) {
        return n"None";
    }
    return StringToName(NameToString(info.uiSlot) + ":" + NameToString(name));
}

// Grid title, e.g. "NOSE"; falls back to the option's internal name.
public func CCUI_Title(info: ref<gameuiCharacterCustomizationInfo>) -> String {
    let title = GetLocalizedText(info.localizedName);
    if StrLen(title) == 0 {
        title = NameToString(info.name);
    }
    return StrUpper(title);
}
