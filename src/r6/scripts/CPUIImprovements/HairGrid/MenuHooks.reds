// Hooks into the character creator appearance menu (also used by the in-game mirror/ripperdoc).
// Gives the hairstyle row a vanilla-style grid button that opens HairGridOverlay.
module CPUIImprovements.HairGrid
import Codeware.UI.*

@addField(characterCreationBodyMorphMenu)
private let m_hgOption: wref<CharacterCustomizationOption>;

@addField(characterCreationBodyMorphMenu)
private let m_hgOverlay: ref<HairGridOverlay>;

@wrapMethod(characterCreationBodyMorphMenu)
public final func InitializeList() -> Void {
    this.m_hgOption = null;
    wrappedMethod();
    HG_Log(s"InitializeList done, hair option found: \(IsDefined(this.m_hgOption))");
    this.HG_EnsureUI();
    if !IsDefined(this.m_hgOption) {
        this.HG_Close();
    }
}

@wrapMethod(characterCreationBodyMorphMenu)
public final func CreateEntry(const option: ref<CharacterCustomizationOption>) -> wref<inkWidget> {
    let widget = wrappedMethod(option);
    if Equals(option.info.uiSlot, n"hairstyle") && IsDefined(option.info as gameuiSwitcherInfo) {
        this.m_hgOption = option;
        HG_Log(s"hairstyle option: \(ArraySize((option.info as gameuiSwitcherInfo).options)) styles, current=\(option.currIndex)");
        let row = widget.GetController() as characterCreationBodyMorphOption;
        if IsDefined(row) {
            row.HG_EnableGallery(this);
        }
    }
    return widget;
}

@wrapMethod(characterCreationBodyMorphMenu)
protected cb func OnOptionUpdated(evt: ref<gameuiCharacterCustomizationSystem_OnOptionUpdatedEvent>) -> Bool {
    let result = wrappedMethod(evt);
    if IsDefined(evt.option) && Equals(evt.option.info.uiSlot, n"hairstyle") {
        this.m_hgOption = evt.option;
        if IsDefined(this.m_hgOverlay) {
            this.m_hgOverlay.Refresh(this.m_hgOption);
        }
    }
    return result;
}

// While the grid is open, "back" closes it and confirm/randomize are swallowed
// so a click can't finish character creation or reroll the preset.
@wrapMethod(characterCreationBodyMorphMenu)
protected cb func OnButtonRelease(evt: ref<inkPointerEvent>) -> Bool {
    if this.HG_IsOpen() && !evt.IsHandled() {
        if evt.IsAction(n"back") {
            this.HG_Close();
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

@addMethod(characterCreationBodyMorphMenu)
private func HG_EnsureUI() {
    if IsDefined(this.m_hgOverlay) {
        return;
    }
    // Added to the menu root last so it draws above the option list.
    this.m_hgOverlay = HairGridOverlay.Create(this);
    this.m_hgOverlay.Reparent(this.GetRootCompoundWidget(), this);
    HG_Log("UI created");
}

@addMethod(characterCreationBodyMorphMenu)
public func HG_IsOpen() -> Bool {
    return IsDefined(this.m_hgOverlay) && this.m_hgOverlay.IsOpen();
}

@addMethod(characterCreationBodyMorphMenu)
public func HG_Open() {
    if !IsDefined(this.m_hgOption) || !IsDefined(this.m_hgOverlay) {
        HG_Log("open requested but no hair option");
        return;
    }
    this.m_hgOverlay.Open(this.m_hgOption);
    this.m_scrollController.SetInputDisabled(true);
    this.RequestCameraChange(this.GetSlotName(this.m_hgOption));
}

@addMethod(characterCreationBodyMorphMenu)
public func HG_Close() {
    if IsDefined(this.m_hgOverlay) && this.m_hgOverlay.IsOpen() {
        this.m_hgOverlay.Close();
        this.m_scrollController.SetInputDisabled(false);
    }
}

// Mirrors OnSliderChange: same camera/busy handling, same system call, same telemetry.
@addMethod(characterCreationBodyMorphMenu)
public func HG_Apply(index: Int32) {
    if !IsDefined(this.m_hgOption) {
        return;
    }
    let current = Cast<Int32>(this.m_hgOption.currIndex);
    HG_Log(s"apply #\(index) (current=\(current), busy=\(EnumInt(this.m_busySwitchingAppearance)), finalized=\(this.m_updatingFinalizedState))");
    if index == current {
        return;
    }
    if Equals(this.m_busySwitchingAppearance, BusySwitchingReason.AVAILABLE) {
        this.RequestCameraChange(this.GetSlotName(this.m_hgOption));
        this.m_busySwitchingAppearance = BusySwitchingReason.SWAPPING;
    }
    this.GetCharacterCustomizationSystem().ApplyChangeToOption(this.m_hgOption, Cast<Uint32>(index));
    this.GetTelemetrySystem().LogInitialChoiceOptionSelected(this.m_hgOption, Cast<Uint32>(index));
    this.PlaySound(n"Button", n"OnPress");
}

// ---- diagnostics for the confirm flow ----

@wrapMethod(characterCreationBodyMorphMenu)
public final func ConfirmCustomizedCharacter() -> Void {
    HG_Log(s"confirm (finalized=\(this.m_updatingFinalizedState), busy=\(EnumInt(this.m_busySwitchingAppearance)), gridOpen=\(this.HG_IsOpen()))");
    this.HG_Close();
    wrappedMethod();
}

@wrapMethod(characterCreationBodyMorphMenu)
protected cb func OnAppearanceAppliedEvent(evt: ref<gameuiCharacterCustomizationSystem_OnAppearanceAppliedEvent>) -> Bool {
    HG_Log(s"appearance applied (busy=\(EnumInt(this.m_busySwitchingAppearance)))");
    return wrappedMethod(evt);
}

@wrapMethod(characterCreationBodyMorphMenu)
protected cb func OnReFinalizeComplete(evt: ref<gameuiCharacterCustomizationSystem_OnReFinalizeStateCompleteEvent>) -> Bool {
    HG_Log("refinalize complete");
    return wrappedMethod(evt);
}

@wrapMethod(characterCreationBodyMorphMenu)
protected cb func OnCancelFinalizedStateUpdate(evt: ref<gameuiCharacterCustomizationSystem_OnCancelFinalizedStateUpdateEvent>) -> Bool {
    HG_Log("refinalize cancelled");
    return wrappedMethod(evt);
}

@addMethod(characterCreationBodyMorphMenu)
protected cb func HG_OnGridButtonRelease(e: ref<inkPointerEvent>) -> Bool {
    if e.IsAction(n"click") {
        this.PlaySound(n"Button", n"OnPress");
        this.HG_Open();
        e.Handle();
        return true;
    }
    return false;
}
