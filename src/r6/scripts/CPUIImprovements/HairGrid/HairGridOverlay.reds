// Hair Grid overlay for the character creator.
// Paged grid of every hairstyle option; clicking a tile applies it through the menu.
module CPUIImprovements.HairGrid
import Codeware.UI.*

public func HG_Log(msg: String) {
    ModLog(n"HairGrid", msg);
}

public class HairGridOverlay extends inkCustomController {
    private let m_menu: wref<characterCreationBodyMorphMenu>;
    private let m_option: ref<CharacterCustomizationOption>;
    private let m_page: Int32;
    private let m_hovered: Int32;

    private let m_grid: wref<inkVerticalPanel>;
    private let m_info: wref<inkText>;
    private let m_tiles: array<wref<inkCanvas>>;

    private let m_cols: Int32;
    private let m_rows: Int32;
    private let m_tileW: Float;
    private let m_tileH: Float;
    private let m_gap: Float;

    public static func Create(menu: ref<characterCreationBodyMorphMenu>) -> ref<HairGridOverlay> {
        let self = new HairGridOverlay();
        self.m_menu = menu;
        self.m_hovered = -1;
        // Layout in the 3840x2160 authoring space the creator uses.
        self.m_cols = 4;
        self.m_rows = 8;
        self.m_tileW = 400.0;
        self.m_tileH = 140.0;
        self.m_gap = 16.0;
        self.CreateInstance();
        return self;
    }

    protected cb func OnCreate() {
        let root = new inkCanvas();
        root.SetName(n"HairGridOverlay");
        root.SetAnchor(inkEAnchor.Fill);
        root.SetVisible(false);

        // Swallows clicks so they don't reach the option list underneath.
        let backdrop = new inkRectangle();
        backdrop.SetName(n"backdrop");
        backdrop.SetAnchor(inkEAnchor.Fill);
        backdrop.SetTintColor(HG_Color(0.0, 0.0, 0.0));
        backdrop.SetOpacity(0.55);
        backdrop.SetInteractive(true);
        backdrop.RegisterToCallback(n"OnRelease", this, n"OnBackdropRelease");
        backdrop.Reparent(root);

        let contentW = Cast<Float>(this.m_cols) * this.m_tileW + Cast<Float>(this.m_cols - 1) * this.m_gap;

        let panel = new inkCanvas();
        panel.SetName(n"panel");
        panel.SetAnchor(inkEAnchor.CenterLeft);
        panel.SetAnchorPoint(new Vector2(0.0, 0.5));
        panel.SetMargin(new inkMargin(140.0, 0.0, 0.0, 0.0));
        panel.SetSize(new Vector2(contentW + 80.0, 1640.0));
        panel.SetInteractive(true);
        panel.Reparent(root);

        let panelBg = new inkRectangle();
        panelBg.SetAnchor(inkEAnchor.Fill);
        panelBg.SetTintColor(HG_Color(0.04, 0.05, 0.07));
        panelBg.SetOpacity(0.94);
        panelBg.Reparent(panel);

        let accent = new inkRectangle();
        accent.SetAnchor(inkEAnchor.TopFillHorizontaly);
        accent.SetSize(new Vector2(100.0, 4.0));
        accent.SetTintColor(HG_Red());
        accent.Reparent(panel);

        let content = new inkVerticalPanel();
        content.SetAnchor(inkEAnchor.Fill);
        content.SetMargin(new inkMargin(40.0, 36.0, 40.0, 36.0));
        content.Reparent(panel);

        // Header: title + page info
        let header = new inkHorizontalPanel();
        header.SetMargin(new inkMargin(0.0, 0.0, 0.0, 24.0));
        header.Reparent(content);

        let title = HG_MakeText("HAIRSTYLES", 56, n"Semi-Bold", HG_Red());
        title.SetLetterCase(textLetterCase.UpperCase);
        title.Reparent(header);

        let info = HG_MakeText("", 34, n"Medium", HG_Grey());
        info.SetMargin(new inkMargin(40.0, 14.0, 0.0, 0.0));
        info.Reparent(header);

        let grid = new inkVerticalPanel();
        grid.SetName(n"grid");
        grid.SetSize(new Vector2(contentW, Cast<Float>(this.m_rows) * (this.m_tileH + this.m_gap)));
        grid.Reparent(content);

        // Footer: paging + close
        let footer = new inkHorizontalPanel();
        footer.SetMargin(new inkMargin(0.0, 20.0, 0.0, 0.0));
        footer.Reparent(content);

        this.MakeButton("< PREV", n"OnPrevRelease").Reparent(footer);
        this.MakeButton("NEXT >", n"OnNextRelease").Reparent(footer);
        this.MakeButton("CLOSE", n"OnCloseRelease").Reparent(footer);

        this.m_grid = grid;
        this.m_info = info;

        this.SetRootWidget(root);
    }

    // ---- public API used by the menu ----

    public func IsOpen() -> Bool {
        return IsDefined(this.GetRootWidget()) && this.GetRootWidget().IsVisible();
    }

    public func Open(option: ref<CharacterCustomizationOption>) {
        this.m_option = option;
        let count = this.GetCount();
        HG_Log(s"open: \(count) options, current=\(this.GetCurrent())");
        if count <= 0 {
            return;
        }
        this.m_page = this.GetCurrent() / this.PageSize();
        this.Rebuild();
        this.GetRootWidget().SetVisible(true);
    }

    public func Close() {
        this.GetRootWidget().SetVisible(false);
        this.m_hovered = -1;
    }

    // Called when the system reports a new option state (after an apply).
    public func Refresh(option: ref<CharacterCustomizationOption>) {
        this.m_option = option;
        if this.IsOpen() {
            this.RestyleTiles();
            this.UpdateInfo();
        }
    }

    // ---- data helpers ----

    private func GetInfo() -> ref<gameuiSwitcherInfo> {
        if !IsDefined(this.m_option) {
            return null;
        }
        return this.m_option.info as gameuiSwitcherInfo;
    }

    private func GetCount() -> Int32 {
        let info = this.GetInfo();
        return IsDefined(info) ? ArraySize(info.options) : 0;
    }

    private func GetCurrent() -> Int32 {
        return IsDefined(this.m_option) ? Cast<Int32>(this.m_option.currIndex) : -1;
    }

    private func PageSize() -> Int32 {
        return this.m_cols * this.m_rows;
    }

    private func PageCount() -> Int32 {
        let count = this.GetCount();
        return count <= 0 ? 1 : (count - 1) / this.PageSize() + 1;
    }

    // ---- building ----

    private func Rebuild() {
        this.m_grid.RemoveAllChildren();
        ArrayClear(this.m_tiles);

        let info = this.GetInfo();
        let count = this.GetCount();
        let first = this.m_page * this.PageSize();
        let last = Min(first + this.PageSize(), count);

        let row: ref<inkHorizontalPanel>;
        let i = first;
        while i < last {
            if (i - first) % this.m_cols == 0 {
                row = new inkHorizontalPanel();
                row.SetMargin(new inkMargin(0.0, 0.0, 0.0, this.m_gap));
                row.Reparent(this.m_grid);
            }
            let tile = this.MakeTile(i, info.options[i]);
            tile.Reparent(row);
            ArrayPush(this.m_tiles, tile);
            i += 1;
        }

        this.RestyleTiles();
        this.UpdateInfo();
    }

    private func MakeTile(index: Int32, entry: gameuiSwitcherOption) -> ref<inkCanvas> {
        let tile = new inkCanvas();
        tile.SetName(StringToName(s"hair_tile_\(index)"));
        tile.SetSize(new Vector2(this.m_tileW, this.m_tileH));
        tile.SetMargin(new inkMargin(0.0, 0.0, this.m_gap, 0.0));
        tile.SetInteractive(true);

        let bg = new inkRectangle();
        bg.SetName(n"bg");
        bg.SetAnchor(inkEAnchor.Fill);
        bg.Reparent(tile);

        let bar = new inkRectangle();
        bar.SetName(n"bar");
        bar.SetAnchor(inkEAnchor.LeftFillVerticaly);
        bar.SetSize(new Vector2(6.0, 100.0));
        bar.Reparent(tile);

        let num = HG_MakeText(s"#\(index)", 26, n"Medium", HG_Grey());
        num.SetName(n"num");
        num.SetAnchor(inkEAnchor.TopLeft);
        num.SetMargin(new inkMargin(20.0, 10.0, 0.0, 0.0));
        num.Reparent(tile);

        let label = HG_MakeText(this.GetLabel(entry), 32, n"Semi-Bold", HG_White());
        label.SetName(n"label");
        label.SetAnchor(inkEAnchor.TopLeft);
        label.SetMargin(new inkMargin(20.0, 42.0, 12.0, 0.0));
        label.SetWrapping(true, this.m_tileW - 36.0);
        label.SetOverflowPolicy(textOverflowPolicy.DotsEnd);
        label.SetSize(new Vector2(this.m_tileW - 36.0, 44.0));
        label.Reparent(tile);

        // Internal name helps tell apart CCXL hairs that share a display name.
        let sub = HG_MakeText(ArraySize(entry.names) > 0 ? NameToString(entry.names[0]) : "", 22, n"Regular", HG_Grey());
        sub.SetName(n"sub");
        sub.SetAnchor(inkEAnchor.BottomLeft);
        sub.SetAnchorPoint(new Vector2(0.0, 1.0));
        sub.SetMargin(new inkMargin(20.0, 0.0, 12.0, 10.0));
        sub.SetOverflowPolicy(textOverflowPolicy.DotsEnd);
        sub.SetSize(new Vector2(this.m_tileW - 36.0, 28.0));
        sub.Reparent(tile);

        tile.RegisterToCallback(n"OnRelease", this, n"OnTileRelease");
        tile.RegisterToCallback(n"OnHoverOver", this, n"OnTileHoverOver");
        tile.RegisterToCallback(n"OnHoverOut", this, n"OnTileHoverOut");

        return tile;
    }

    private func GetLabel(entry: gameuiSwitcherOption) -> String {
        let label = GetLocalizedText(entry.localizedName);
        if StrLen(label) == 0 {
            label = entry.localizedName;
        }
        if StrLen(label) == 0 && ArraySize(entry.names) > 0 {
            label = NameToString(entry.names[0]);
        }
        return label;
    }

    private func RestyleTiles() {
        let current = this.GetCurrent();
        for tile in this.m_tiles {
            let index = HG_TileIndex(tile);
            let selected = index == current;
            let hovered = index == this.m_hovered;

            let bg = tile.GetWidget(n"bg");
            let bar = tile.GetWidget(n"bar");
            let label = tile.GetWidget(n"label");

            if selected {
                bg.SetTintColor(HG_Color(0.30, 0.08, 0.08));
                bar.SetTintColor(HG_Red());
                bar.SetOpacity(1.0);
                label.SetTintColor(HG_Cyan());
            } else if hovered {
                bg.SetTintColor(HG_Color(0.16, 0.18, 0.22));
                bar.SetTintColor(HG_Cyan());
                bar.SetOpacity(1.0);
                label.SetTintColor(HG_White());
            } else {
                bg.SetTintColor(HG_Color(0.09, 0.10, 0.13));
                bar.SetTintColor(HG_Grey());
                bar.SetOpacity(0.4);
                label.SetTintColor(HG_White());
            }
        }
    }

    private func UpdateInfo() {
        this.m_info.SetText(s"\(this.GetCount()) styles  ·  page \(this.m_page + 1)/\(this.PageCount())  ·  current #\(this.GetCurrent())");
    }

    private func MakeButton(text: String, callback: CName) -> ref<inkCanvas> {
        let btn = new inkCanvas();
        btn.SetSize(new Vector2(260.0, 80.0));
        btn.SetMargin(new inkMargin(0.0, 0.0, 24.0, 0.0));
        btn.SetInteractive(true);

        let bg = new inkRectangle();
        bg.SetName(n"bg");
        bg.SetAnchor(inkEAnchor.Fill);
        bg.SetTintColor(HG_Color(0.12, 0.14, 0.18));
        bg.Reparent(btn);

        let label = HG_MakeText(text, 34, n"Semi-Bold", HG_Cyan());
        label.SetAnchor(inkEAnchor.Centered);
        label.SetAnchorPoint(new Vector2(0.5, 0.5));
        label.Reparent(btn);

        btn.RegisterToCallback(n"OnRelease", this, callback);
        btn.RegisterToCallback(n"OnHoverOver", this, n"OnButtonHoverOver");
        btn.RegisterToCallback(n"OnHoverOut", this, n"OnButtonHoverOut");
        return btn;
    }

    // ---- callbacks ----

    protected cb func OnTileRelease(e: ref<inkPointerEvent>) -> Bool {
        if e.IsAction(n"click") {
            let index = HG_TileIndex(e.GetCurrentTarget());
            HG_Log(s"click tile #\(index)");
            if index >= 0 && IsDefined(this.m_menu) {
                this.m_menu.HG_Apply(index);
            }
        }
        e.Handle();
        return true;
    }

    protected cb func OnTileHoverOver(e: ref<inkPointerEvent>) -> Bool {
        this.m_hovered = HG_TileIndex(e.GetCurrentTarget());
        this.RestyleTiles();
        return false;
    }

    protected cb func OnTileHoverOut(e: ref<inkPointerEvent>) -> Bool {
        if this.m_hovered == HG_TileIndex(e.GetCurrentTarget()) {
            this.m_hovered = -1;
            this.RestyleTiles();
        }
        return false;
    }

    protected cb func OnButtonHoverOver(e: ref<inkPointerEvent>) -> Bool {
        (e.GetCurrentTarget() as inkCompoundWidget).GetWidget(n"bg").SetTintColor(HG_Color(0.22, 0.26, 0.32));
        return false;
    }

    protected cb func OnButtonHoverOut(e: ref<inkPointerEvent>) -> Bool {
        (e.GetCurrentTarget() as inkCompoundWidget).GetWidget(n"bg").SetTintColor(HG_Color(0.12, 0.14, 0.18));
        return false;
    }

    protected cb func OnPrevRelease(e: ref<inkPointerEvent>) -> Bool {
        if e.IsAction(n"click") {
            this.m_page = this.m_page > 0 ? this.m_page - 1 : this.PageCount() - 1;
            this.m_hovered = -1;
            this.Rebuild();
        }
        e.Handle();
        return true;
    }

    protected cb func OnNextRelease(e: ref<inkPointerEvent>) -> Bool {
        if e.IsAction(n"click") {
            this.m_page = this.m_page < this.PageCount() - 1 ? this.m_page + 1 : 0;
            this.m_hovered = -1;
            this.Rebuild();
        }
        e.Handle();
        return true;
    }

    protected cb func OnCloseRelease(e: ref<inkPointerEvent>) -> Bool {
        if e.IsAction(n"click") && IsDefined(this.m_menu) {
            this.m_menu.HG_Close();
        }
        e.Handle();
        return true;
    }

    protected cb func OnBackdropRelease(e: ref<inkPointerEvent>) -> Bool {
        e.Handle();
        return true;
    }
}

// ---- styling helpers ----

// Tiles are named "hair_tile_<index>".
public func HG_TileIndex(widget: wref<inkWidget>) -> Int32 {
    if !IsDefined(widget) {
        return -1;
    }
    let name = NameToString(widget.GetName());
    if !StrBeginsWith(name, "hair_tile_") {
        return -1;
    }
    return StringToInt(StrAfterFirst(name, "hair_tile_"), -1);
}

public func HG_Color(r: Float, g: Float, b: Float) -> HDRColor {
    return new HDRColor(r, g, b, 1.0);
}

public func HG_Red() -> HDRColor {
    return HG_Color(1.0, 0.38, 0.33);
}

public func HG_Cyan() -> HDRColor {
    return HG_Color(0.37, 0.96, 1.0);
}

public func HG_White() -> HDRColor {
    return HG_Color(0.92, 0.94, 0.96);
}

public func HG_Grey() -> HDRColor {
    return HG_Color(0.55, 0.58, 0.62);
}

public func HG_MakeText(text: String, size: Int32, style: CName, color: HDRColor) -> ref<inkText> {
    let t = new inkText();
    t.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    t.SetFontStyle(style);
    t.SetFontSize(size);
    t.SetTintColor(color);
    t.SetText(text);
    return t;
}
