// Hooks into the character creator appearance menu (also used by mirrors and ripperdocs).
// Rows listed in GridTargets.reds get a vanilla-style grid button that opens OptionGridOverlay.
module CPUIImprovements.CharacterCreator
import Codeware.UI.*

// Every grid-enabled option currently in the list, refreshed as the system updates them.
@addField(characterCreationBodyMorphMenu)
private let m_ccuiOptions: array<wref<CharacterCustomizationOption>>;

// The option whose grid is open.
@addField(characterCreationBodyMorphMenu)
private let m_ccuiActive: wref<CharacterCustomizationOption>;

@addField(characterCreationBodyMorphMenu)
private let m_ccuiOverlay: ref<OptionGridOverlay>;

@wrapMethod(characterCreationBodyMorphMenu)
public final func InitializeList() -> Void {
    ArrayClear(this.m_ccuiOptions);
    ArrayClear(this.m_ccuiRows);
    wrappedMethod();
    CCUI_Log(s"InitializeList done, \(ArraySize(this.m_ccuiOptions)) grid rows");
    this.CCUI_EnsureUI();
    // The list was rebuilt; a grid left open would point at a stale option.
    this.CCUI_Close();
}

@wrapMethod(characterCreationBodyMorphMenu)
public final func CreateEntry(const option: ref<CharacterCustomizationOption>) -> wref<inkWidget> {
    let widget = wrappedMethod(option);
    if CCUI_IsGridSlot(option.info.uiSlot) && CCUI_EntryCount(option.info) > 1 {
        let row = widget.GetController() as characterCreationBodyMorphOption;
        if IsDefined(row) {
            ArrayPush(this.m_ccuiOptions, option);
            row.CCUI_EnableGallery(this);
            CCUI_Log(s"grid row \(NameToString(option.info.uiSlot)): \(CCUI_EntryCount(option.info)) entries, current=\(option.currIndex)");
        }
    }
    // Every row can be minimized; keyed by the option's internal name (unique, unlike uiSlot).
    this.CCUI_AttachCollapse(widget, option.info.name);
    return widget;
}

@wrapMethod(characterCreationBodyMorphMenu)
protected cb func OnOptionUpdated(evt: ref<gameuiCharacterCustomizationSystem_OnOptionUpdatedEvent>) -> Bool {
    let result = wrappedMethod(evt);
    if IsDefined(evt.option) && CCUI_IsGridSlot(evt.option.info.uiSlot) {
        let slot = evt.option.info.uiSlot;
        let i = 0;
        while i < ArraySize(this.m_ccuiOptions) {
            if IsDefined(this.m_ccuiOptions[i]) && Equals(this.m_ccuiOptions[i].info.uiSlot, slot) {
                this.m_ccuiOptions[i] = evt.option;
            }
            i += 1;
        }
        if IsDefined(this.m_ccuiActive) && Equals(this.m_ccuiActive.info.uiSlot, slot) {
            this.m_ccuiActive = evt.option;
            if IsDefined(this.m_ccuiOverlay) {
                this.m_ccuiOverlay.Refresh(evt.option);
            }
        }
    }
    return result;
}

// While a grid is open, "back" closes it and confirm/randomize are swallowed
// so a click can't finish character creation or reroll the preset.
@wrapMethod(characterCreationBodyMorphMenu)
protected cb func OnButtonRelease(evt: ref<inkPointerEvent>) -> Bool {
    if this.CCUI_IsOpen() && !evt.IsHandled() {
        if evt.IsAction(n"back") {
            this.CCUI_Close();
            evt.Handle();
            return true;
        }
        if evt.IsAction(n"one_click_confirm") || evt.IsAction(n"character_preview_randomize") {
            evt.Handle();
            return true;
        }
    }
    return wrappedMethod(evt);
}

// Close the grid before the game finalizes the character.
@wrapMethod(characterCreationBodyMorphMenu)
public final func ConfirmCustomizedCharacter() -> Void {
    CCUI_Log(s"confirm (finalized=\(this.m_updatingFinalizedState), busy=\(EnumInt(this.m_busySwitchingAppearance)), gridOpen=\(this.CCUI_IsOpen()))");
    this.CCUI_Close();
    wrappedMethod();
}

@addMethod(characterCreationBodyMorphMenu)
private func CCUI_EnsureUI() {
    if IsDefined(this.m_ccuiOverlay) {
        return;
    }
    // Added to the menu root last so it draws above the option list.
    this.m_ccuiOverlay = OptionGridOverlay.Create(this);
    this.m_ccuiOverlay.Reparent(this.GetRootCompoundWidget(), this);
    CCUI_Info(s"Character Creator UI Improvements \(CCUI_Version()) ready");
}

@addMethod(characterCreationBodyMorphMenu)
public func CCUI_IsOpen() -> Bool {
    return IsDefined(this.m_ccuiOverlay) && this.m_ccuiOverlay.IsOpen();
}

// Called by a row's grid button with that row's option.
@addMethod(characterCreationBodyMorphMenu)
public func CCUI_OpenFor(option: wref<CharacterCustomizationOption>) {
    if !IsDefined(option) || !IsDefined(this.m_ccuiOverlay) {
        CCUI_Log("open requested without an option");
        return;
    }
    // Prefer the freshest copy tracked for this slot.
    for tracked in this.m_ccuiOptions {
        if IsDefined(tracked) && Equals(tracked.info.uiSlot, option.info.uiSlot) {
            option = tracked;
        }
    }
    this.m_ccuiActive = option;
    this.m_ccuiOverlay.Open(option);
    this.m_scrollController.SetInputDisabled(true);
    this.RequestCameraChange(this.GetSlotName(option));
}

@addMethod(characterCreationBodyMorphMenu)
public func CCUI_Close() {
    if IsDefined(this.m_ccuiOverlay) && this.m_ccuiOverlay.IsOpen() {
        this.m_ccuiOverlay.Close();
        this.m_scrollController.SetInputDisabled(false);
    }
    this.m_ccuiActive = null;
}

// Mirrors OnSliderChange: same camera/busy handling, same system call, same telemetry.
@addMethod(characterCreationBodyMorphMenu)
public func CCUI_Apply(index: Int32) {
    let option = this.m_ccuiActive;
    if !IsDefined(option) {
        return;
    }
    let current = Cast<Int32>(option.currIndex);
    CCUI_Log(s"apply \(NameToString(option.info.uiSlot)) #\(index) (current=\(current), busy=\(EnumInt(this.m_busySwitchingAppearance)), finalized=\(this.m_updatingFinalizedState))");
    if index == current {
        return;
    }
    if Equals(this.m_busySwitchingAppearance, BusySwitchingReason.AVAILABLE) {
        this.RequestCameraChange(this.GetSlotName(option));
        this.m_busySwitchingAppearance = BusySwitchingReason.SWAPPING;
    }
    this.GetCharacterCustomizationSystem().ApplyChangeToOption(option, Cast<Uint32>(index));
    this.GetTelemetrySystem().LogInitialChoiceOptionSelected(option, Cast<Uint32>(index));
    this.PlaySound(n"Button", n"OnPress");
}
