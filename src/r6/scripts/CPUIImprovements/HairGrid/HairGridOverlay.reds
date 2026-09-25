// Hair Grid overlay for the character creator.
// Paged grid of every hairstyle option; clicking a tile applies it through the menu.
module CPUIImprovements.HairGrid
import Codeware.UI.*

public func HG_Log(msg: String) {
    ModLog(n"HairGrid", msg);
}

public class HairGridOverlay extends inkCustomController {
    private let m_menu: wref<characterCreationBodyMorphMenu>;
    private let m_option: wref<CharacterCustomizationOption>;
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
        self.m_cols = 3;
        self.m_rows = 9;
        self.m_tileW = 400.0;
        self.m_tileH = 120.0;
        self.m_gap = 14.0;
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
        backdrop.SetTintColor(HG_Black());
        backdrop.SetOpacity(0.45);
        backdrop.SetInteractive(true);
        backdrop.RegisterToCallback(n"OnRelease", this, n"OnBackdropRelease");
        backdrop.Reparent(root);

        let contentW = Cast<Float>(this.m_cols) * this.m_tileW + Cast<Float>(this.m_cols - 1) * this.m_gap;
        let gridH = Cast<Float>(this.m_rows) * (this.m_tileH + this.m_gap);
        let panelW = contentW + 80.0;
        // Header (~110) + grid + footer (~110) + padding (72).
        let panelH = 110.0 + gridH + 110.0 + 72.0;

        // Right side, over the option list, below "CUSTOMIZE YOUR LOOK" and above BACK/CONFIRM.
        let panel = new inkCanvas();
        panel.SetName(n"panel");
        panel.SetAnchor(inkEAnchor.TopRight);
        panel.SetAnchorPoint(new Vector2(1.0, 0.0));
        panel.SetMargin(new inkMargin(0.0, 250.0, 110.0, 0.0));
        panel.SetSize(new Vector2(panelW, panelH));
        panel.SetInteractive(true);
        panel.Reparent(root);

        let panelBg = new inkRectangle();
        panelBg.SetAnchor(inkEAnchor.Fill);
        panelBg.SetTintColor(HG_PanelBg());
        panelBg.SetOpacity(0.96);
        panelBg.Reparent(panel);

        HG_AddFrame(panel, HG_MildRed(), 2.0, 0.8);

        let accent = new inkRectangle();
        accent.SetAnchor(inkEAnchor.TopFillHorizontaly);
        accent.SetSize(new Vector2(100.0, 5.0));
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

        let info = HG_MakeText("", 32, n"Medium", HG_MildRed());
        info.SetMargin(new inkMargin(36.0, 16.0, 0.0, 0.0));
        info.Reparent(header);

        let grid = new inkVerticalPanel();
        grid.SetName(n"grid");
        grid.SetSize(new Vector2(contentW, gridH));
        grid.Reparent(content);

        // Footer: paging + close
        let footer = new inkHorizontalPanel();
        footer.SetMargin(new inkMargin(0.0, 16.0, 0.0, 0.0));
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

    public func Open(option: wref<CharacterCustomizationOption>) {
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
    public func Refresh(option: wref<CharacterCustomizationOption>) {
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
        let textW = this.m_tileW - 40.0;

        let tile = new inkCanvas();
        tile.SetName(StringToName(s"hair_tile_\(index)"));
        tile.SetSize(new Vector2(this.m_tileW, this.m_tileH));
        tile.SetMargin(new inkMargin(0.0, 0.0, this.m_gap, 0.0));
        tile.SetInteractive(true);

        let bg = new inkRectangle();
        bg.SetName(n"bg");
        bg.SetAnchor(inkEAnchor.Fill);
        bg.Reparent(tile);

        let frame = HG_AddFrame(tile, HG_MildRed(), 2.0, 0.7);
        frame.SetName(n"frame");

        let bar = new inkRectangle();
        bar.SetName(n"bar");
        bar.SetAnchor(inkEAnchor.LeftFillVerticaly);
        bar.SetSize(new Vector2(6.0, 100.0));
        bar.Reparent(tile);

        // Up to two lines, clipped with an ellipsis on the second.
        let label = HG_MakeText(HG_Ellipsize(this.GetLabel(entry), 50), 30, n"Semi-Bold", HG_Red());
        label.SetName(n"label");
        label.SetAnchor(inkEAnchor.TopLeft);
        label.SetMargin(new inkMargin(20.0, 10.0, 0.0, 0.0));
        label.SetFitToContent(false);
        label.SetSize(new Vector2(textW, 72.0));
        label.SetWrapping(true, textW);
        label.SetOverflowPolicy(textOverflowPolicy.DotsEndLastLine);
        label.Reparent(tile);

        // Index + internal name help tell apart CCXL hairs that share a display name.
        let internal = ArraySize(entry.names) > 0 ? NameToString(entry.names[0]) : "";
        let sub = HG_MakeText(HG_Ellipsize(s"#\(index)  \(internal)", 36), 22, n"Regular", HG_MildRed());
        sub.SetName(n"sub");
        sub.SetAnchor(inkEAnchor.BottomLeft);
        sub.SetAnchorPoint(new Vector2(0.0, 1.0));
        sub.SetMargin(new inkMargin(20.0, 0.0, 0.0, 8.0));
        sub.SetFitToContent(false);
        sub.SetSize(new Vector2(textW, 28.0));
        sub.SetOverflowPolicy(textOverflowPolicy.DotsEnd);
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

    // Vanilla option-row look: dark red fill, red frame and text; the active value is cyan.
    private func RestyleTiles() {
        let current = this.GetCurrent();
        for tile in this.m_tiles {
            let index = HG_TileIndex(tile);
            let selected = index == current;
            let hovered = index == this.m_hovered;

            let bg = tile.GetWidget(n"bg");
            let frame = tile.GetWidget(n"frame");
            let bar = tile.GetWidget(n"bar");
            let label = tile.GetWidget(n"label");
            let sub = tile.GetWidget(n"sub");

            if selected {
                bg.SetTintColor(HG_FaintBlue());
                bg.SetOpacity(0.9);
                frame.SetTintColor(HG_Blue());
                frame.SetOpacity(1.0);
                bar.SetTintColor(HG_Blue());
                bar.SetOpacity(1.0);
                label.SetTintColor(HG_Blue());
                sub.SetTintColor(HG_MildBlue());
            } else if hovered {
                bg.SetTintColor(HG_HoverRed());
                bg.SetOpacity(0.9);
                frame.SetTintColor(HG_Red());
                frame.SetOpacity(1.0);
                bar.SetTintColor(HG_Red());
                bar.SetOpacity(1.0);
                label.SetTintColor(HG_ActiveRed());
                sub.SetTintColor(HG_Red());
            } else {
                bg.SetTintColor(HG_DarkRed());
                bg.SetOpacity(0.55);
                frame.SetTintColor(HG_MildRed());
                frame.SetOpacity(0.7);
                bar.SetTintColor(HG_MildRed());
                bar.SetOpacity(0.6);
                label.SetTintColor(HG_Red());
                sub.SetTintColor(HG_MildRed());
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
        bg.SetTintColor(HG_DarkRed());
        bg.SetOpacity(0.8);
        bg.Reparent(btn);

        let frame = HG_AddFrame(btn, HG_Red(), 2.0, 0.8);
        frame.SetName(n"frame");

        let label = HG_MakeText(text, 34, n"Semi-Bold", HG_Red());
        label.SetName(n"label");
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
        let btn = e.GetCurrentTarget() as inkCompoundWidget;
        btn.GetWidget(n"bg").SetTintColor(HG_HoverRed());
        btn.GetWidget(n"frame").SetOpacity(1.0);
        btn.GetWidget(n"label").SetTintColor(HG_ActiveRed());
        return false;
    }

    protected cb func OnButtonHoverOut(e: ref<inkPointerEvent>) -> Bool {
        let btn = e.GetCurrentTarget() as inkCompoundWidget;
        btn.GetWidget(n"bg").SetTintColor(HG_DarkRed());
        btn.GetWidget(n"frame").SetOpacity(0.8);
        btn.GetWidget(n"label").SetTintColor(HG_Red());
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

// ---- helpers ----

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

// Hard cap as a backstop in case the engine's overflow policy doesn't clip.
public func HG_Ellipsize(text: String, maxChars: Int32) -> String {
    if StrLen(text) <= maxChars {
        return text;
    }
    return StrLeft(text, maxChars - 3) + "...";
}

// 1px-style outline made of four edges; returned canvas is named by the caller.
public func HG_AddFrame(parent: ref<inkCompoundWidget>, color: HDRColor, thickness: Float, opacity: Float) -> ref<inkCanvas> {
    let frame = new inkCanvas();
    frame.SetAnchor(inkEAnchor.Fill);
    frame.SetTintColor(color);
    frame.SetOpacity(opacity);

    let top = new inkRectangle();
    top.SetAnchor(inkEAnchor.TopFillHorizontaly);
    top.SetSize(new Vector2(100.0, thickness));
    top.Reparent(frame);

    let bottom = new inkRectangle();
    bottom.SetAnchor(inkEAnchor.BottomFillHorizontaly);
    bottom.SetSize(new Vector2(100.0, thickness));
    bottom.Reparent(frame);

    let left = new inkRectangle();
    left.SetAnchor(inkEAnchor.LeftFillVerticaly);
    left.SetSize(new Vector2(thickness, 100.0));
    left.Reparent(frame);

    let right = new inkRectangle();
    right.SetAnchor(inkEAnchor.RightFillVerticaly);
    right.SetSize(new Vector2(thickness, 100.0));
    right.Reparent(frame);

    frame.Reparent(parent);
    return frame;
}

// Palette from base\gameplay\gui\common\main_colors.inkstyle (MainColors.*).
public func HG_Red() -> HDRColor = new HDRColor(1.176, 0.381, 0.348, 1.0)
public func HG_ActiveRed() -> HDRColor = new HDRColor(1.370, 0.444, 0.405, 1.0)
public func HG_MildRed() -> HDRColor = new HDRColor(0.682, 0.231, 0.212, 1.0)
public func HG_DarkRed() -> HDRColor = new HDRColor(0.263, 0.086, 0.094, 1.0)
public func HG_HoverRed() -> HDRColor = new HDRColor(0.412, 0.086, 0.090, 1.0)  // Fullscreen_SecondaryBackground4
public func HG_PanelBg() -> HDRColor = new HDRColor(0.055, 0.035, 0.050, 1.0)   // near Fullscreen_PrimaryBackgroundDarkest, red-shifted
public func HG_Blue() -> HDRColor = new HDRColor(0.369, 0.965, 1.0, 1.0)
public func HG_MildBlue() -> HDRColor = new HDRColor(0.204, 0.569, 0.592, 1.0)
public func HG_FaintBlue() -> HDRColor = new HDRColor(0.090, 0.173, 0.180, 1.0)
public func HG_Black() -> HDRColor = new HDRColor(0.0, 0.0, 0.0, 1.0)

public func HG_Color(r: Float, g: Float, b: Float) -> HDRColor {
    return new HDRColor(r, g, b, 1.0);
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
