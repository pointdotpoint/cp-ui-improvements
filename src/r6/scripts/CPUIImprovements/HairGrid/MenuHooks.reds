// Hooks into the character creator appearance menu (also used by the in-game mirror/ripperdoc).
// Adds a "HAIR GRID" launcher that opens HairGridOverlay for the hairstyle option.
module CPUIImprovements.HairGrid
import Codeware.UI.*

@addField(characterCreationBodyMorphMenu)
private let m_hgOption: ref<CharacterCustomizationOption>;

@addField(characterCreationBodyMorphMenu)
private let m_hgOverlay: ref<HairGridOverlay>;

@addField(characterCreationBodyMorphMenu)
private let m_hgLauncher: wref<inkCanvas>;

@wrapMethod(characterCreationBodyMorphMenu)
public final func InitializeList() -> Void {
    this.m_hgOption = null;
    wrappedMethod();
    HG_Log(s"InitializeList done, hair option found: \(IsDefined(this.m_hgOption))");
    this.HG_EnsureUI();
    this.m_hgLauncher.SetVisible(IsDefined(this.m_hgOption));
    if !IsDefined(this.m_hgOption) {
        this.HG_Close();
    }
}

@wrapMethod(characterCreationBodyMorphMenu)
public final func CreateEntry(const option: ref<CharacterCustomizationOption>) -> wref<inkWidget> {
    let widget = wrappedMethod(option);
    HG_Log(s"entry name=\(NameToString(option.info.name)) uiSlot=\(NameToString(option.info.uiSlot)) type=\(NameToString(option.info.GetClassName())) curr=\(option.currIndex)");
    if Equals(option.info.uiSlot, n"hairstyle") && IsDefined(option.info as gameuiSwitcherInfo) {
        this.m_hgOption = option;
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
    let root = this.GetRootCompoundWidget();

    let launcher = new inkCanvas();
    launcher.SetName(n"HairGridLauncher");
    launcher.SetAnchor(inkEAnchor.TopCenter);
    launcher.SetAnchorPoint(new Vector2(0.5, 0.0));
    launcher.SetMargin(new inkMargin(0.0, 60.0, 0.0, 0.0));
    launcher.SetSize(new Vector2(380.0, 90.0));
    launcher.SetInteractive(true);

    let bg = new inkRectangle();
    bg.SetName(n"bg");
    bg.SetAnchor(inkEAnchor.Fill);
    bg.SetTintColor(HG_Color(0.12, 0.14, 0.18));
    bg.SetOpacity(0.9);
    bg.Reparent(launcher);

    let bar = new inkRectangle();
    bar.SetAnchor(inkEAnchor.BottomFillHorizontaly);
    bar.SetSize(new Vector2(100.0, 4.0));
    bar.SetTintColor(HG_Red());
    bar.Reparent(launcher);

    let label = HG_MakeText("HAIR GRID", 40, n"Semi-Bold", HG_Cyan());
    label.SetAnchor(inkEAnchor.Centered);
    label.SetAnchorPoint(new Vector2(0.5, 0.5));
    label.Reparent(launcher);

    launcher.RegisterToCallback(n"OnRelease", this, n"HG_OnLauncherRelease");
    launcher.RegisterToCallback(n"OnHoverOver", this, n"HG_OnLauncherHoverOver");
    launcher.RegisterToCallback(n"OnHoverOut", this, n"HG_OnLauncherHoverOut");
    launcher.Reparent(root);
    this.m_hgLauncher = launcher;

    // Added last so it draws above everything, launcher included.
    this.m_hgOverlay = HairGridOverlay.Create(this);
    this.m_hgOverlay.Reparent(root, this);

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

// Mirrors OnSliderChange: same camera/busy handling, same system call.
@addMethod(characterCreationBodyMorphMenu)
public func HG_Apply(index: Int32) {
    if !IsDefined(this.m_hgOption) {
        return;
    }
    HG_Log(s"apply #\(index) (busy=\(EnumInt(this.m_busySwitchingAppearance)))");
    if Equals(this.m_busySwitchingAppearance, BusySwitchingReason.AVAILABLE) {
        this.RequestCameraChange(this.GetSlotName(this.m_hgOption));
        this.m_busySwitchingAppearance = BusySwitchingReason.SWAPPING;
    }
    this.GetCharacterCustomizationSystem().ApplyChangeToOption(this.m_hgOption, Cast<Uint32>(index));
    this.PlaySound(n"Button", n"OnPress");
}

@addMethod(characterCreationBodyMorphMenu)
protected cb func HG_OnLauncherRelease(e: ref<inkPointerEvent>) -> Bool {
    if e.IsAction(n"click") {
        this.PlaySound(n"Button", n"OnPress");
        this.HG_Open();
    }
    e.Handle();
    return true;
}

@addMethod(characterCreationBodyMorphMenu)
protected cb func HG_OnLauncherHoverOver(e: ref<inkPointerEvent>) -> Bool {
    this.m_hgLauncher.GetWidget(n"bg").SetTintColor(HG_Color(0.22, 0.26, 0.32));
    return false;
}

@addMethod(characterCreationBodyMorphMenu)
protected cb func HG_OnLauncherHoverOut(e: ref<inkPointerEvent>) -> Bool {
    this.m_hgLauncher.GetWidget(n"bg").SetTintColor(HG_Color(0.12, 0.14, 0.18));
    return false;
}
