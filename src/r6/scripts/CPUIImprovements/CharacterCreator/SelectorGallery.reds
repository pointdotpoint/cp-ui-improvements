// Turns a "Selector" row (hairstyle, nose, tattoos, ...) into the vanilla gallery look
// used by Skin Tone / Hair Color: < [grid] > with a clickable middle button.
// Layout values come from the 'ColorPicker' library item in
// base\gameplay\gui\fullscreen\main_menu\character_creation_step_2.inkwidget.
module CPUIImprovements.CharacterCreator
import Codeware.UI.*

@addField(characterCreationBodyMorphOption)
private let m_ccuiGallery: Bool;

@addField(characterCreationBodyMorphOption)
private let m_ccuiGridHovered: Bool;

@addField(characterCreationBodyMorphOption)
private let m_ccuiMenu: wref<characterCreationBodyMorphMenu>;

@addMethod(characterCreationBodyMorphOption)
public func CCUI_EnableGallery(menu: ref<characterCreationBodyMorphMenu>) {
    if this.m_ccuiGallery {
        return;
    }
    this.m_ccuiGallery = true;
    this.m_ccuiMenu = menu;

    let root = this.GetRootCompoundWidget();
    let left = root.GetWidget(n"hitAreaLeft");
    let right = root.GetWidget(n"hitAreaRight");
    if IsDefined(left) {
        left.SetWidth(300.0);
    }
    if IsDefined(right) {
        right.SetWidth(310.0);
    }
    let arrows = root.GetWidget(n"arrows");
    if IsDefined(arrows) {
        arrows.SetMargin(inkMargin(0.0, 0.0, 0.0, 15.0));
    }

    let btn = new inkCanvas();
    btn.SetName(n"ccuiGridButton");
    btn.SetAnchor(inkEAnchor.BottomCenter);
    btn.SetAnchorPoint(Vector2(0.5, 1.0));
    btn.SetSize(Vector2(290.0, 72.0));
    btn.SetInteractive(true);

    // Near-invisible fill so the area is hit-testable; the grid glyph comes from the arrows texture.
    let hit = new inkRectangle();
    hit.SetAnchor(inkEAnchor.Fill);
    hit.SetOpacity(0.01);
    hit.Reparent(btn);

    btn.RegisterToCallback(n"OnRelease", this, n"CCUI_OnGridButtonRelease");
    btn.RegisterToCallback(n"OnHoverOver", this, n"CCUI_OnGridHoverOver");
    btn.RegisterToCallback(n"OnHoverOut", this, n"CCUI_OnGridHoverOut");
    btn.Reparent(root);

    this.CCUI_Remap();
}

// Opens the grid for this row's own option.
@addMethod(characterCreationBodyMorphOption)
protected cb func CCUI_OnGridButtonRelease(e: ref<inkPointerEvent>) -> Bool {
    if !e.IsAction(n"click") || !this.m_isVisible || !IsDefined(this.m_ccuiMenu) {
        return false;
    }
    this.PlaySound(n"Button", n"OnPress");
    this.m_ccuiMenu.CCUI_OpenFor(this.m_selectorOption);
    e.Handle();
    return true;
}

// Swap the textures vanilla just set (cell_option_* / arrow*) for the gallery variants.
@addMethod(characterCreationBodyMorphOption)
private func CCUI_Remap() {
    if !this.m_ccuiGallery {
        return;
    }
    if this.m_ccuiGridHovered && this.m_isVisible {
        inkImageRef.SetTexturePart(this.m_selectorTexture, n"cell_gallery_centre");
        inkImageRef.SetTexturePart(this.m_arrowsTexture, n"arrow_gal_centre");
        return;
    }
    let cell = NameToString(inkImageRef.GetTexturePart(this.m_selectorTexture));
    if StrBeginsWith(cell, "cell_option_") {
        inkImageRef.SetTexturePart(this.m_selectorTexture, StringToName("cell_gallery_" + StrAfterFirst(cell, "cell_option_")));
    }
    let arrow = inkImageRef.GetTexturePart(this.m_arrowsTexture);
    if Equals(arrow, n"arrows_idle") {
        inkImageRef.SetTexturePart(this.m_arrowsTexture, n"arrow_gal_idle");
    } else if Equals(arrow, n"arrow_left") {
        inkImageRef.SetTexturePart(this.m_arrowsTexture, n"arrow_gal_left");
    } else if Equals(arrow, n"arrow_right") {
        inkImageRef.SetTexturePart(this.m_arrowsTexture, n"arrow_gal_right");
    }
}

@addMethod(characterCreationBodyMorphOption)
protected cb func CCUI_OnGridHoverOver(e: ref<inkPointerEvent>) -> Bool {
    this.m_ccuiGridHovered = true;
    this.CCUI_Remap();
    return false;
}

@addMethod(characterCreationBodyMorphOption)
protected cb func CCUI_OnGridHoverOut(e: ref<inkPointerEvent>) -> Bool {
    this.m_ccuiGridHovered = false;
    if this.m_isVisible {
        inkImageRef.SetTexturePart(this.m_selectorTexture, n"cell_option_idle");
        inkImageRef.SetTexturePart(this.m_arrowsTexture, n"arrows_idle");
    }
    this.CCUI_Remap();
    return false;
}

@wrapMethod(characterCreationBodyMorphOption)
protected cb func OnHoverOverNext(e: ref<inkPointerEvent>) -> Bool {
    let r = wrappedMethod(e);
    this.CCUI_Remap();
    return r;
}

@wrapMethod(characterCreationBodyMorphOption)
protected cb func OnHoverOutNext(e: ref<inkPointerEvent>) -> Bool {
    let r = wrappedMethod(e);
    this.CCUI_Remap();
    return r;
}

@wrapMethod(characterCreationBodyMorphOption)
protected cb func OnHoverOverPrev(e: ref<inkPointerEvent>) -> Bool {
    let r = wrappedMethod(e);
    this.CCUI_Remap();
    return r;
}

@wrapMethod(characterCreationBodyMorphOption)
protected cb func OnHoverOutPrev(e: ref<inkPointerEvent>) -> Bool {
    let r = wrappedMethod(e);
    this.CCUI_Remap();
    return r;
}

@wrapMethod(characterCreationBodyMorphOption)
public final func SetInputDisabled(disabled: Bool) -> Void {
    wrappedMethod(disabled);
    this.CCUI_Remap();
}

@wrapMethod(characterCreationBodyMorphOption)
public final func RefreshView() -> Void {
    wrappedMethod();
    this.CCUI_Remap();
}
