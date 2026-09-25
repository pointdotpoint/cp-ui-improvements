// Minimize rarely-changed rows (voice tone, teeth, ...) to a bare one-line name/value line.
// Works on every row the appearance menu builds: 'Selector' rows, 'ColorPicker' rows and
// the voice tone 'VoiceOverSwitcher'. All three share the same layout: a 'TextHolder'
// with the name/value, plus frame, arrows and hit areas around it.
//
// Collapsing fades the other children out instead of hiding them, because vanilla calls
// SetVisible(true) on them (e.g. the arrows in RefreshView) and would undo a hide.
// They're also made non-interactive so invisible arrows can't change the value.
module CPUIImprovements.CharacterCreator
import Codeware.UI.*

// Which rows are minimized; shared across saves (Codeware persistent service).
public class RowLayoutStore extends ScriptableService {
    private persistent let m_minimized: array<CName>;

    public static func Get() -> ref<RowLayoutStore> {
        return GameInstance.GetScriptableServiceContainer()
            .GetService(n"CPUIImprovements.CharacterCreator.RowLayoutStore") as RowLayoutStore;
    }

    public func IsMinimized(key: CName) -> Bool {
        return ArrayContains(this.m_minimized, key);
    }

    public func SetMinimized(key: CName, minimized: Bool) {
        if minimized && !ArrayContains(this.m_minimized, key) {
            ArrayPush(this.m_minimized, key);
        } else if !minimized {
            ArrayRemove(this.m_minimized, key);
        }
    }
}

struct CCUI_SavedChild {
    let widget: wref<inkWidget>;
    let opacity: Float;
    let interactive: Bool;
}

public class OptionRowCollapser extends IScriptable {
    private let m_root: wref<inkCompoundWidget>;
    private let m_text: wref<inkWidget>;
    private let m_key: CName;
    private let m_collapsed: Bool;

    private let m_origHeight: Float;
    private let m_origTextHeight: Float;
    private let m_origTextMargin: inkMargin;
    private let m_saved: array<CCUI_SavedChild>;

    private let m_toggle: wref<inkCanvas>;
    private let m_plusBar: wref<inkWidget>;

    // Collapsed height: just the name/value line, no frame or padding.
    private let m_collapsedHeight: Float;

    public static func Attach(row: wref<inkWidget>, key: CName) -> ref<OptionRowCollapser> {
        let root = row as inkCompoundWidget;
        let text = IsDefined(root) ? root.GetWidget(n"TextHolder") : null;
        if !IsDefined(text) || !IsNameValid(key) {
            return null;
        }
        let self = new OptionRowCollapser();
        self.m_root = root;
        self.m_text = text;
        self.m_key = key;
        self.m_origHeight = root.GetHeight();
        self.m_origTextHeight = text.GetHeight();
        self.m_origTextMargin = text.GetMargin();
        self.m_collapsedHeight = 60.0;
        self.Build();
        let store = RowLayoutStore.Get();
        self.Apply(IsDefined(store) && store.IsMinimized(key));
        return self;
    }

    private func Build() {
        // Make room left of the row name for the toggle.
        let label = (this.m_text as inkCompoundWidget).GetWidget(n"OptionsLabel");
        if IsDefined(label) {
            let m = label.GetMargin();
            label.SetMargin(inkMargin(m.left + 50.0, m.top, m.right, m.bottom));
        }

        // [–] / [+] toggle: a framed box with a horizontal bar, plus a vertical bar when collapsed.
        let toggle = new inkCanvas();
        toggle.SetName(n"ccuiToggle");
        toggle.SetAnchor(inkEAnchor.TopLeft);
        toggle.SetSize(Vector2(36.0, 36.0));
        toggle.SetInteractive(true);
        toggle.SetTintColor(CCUI_Red());
        toggle.SetOpacity(0.6);
        let hit = new inkRectangle();
        hit.SetAnchor(inkEAnchor.Fill);
        hit.SetOpacity(0.01);
        hit.Reparent(toggle);
        CCUI_AddFrame(toggle, CCUI_Red(), 2.0, 1.0);
        let minus = new inkRectangle();
        minus.SetAnchor(inkEAnchor.Centered);
        minus.SetAnchorPoint(Vector2(0.5, 0.5));
        minus.SetSize(Vector2(18.0, 3.0));
        minus.Reparent(toggle);
        let plus = new inkRectangle();
        plus.SetAnchor(inkEAnchor.Centered);
        plus.SetAnchorPoint(Vector2(0.5, 0.5));
        plus.SetSize(Vector2(3.0, 18.0));
        plus.Reparent(toggle);
        toggle.RegisterToCallback(n"OnRelease", this, n"OnToggleRelease");
        toggle.RegisterToCallback(n"OnHoverOver", this, n"OnToggleHoverOver");
        toggle.RegisterToCallback(n"OnHoverOut", this, n"OnToggleHoverOut");
        toggle.Reparent(this.m_root);

        this.m_toggle = toggle;
        this.m_plusBar = plus;
    }

    private func IsOwnWidget(w: wref<inkWidget>) -> Bool {
        return w == this.m_text || w == this.m_toggle;
    }

    public func Apply(collapsed: Bool) {
        this.m_collapsed = collapsed;
        let i = 0;
        let n = this.m_root.GetNumChildren();
        if collapsed {
            ArrayClear(this.m_saved);
            while i < n {
                let child = this.m_root.GetWidgetByIndex(i);
                if !this.IsOwnWidget(child) {
                    ArrayPush(this.m_saved, CCUI_SavedChild(child, child.GetOpacity(), child.IsInteractive()));
                    child.SetOpacity(0.0);
                    child.SetInteractive(false);
                }
                i += 1;
            }
            this.m_root.SetHeight(this.m_collapsedHeight);
            this.m_text.SetHeight(this.m_collapsedHeight);
            this.m_text.SetMargin(inkMargin(0.0, 0.0, 0.0, 0.0));
        } else {
            for saved in this.m_saved {
                if IsDefined(saved.widget) {
                    saved.widget.SetOpacity(saved.opacity);
                    saved.widget.SetInteractive(saved.interactive);
                }
            }
            ArrayClear(this.m_saved);
            this.m_root.SetHeight(this.m_origHeight);
            this.m_text.SetHeight(this.m_origTextHeight);
            this.m_text.SetMargin(this.m_origTextMargin);
        }
        this.m_plusBar.SetVisible(collapsed);

        // Vertically center the toggle on the name line. TextHolder is anchored
        // CenterFillHorizontaly, so its center is (height + top - bottom) / 2.
        let h = this.m_root.GetHeight();
        let m = this.m_text.GetMargin();
        let centerY = (h + m.top - m.bottom) / 2.0;
        this.m_toggle.SetMargin(inkMargin(30.0, centerY - 18.0, 0.0, 0.0));
    }

    protected cb func OnToggleRelease(e: ref<inkPointerEvent>) -> Bool {
        if e.IsAction(n"click") {
            this.Apply(!this.m_collapsed);
            let store = RowLayoutStore.Get();
            if IsDefined(store) {
                store.SetMinimized(this.m_key, this.m_collapsed);
            }
            CCUI_Log(s"row \(NameToString(this.m_key)) minimized=\(this.m_collapsed)");
        }
        e.Handle();
        return true;
    }

    protected cb func OnToggleHoverOver(e: ref<inkPointerEvent>) -> Bool {
        this.m_toggle.SetOpacity(1.0);
        return false;
    }

    protected cb func OnToggleHoverOut(e: ref<inkPointerEvent>) -> Bool {
        this.m_toggle.SetOpacity(0.6);
        return false;
    }
}

// ---- menu hooks ----

@addField(characterCreationBodyMorphMenu)
private let m_ccuiRows: array<ref<OptionRowCollapser>>;

@addMethod(characterCreationBodyMorphMenu)
private func CCUI_AttachCollapse(row: wref<inkWidget>, key: CName) {
    let collapser = OptionRowCollapser.Attach(row, key);
    if IsDefined(collapser) {
        ArrayPush(this.m_ccuiRows, collapser);
    }
}

// Other mods may replace this and skip creating the row (e.g. in mirrors), so only
// attach if a row was actually added and it really is the voice tone switcher.
@wrapMethod(characterCreationBodyMorphMenu)
public final func CreateVoiceOverSwitcher() -> Void {
    let before = inkCompoundRef.GetNumChildren(this.m_optionsList);
    wrappedMethod();
    let after = inkCompoundRef.GetNumChildren(this.m_optionsList);
    if after > before {
        let row = inkCompoundRef.GetWidgetByIndex(this.m_optionsList, after - 1);
        if IsDefined(row) && IsDefined(row.GetController() as characterCreationVoiceOverSwitcher) {
            this.CCUI_AttachCollapse(row, n"voice_tone");
        }
    }
}
