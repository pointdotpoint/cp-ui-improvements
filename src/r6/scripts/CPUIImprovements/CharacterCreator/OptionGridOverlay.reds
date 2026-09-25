// Grid overlay for one character-creator option (hairstyle, nose, tattoos, ...).
// Paged grid of every entry; clicking a tile applies it through the menu, the star favorites it.
module CPUIImprovements.CharacterCreator
import Codeware.UI.*

public class OptionGridOverlay extends inkCustomController {
    private let m_menu: wref<characterCreationBodyMorphMenu>;
    private let m_option: wref<CharacterCustomizationOption>;
    private let m_page: Int32;
    private let m_hovered: Int32;

    private let m_grid: wref<inkVerticalPanel>;
    private let m_title: wref<inkText>;
    private let m_info: wref<inkText>;
    private let m_toast: wref<inkHorizontalPanel>;
    private let m_firstBtn: wref<inkCanvas>;
    private let m_lastBtn: wref<inkCanvas>;
    private let m_prevBtn: wref<inkCanvas>;
    private let m_nextBtn: wref<inkCanvas>;
    private let m_favBtn: wref<inkCanvas>;
    private let m_toastIcon: wref<inkImage>;
    private let m_toastText: wref<inkText>;
    private let m_tiles: array<wref<inkCanvas>>;
    // Display order: favorites first (in list order), then the rest.
    private let m_order: array<Int32>;

    private let m_cols: Int32;
    private let m_rows: Int32;
    private let m_tileW: Float;
    private let m_tileH: Float;
    private let m_gap: Float;

    public static func Create(menu: ref<characterCreationBodyMorphMenu>) -> ref<OptionGridOverlay> {
        let self = new OptionGridOverlay();
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
        root.SetName(n"CCUIOptionGrid");
        root.SetAnchor(inkEAnchor.Fill);
        root.SetVisible(false);

        // Swallows clicks so they don't reach the option list underneath.
        let backdrop = new inkRectangle();
        backdrop.SetName(n"backdrop");
        backdrop.SetAnchor(inkEAnchor.Fill);
        backdrop.SetTintColor(CCUI_Black());
        backdrop.SetOpacity(0.45);
        backdrop.SetInteractive(true);
        backdrop.RegisterToCallback(n"OnRelease", this, n"OnBackdropRelease");
        backdrop.Reparent(root);

        let contentW = Cast<Float>(this.m_cols) * this.m_tileW + Cast<Float>(this.m_cols - 1) * this.m_gap;
        let gridH = Cast<Float>(this.m_rows) * (this.m_tileH + this.m_gap);
        let panelW = contentW + 80.0;
        // Header (~110) + grid + toast line (~60) + footer (~110) + padding (72).
        let panelH = 110.0 + gridH + 60.0 + 110.0 + 72.0;

        // Right side, over the option list, below "CUSTOMIZE YOUR LOOK" and above BACK/CONFIRM.
        let panel = new inkCanvas();
        panel.SetName(n"panel");
        panel.SetAnchor(inkEAnchor.TopRight);
        panel.SetAnchorPoint(Vector2(1.0, 0.0));
        panel.SetMargin(inkMargin(0.0, 250.0, 110.0, 0.0));
        panel.SetSize(Vector2(panelW, panelH));
        panel.SetInteractive(true);
        panel.Reparent(root);

        let panelBg = new inkRectangle();
        panelBg.SetAnchor(inkEAnchor.Fill);
        panelBg.SetTintColor(CCUI_PanelBg());
        panelBg.SetOpacity(0.96);
        panelBg.Reparent(panel);

        CCUI_AddFrame(panel, CCUI_MildRed(), 2.0, 0.8);

        let accent = new inkRectangle();
        accent.SetAnchor(inkEAnchor.TopFillHorizontaly);
        accent.SetSize(Vector2(100.0, 5.0));
        accent.SetTintColor(CCUI_Red());
        accent.Reparent(panel);

        let content = new inkVerticalPanel();
        content.SetAnchor(inkEAnchor.Fill);
        content.SetMargin(inkMargin(40.0, 36.0, 40.0, 36.0));
        content.Reparent(panel);

        // Header: title + page info
        let header = new inkHorizontalPanel();
        header.SetMargin(inkMargin(0.0, 0.0, 0.0, 24.0));
        header.Reparent(content);

        let title = CCUI_MakeText("", 56, n"Semi-Bold", CCUI_Red());
        title.SetLetterCase(textLetterCase.UpperCase);
        title.Reparent(header);

        let info = CCUI_MakeText("", 32, n"Medium", CCUI_MildRed());
        info.SetMargin(inkMargin(36.0, 16.0, 0.0, 0.0));
        info.Reparent(header);

        let grid = new inkVerticalPanel();
        grid.SetName(n"grid");
        grid.SetSize(Vector2(contentW, gridH));
        grid.Reparent(content);

        // Toast line: favorite added/removed, fades out on its own.
        let toast = new inkHorizontalPanel();
        toast.SetName(n"toast");
        toast.SetSize(Vector2(contentW, 48.0));
        toast.SetMargin(inkMargin(0.0, 6.0, 0.0, 6.0));
        toast.SetOpacity(0.0);
        toast.Reparent(content);

        let toastIcon = new inkImage();
        toastIcon.SetAtlasResource(r"base\\gameplay\\gui\\common\\icons\\atlas_nameplate.inkatlas");
        toastIcon.SetTexturePart(n"icon_star");
        toastIcon.SetSize(Vector2(36.0, 36.0));
        toastIcon.SetVAlign(inkEVerticalAlign.Center);
        toastIcon.SetMargin(inkMargin(0.0, 0.0, 14.0, 0.0));
        toastIcon.Reparent(toast);

        let toastText = CCUI_MakeText("", 32, n"Medium", CCUI_Gold());
        toastText.SetVAlign(inkEVerticalAlign.Center);
        toastText.Reparent(toast);

        // Footer: paging + close
        let footer = new inkHorizontalPanel();
        footer.SetMargin(inkMargin(0.0, 16.0, 0.0, 0.0));
        footer.Reparent(content);

        // With more than two pages: FIRST ‹ › LAST; otherwise < PREV / NEXT > (see UpdatePaging).
        let firstBtn = this.MakeButton("FIRST", n"OnFirstRelease", 190.0);
        firstBtn.SetAffectsLayoutWhenHidden(false);
        firstBtn.Reparent(footer);
        let prevBtn = this.MakeButton("< PREV", n"OnPrevRelease", 200.0);
        CCUI_AddChevron(prevBtn, true);
        prevBtn.Reparent(footer);
        let nextBtn = this.MakeButton("NEXT >", n"OnNextRelease", 200.0);
        CCUI_AddChevron(nextBtn, false);
        nextBtn.Reparent(footer);
        let lastBtn = this.MakeButton("LAST", n"OnLastRelease", 190.0);
        lastBtn.SetAffectsLayoutWhenHidden(false);
        lastBtn.Reparent(footer);
        // Star: favorite/unfavorite the entry currently applied (see UpdateFavButton).
        let favBtn = this.MakeButton("", n"OnFavCurrentRelease", 90.0);
        let favStar = new inkImage();
        favStar.SetName(n"favStar");
        favStar.SetAtlasResource(r"base\\gameplay\\gui\\common\\icons\\atlas_nameplate.inkatlas");
        favStar.SetTexturePart(n"icon_star");
        favStar.SetAnchor(inkEAnchor.Centered);
        favStar.SetAnchorPoint(Vector2(0.5, 0.5));
        favStar.SetSize(Vector2(44.0, 44.0));
        favStar.Reparent(favBtn);
        favBtn.Reparent(footer);
        this.MakeButton("CLOSE", n"OnCloseRelease", 220.0).Reparent(footer);
        this.m_favBtn = favBtn;
        this.m_firstBtn = firstBtn;
        this.m_lastBtn = lastBtn;
        this.m_prevBtn = prevBtn;
        this.m_nextBtn = nextBtn;

        this.m_grid = grid;
        this.m_title = title;
        this.m_info = info;
        this.m_toast = toast;
        this.m_toastIcon = toastIcon;
        this.m_toastText = toastText;

        this.SetRootWidget(root);
    }

    // ---- public API used by the menu ----

    public func IsOpen() -> Bool {
        return IsDefined(this.GetRootWidget()) && this.GetRootWidget().IsVisible();
    }

    public func Open(option: wref<CharacterCustomizationOption>) {
        this.m_option = option;
        let count = this.GetCount();
        CCUI_Log(s"open \(NameToString(option.info.uiSlot)): \(count) entries, current=\(this.GetCurrent())");
        if count <= 0 {
            return;
        }
        this.m_title.SetText(CCUI_Title(option.info));
        this.m_toast.StopAllAnimations();
        this.m_toast.SetOpacity(0.0);
        this.BuildOrder();
        this.m_page = Max(0, this.DisplayPos(this.GetCurrent())) / this.PageSize();
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

    private func GetInfo() -> ref<gameuiCharacterCustomizationInfo> {
        return IsDefined(this.m_option) ? this.m_option.info : null;
    }

    private func GetCount() -> Int32 {
        let info = this.GetInfo();
        return IsDefined(info) ? CCUI_EntryCount(info) : 0;
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

    private func BuildOrder() {
        ArrayClear(this.m_order);
        let info = this.GetInfo();
        let favs = OptionFavorites.Get();
        let count = this.GetCount();
        let rest: array<Int32>;
        let i = 0;
        while i < count {
            if IsDefined(favs) && favs.Has(CCUI_FavoriteKey(info, i)) {
                ArrayPush(this.m_order, i);
            } else {
                ArrayPush(rest, i);
            }
            i += 1;
        }
        for index in rest {
            ArrayPush(this.m_order, index);
        }
    }

    private func DisplayPos(index: Int32) -> Int32 {
        return ArrayFindFirst(this.m_order, index);
    }

    private func IsFavorite(index: Int32) -> Bool {
        let info = this.GetInfo();
        let favs = OptionFavorites.Get();
        return IsDefined(info) && IsDefined(favs) && index >= 0 && index < this.GetCount()
            && favs.Has(CCUI_FavoriteKey(info, index));
    }

    // ---- building ----

    private func Rebuild() {
        this.m_grid.RemoveAllChildren();
        ArrayClear(this.m_tiles);

        let count = this.GetCount();
        let first = this.m_page * this.PageSize();
        let last = Min(first + this.PageSize(), count);

        let row: ref<inkHorizontalPanel>;
        let i = first;
        while i < last {
            if (i - first) % this.m_cols == 0 {
                row = new inkHorizontalPanel();
                row.SetMargin(inkMargin(0.0, 0.0, 0.0, this.m_gap));
                row.Reparent(this.m_grid);
            }
            let index = this.m_order[i];
            let tile = this.MakeTile(index);
            tile.Reparent(row);
            ArrayPush(this.m_tiles, tile);
            i += 1;
        }

        this.RestyleTiles();
        this.UpdateInfo();
    }

    private func MakeTile(index: Int32) -> ref<inkCanvas> {
        let info = this.GetInfo();
        let textW = this.m_tileW - 40.0;
        let labelW = textW - 44.0; // room for the star

        let tile = new inkCanvas();
        tile.SetName(StringToName(s"grid_tile_\(index)"));
        tile.SetSize(Vector2(this.m_tileW, this.m_tileH));
        tile.SetMargin(inkMargin(0.0, 0.0, this.m_gap, 0.0));
        tile.SetInteractive(true);

        let bg = new inkRectangle();
        bg.SetName(n"bg");
        bg.SetAnchor(inkEAnchor.Fill);
        bg.Reparent(tile);

        let frame = CCUI_AddFrame(tile, CCUI_MildRed(), 2.0, 0.7);
        frame.SetName(n"frame");

        let bar = new inkRectangle();
        bar.SetName(n"bar");
        bar.SetAnchor(inkEAnchor.LeftFillVerticaly);
        bar.SetSize(Vector2(6.0, 100.0));
        bar.Reparent(tile);

        // Up to two lines, clipped with an ellipsis on the second.
        let label = CCUI_MakeText(CCUI_Ellipsize(CCUI_EntryLabel(info, index), 46), 30, n"Semi-Bold", CCUI_Red());
        label.SetName(n"label");
        label.SetAnchor(inkEAnchor.TopLeft);
        label.SetMargin(inkMargin(20.0, 10.0, 0.0, 0.0));
        label.SetFitToContent(false);
        label.SetSize(Vector2(labelW, 72.0));
        label.SetWrapping(true, labelW);
        label.SetOverflowPolicy(textOverflowPolicy.DotsEndLastLine);
        label.Reparent(tile);

        // Index + internal name help tell apart modded entries that share a display name.
        let internal = NameToString(CCUI_EntryName(info, index));
        let sub = CCUI_MakeText(CCUI_Ellipsize(s"#\(index)  \(internal)", 36), 22, n"Regular", CCUI_MildRed());
        sub.SetName(n"sub");
        sub.SetAnchor(inkEAnchor.BottomLeft);
        sub.SetAnchorPoint(Vector2(0.0, 1.0));
        sub.SetMargin(inkMargin(20.0, 0.0, 0.0, 8.0));
        sub.SetFitToContent(false);
        sub.SetSize(Vector2(textW, 28.0));
        sub.SetOverflowPolicy(textOverflowPolicy.DotsEnd);
        sub.Reparent(tile);

        // Favorite toggle; its clicks are kept from applying the entry (see OnTileRelease).
        let star = new inkImage();
        star.SetName(n"star");
        star.SetAtlasResource(r"base\\gameplay\\gui\\common\\icons\\atlas_nameplate.inkatlas");
        star.SetTexturePart(n"icon_star");
        star.SetAnchor(inkEAnchor.TopRight);
        star.SetAnchorPoint(Vector2(1.0, 0.0));
        star.SetMargin(inkMargin(0.0, 10.0, 10.0, 0.0));
        star.SetSize(Vector2(38.0, 38.0));
        star.SetInteractive(true);
        star.RegisterToCallback(n"OnRelease", this, n"OnStarRelease");
        star.RegisterToCallback(n"OnHoverOver", this, n"OnStarHoverOver");
        star.RegisterToCallback(n"OnHoverOut", this, n"OnStarHoverOut");
        star.Reparent(tile);

        tile.RegisterToCallback(n"OnRelease", this, n"OnTileRelease");
        tile.RegisterToCallback(n"OnHoverOver", this, n"OnTileHoverOver");
        tile.RegisterToCallback(n"OnHoverOut", this, n"OnTileHoverOut");

        return tile;
    }

    // Vanilla option-row look: dark red fill, red frame and text; the active value is cyan.
    private func RestyleTiles() {
        let current = this.GetCurrent();
        for tile in this.m_tiles {
            let index = CCUI_TileIndex(tile);
            let selected = index == current;
            let hovered = index == this.m_hovered;

            let bg = tile.GetWidget(n"bg");
            let frame = tile.GetWidget(n"frame");
            let bar = tile.GetWidget(n"bar");
            let label = tile.GetWidget(n"label");
            let sub = tile.GetWidget(n"sub");
            let star = tile.GetWidget(n"star");
            if this.IsFavorite(index) {
                star.SetTintColor(CCUI_Gold());
                star.SetOpacity(1.0);
            } else {
                star.SetTintColor(hovered ? CCUI_Red() : CCUI_MildRed());
                star.SetOpacity(hovered ? 0.9 : 0.45);
            }

            if selected {
                bg.SetTintColor(CCUI_FaintBlue());
                bg.SetOpacity(0.9);
                CCUI_SetTint(frame, CCUI_Blue());
                frame.SetOpacity(1.0);
                bar.SetTintColor(CCUI_Blue());
                bar.SetOpacity(1.0);
                label.SetTintColor(CCUI_Blue());
                sub.SetTintColor(CCUI_MildBlue());
            } else if hovered {
                bg.SetTintColor(CCUI_HoverRed());
                bg.SetOpacity(0.9);
                CCUI_SetTint(frame, CCUI_Red());
                frame.SetOpacity(1.0);
                bar.SetTintColor(CCUI_Red());
                bar.SetOpacity(1.0);
                label.SetTintColor(CCUI_ActiveRed());
                sub.SetTintColor(CCUI_Red());
            } else {
                bg.SetTintColor(CCUI_DarkRed());
                bg.SetOpacity(0.55);
                CCUI_SetTint(frame, CCUI_MildRed());
                frame.SetOpacity(0.7);
                bar.SetTintColor(CCUI_MildRed());
                bar.SetOpacity(0.6);
                label.SetTintColor(CCUI_Red());
                sub.SetTintColor(CCUI_MildRed());
            }
        }
    }

    private func ShowToast(added: Bool, name: String) {
        let color = added ? CCUI_Gold() : CCUI_MildRed();
        this.m_toastIcon.SetTintColor(color);
        this.m_toastIcon.SetOpacity(added ? 1.0 : 0.5);
        this.m_toastText.SetTintColor(color);
        this.m_toastText.SetText(CCUI_Ellipsize((added ? "Added to favorites: " : "Removed from favorites: ") + name, 70));

        // Restart: visible now, hold, then fade out.
        this.m_toast.StopAllAnimations();
        this.m_toast.SetOpacity(1.0);
        let fade = new inkAnimTransparency();
        fade.SetStartTransparency(1.0);
        fade.SetEndTransparency(0.0);
        fade.SetStartDelay(1.8);
        fade.SetDuration(0.6);
        let anim = new inkAnimDef();
        anim.AddInterpolator(fade);
        this.m_toast.PlayAnimation(anim);
    }

    private func UpdateInfo() {
        let favs = OptionFavorites.Get();
        let info = this.GetInfo();
        let favCount = IsDefined(favs) && IsDefined(info) ? favs.CountFor(info.uiSlot) : 0;
        this.m_info.SetText(s"\(this.GetCount()) options  ·  \(favCount) fav  ·  page \(this.m_page + 1)/\(this.PageCount())  ·  current #\(this.GetCurrent())");
        this.UpdatePaging();
        this.UpdateFavButton();
    }

    private func UpdateFavButton() {
        let star = this.m_favBtn.GetWidget(n"favStar");
        let current = this.GetCurrent();
        if current < 0 {
            star.SetOpacity(0.2);
            return;
        }
        let fav = this.IsFavorite(current);
        star.SetTintColor(fav ? CCUI_Gold() : CCUI_MildRed());
        star.SetOpacity(fav ? 1.0 : 0.6);
    }

    // Shared by the tile stars and the footer star.
    private func ToggleFavorite(index: Int32) {
        let info = this.GetInfo();
        let favs = OptionFavorites.Get();
        if index < 0 || !IsDefined(info) || !IsDefined(favs) {
            return;
        }
        let key = CCUI_FavoriteKey(info, index);
        let now = favs.Toggle(key);
        CCUI_Log(s"favorite \(NameToString(key)) -> \(now)");
        this.ShowToast(now, CCUI_EntryLabel(info, index));
        if IsDefined(this.m_menu) {
            this.m_menu.PlaySound(n"Button", n"OnPress");
        }
        // Re-sort but stay on the same page.
        this.BuildOrder();
        this.m_page = Min(this.m_page, this.PageCount() - 1);
        this.Rebuild();
    }

    private func UpdatePaging() {
        let many = this.PageCount() > 2;
        this.m_firstBtn.SetVisible(many);
        this.m_lastBtn.SetVisible(many);
        // The UI font has no ‹ › glyphs, so the compact buttons show drawn chevrons instead.
        for btn in [this.m_prevBtn, this.m_nextBtn] {
            btn.GetWidget(n"label").SetVisible(!many);
            btn.GetWidget(n"chevron").SetVisible(many);
        }
    }

    private func MakeButton(text: String, callback: CName, width: Float) -> ref<inkCanvas> {
        let btn = new inkCanvas();
        btn.SetSize(Vector2(width, 80.0));
        btn.SetMargin(inkMargin(0.0, 0.0, 20.0, 0.0));
        btn.SetInteractive(true);

        let bg = new inkRectangle();
        bg.SetName(n"bg");
        bg.SetAnchor(inkEAnchor.Fill);
        bg.SetTintColor(CCUI_DarkRed());
        bg.SetOpacity(0.8);
        bg.Reparent(btn);

        let frame = CCUI_AddFrame(btn, CCUI_Red(), 2.0, 0.8);
        frame.SetName(n"frame");

        let label = CCUI_MakeText(text, 34, n"Semi-Bold", CCUI_Red());
        label.SetName(n"label");
        label.SetAnchor(inkEAnchor.Centered);
        label.SetAnchorPoint(Vector2(0.5, 0.5));
        label.Reparent(btn);

        btn.RegisterToCallback(n"OnRelease", this, callback);
        btn.RegisterToCallback(n"OnHoverOver", this, n"OnButtonHoverOver");
        btn.RegisterToCallback(n"OnHoverOut", this, n"OnButtonHoverOut");
        return btn;
    }

    // ---- callbacks ----

    protected cb func OnTileRelease(e: ref<inkPointerEvent>) -> Bool {
        if Equals(e.GetTarget().GetName(), n"star") {
            return false;
        }
        if e.IsAction(n"click") {
            let index = CCUI_TileIndex(e.GetCurrentTarget());
            CCUI_Log(s"click tile #\(index)");
            if index >= 0 && IsDefined(this.m_menu) {
                this.m_menu.CCUI_Apply(index);
            }
        }
        e.Handle();
        return true;
    }

    protected cb func OnStarRelease(e: ref<inkPointerEvent>) -> Bool {
        if e.IsAction(n"click") {
            this.ToggleFavorite(CCUI_TileIndex(e.GetCurrentTarget().GetParentWidget()));
        }
        e.Handle();
        return true;
    }

    protected cb func OnFavCurrentRelease(e: ref<inkPointerEvent>) -> Bool {
        if e.IsAction(n"click") {
            this.ToggleFavorite(this.GetCurrent());
        }
        e.Handle();
        return true;
    }

    protected cb func OnStarHoverOver(e: ref<inkPointerEvent>) -> Bool {
        let star = e.GetCurrentTarget();
        if !this.IsFavorite(CCUI_TileIndex(star.GetParentWidget())) {
            star.SetTintColor(CCUI_Gold());
            star.SetOpacity(0.8);
        }
        return false;
    }

    protected cb func OnStarHoverOut(e: ref<inkPointerEvent>) -> Bool {
        this.RestyleTiles();
        return false;
    }

    protected cb func OnTileHoverOver(e: ref<inkPointerEvent>) -> Bool {
        this.m_hovered = CCUI_TileIndex(e.GetCurrentTarget());
        this.RestyleTiles();
        return false;
    }

    protected cb func OnTileHoverOut(e: ref<inkPointerEvent>) -> Bool {
        if this.m_hovered == CCUI_TileIndex(e.GetCurrentTarget()) {
            this.m_hovered = -1;
            this.RestyleTiles();
        }
        return false;
    }

    protected cb func OnButtonHoverOver(e: ref<inkPointerEvent>) -> Bool {
        let btn = e.GetCurrentTarget() as inkCompoundWidget;
        btn.GetWidget(n"bg").SetTintColor(CCUI_HoverRed());
        btn.GetWidget(n"frame").SetOpacity(1.0);
        btn.GetWidget(n"label").SetTintColor(CCUI_ActiveRed());
        let chevron = btn.GetWidget(n"chevron");
        if IsDefined(chevron) {
            CCUI_SetTint(chevron, CCUI_ActiveRed());
        }
        return false;
    }

    protected cb func OnButtonHoverOut(e: ref<inkPointerEvent>) -> Bool {
        let btn = e.GetCurrentTarget() as inkCompoundWidget;
        btn.GetWidget(n"bg").SetTintColor(CCUI_DarkRed());
        btn.GetWidget(n"frame").SetOpacity(0.8);
        btn.GetWidget(n"label").SetTintColor(CCUI_Red());
        let chevron = btn.GetWidget(n"chevron");
        if IsDefined(chevron) {
            CCUI_SetTint(chevron, CCUI_Red());
        }
        return false;
    }

    protected cb func OnFirstRelease(e: ref<inkPointerEvent>) -> Bool {
        if e.IsAction(n"click") && this.m_page != 0 {
            this.m_page = 0;
            this.m_hovered = -1;
            this.Rebuild();
        }
        e.Handle();
        return true;
    }

    protected cb func OnLastRelease(e: ref<inkPointerEvent>) -> Bool {
        let last = this.PageCount() - 1;
        if e.IsAction(n"click") && this.m_page != last {
            this.m_page = last;
            this.m_hovered = -1;
            this.Rebuild();
        }
        e.Handle();
        return true;
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
            this.m_menu.CCUI_Close();
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

// Tiles are named "grid_tile_<index>".
public func CCUI_TileIndex(widget: wref<inkWidget>) -> Int32 {
    if !IsDefined(widget) {
        return -1;
    }
    let name = NameToString(widget.GetName());
    if !StrBeginsWith(name, "grid_tile_") {
        return -1;
    }
    return StringToInt(StrAfterFirst(name, "grid_tile_"), -1);
}

// A single chevron (‹ or ›) drawn as two rotated bars, named "chevron", hidden until UpdatePaging shows it.
public func CCUI_AddChevron(parent: ref<inkCompoundWidget>, pointLeft: Bool) {
    let w = 30.0;
    let h = 40.0;
    let reach = 13.0;      // horizontal distance from the tip to the arm ends
    let thickness = 4.0;
    let armLength = reach * 1.4142 + thickness / 2.0;

    let chevron = new inkCanvas();
    chevron.SetName(n"chevron");
    chevron.SetAnchor(inkEAnchor.Centered);
    chevron.SetAnchorPoint(Vector2(0.5, 0.5));
    chevron.SetSize(Vector2(w, h));
    chevron.SetVisible(false);

    let tipX = pointLeft ? (w - reach) / 2.0 : (w + reach) / 2.0;
    let armX = pointLeft ? tipX + reach / 2.0 : tipX - reach / 2.0;
    let midY = h / 2.0;
    // Screen y grows downward and positive rotation is clockwise, so for ‹ the upper arm
    // ("/") is rotated -45° and the lower arm ("\") +45°; › mirrors that.
    let upperAngle = pointLeft ? -45.0 : 45.0;

    let upper = new inkRectangle();
    upper.SetAnchor(inkEAnchor.TopLeft);
    upper.SetAnchorPoint(Vector2(0.5, 0.5));
    upper.SetSize(Vector2(armLength, thickness));
    upper.SetMargin(inkMargin(armX, midY - reach / 2.0, 0.0, 0.0));
    upper.SetRotation(upperAngle);
    upper.Reparent(chevron);

    let lower = new inkRectangle();
    lower.SetAnchor(inkEAnchor.TopLeft);
    lower.SetAnchorPoint(Vector2(0.5, 0.5));
    lower.SetSize(Vector2(armLength, thickness));
    lower.SetMargin(inkMargin(armX, midY + reach / 2.0, 0.0, 0.0));
    lower.SetRotation(-upperAngle);
    lower.Reparent(chevron);

    CCUI_SetTint(chevron, CCUI_Red());
    chevron.Reparent(parent);
}

// Hard cap as a backstop in case the engine's overflow policy doesn't clip.
public func CCUI_Ellipsize(text: String, maxChars: Int32) -> String {
    if StrLen(text) <= maxChars {
        return text;
    }
    return StrLeft(text, maxChars - 3) + "...";
}

// 1px-style outline made of four edges; returned canvas is named by the caller.
public func CCUI_AddFrame(parent: ref<inkCompoundWidget>, color: HDRColor, thickness: Float, opacity: Float) -> ref<inkCanvas> {
    let frame = new inkCanvas();
    frame.SetAnchor(inkEAnchor.Fill);
    frame.SetOpacity(opacity);

    let top = new inkRectangle();
    top.SetAnchor(inkEAnchor.TopFillHorizontaly);
    top.SetSize(Vector2(100.0, thickness));
    top.Reparent(frame);

    let bottom = new inkRectangle();
    bottom.SetAnchor(inkEAnchor.BottomFillHorizontaly);
    bottom.SetSize(Vector2(100.0, thickness));
    bottom.Reparent(frame);

    let left = new inkRectangle();
    left.SetAnchor(inkEAnchor.LeftFillVerticaly);
    left.SetSize(Vector2(thickness, 100.0));
    left.Reparent(frame);

    let right = new inkRectangle();
    right.SetAnchor(inkEAnchor.RightFillVerticaly);
    right.SetSize(Vector2(thickness, 100.0));
    right.Reparent(frame);

    CCUI_SetTint(frame, color);
    frame.Reparent(parent);
    return frame;
}

// Ink tint doesn't propagate to children (opacity does), so color a drawn
// shape by tinting the container and every widget inside it.
public func CCUI_SetTint(widget: wref<inkWidget>, color: HDRColor) {
    if !IsDefined(widget) {
        return;
    }
    widget.SetTintColor(color);
    let compound = widget as inkCompoundWidget;
    if IsDefined(compound) {
        let i = 0;
        while i < compound.GetNumChildren() {
            CCUI_SetTint(compound.GetWidgetByIndex(i), color);
            i += 1;
        }
    }
}

// Palette from base\gameplay\gui\common\main_colors.inkstyle (MainColors.*).
public func CCUI_Red() -> HDRColor = HDRColor(1.176, 0.381, 0.348, 1.0)
public func CCUI_ActiveRed() -> HDRColor = HDRColor(1.370, 0.444, 0.405, 1.0)
public func CCUI_MildRed() -> HDRColor = HDRColor(0.682, 0.231, 0.212, 1.0)
public func CCUI_DarkRed() -> HDRColor = HDRColor(0.263, 0.086, 0.094, 1.0)
public func CCUI_HoverRed() -> HDRColor = HDRColor(0.412, 0.086, 0.090, 1.0)  // Fullscreen_SecondaryBackground4
public func CCUI_PanelBg() -> HDRColor = HDRColor(0.055, 0.035, 0.050, 1.0)   // near Fullscreen_PrimaryBackgroundDarkest, red-shifted
public func CCUI_Blue() -> HDRColor = HDRColor(0.369, 0.965, 1.0, 1.0)
public func CCUI_MildBlue() -> HDRColor = HDRColor(0.204, 0.569, 0.592, 1.0)
public func CCUI_FaintBlue() -> HDRColor = HDRColor(0.090, 0.173, 0.180, 1.0)
public func CCUI_Gold() -> HDRColor = HDRColor(1.119, 0.844, 0.257, 1.0)
public func CCUI_Black() -> HDRColor = HDRColor(0.0, 0.0, 0.0, 1.0)

public func CCUI_Color(r: Float, g: Float, b: Float) -> HDRColor {
    return HDRColor(r, g, b, 1.0);
}

public func CCUI_MakeText(text: String, size: Int32, style: CName, color: HDRColor) -> ref<inkText> {
    let t = new inkText();
    t.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    t.SetFontStyle(style);
    t.SetFontSize(size);
    t.SetTintColor(color);
    t.SetText(text);
    return t;
}
