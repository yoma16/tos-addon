-- v1.0.0 first release
-- v1.0.1 fix slot remap and speed up summon interval
-- v1.0.2 add always-on-screen preset HUD (labeled toggle button + separate compact preset panel)
-- v1.0.3 add a "made by" credit line with the guild emblem at the bottom of the preset window
-- v1.0.4 rebuild the preset window: hand-drawn tabs, panelled regions, skinned scrollbar
local addonName = "cupole_manager"
local version = "1.0.4"
local author = "Yomae"

local addonNameLower = string.lower(addonName)

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]
local acutil = require("acutil")
local json = require("json")

-- 이 팀으로 접속하면 애드온 설정을 일절 쓰지 않는다. 저장은 빈 값으로만 하고, 읽기는 항상
-- 없는 것으로 취급해서 매번 기본값으로 시작한다(저장만 막으면 이미 저장돼 있던 설정이 계속
-- 로드되므로 둘 다 막아야 한다)
-- teams that never use addon settings: writes go out empty and reads always report "missing",
-- so every login starts from defaults (blocking writes alone would still load older saves)
local CM_NO_SAVE_TEAMS = {
    ["유니우스"] = true,
    ["파비우스"] = true,
    ["이그너스"] = true
}

local function CM_is_no_save_team()
    -- 로그인 전에는 팀명을 못 얻을 수 있다. 실패하면 평소대로 동작시킨다
    -- the team name may not exist before login; fall back to normal behaviour
    local ok, team_name = pcall(GETMYFAMILYNAME)
    if not ok or type(team_name) ~= "string" then
        return false
    end
    return CM_NO_SAVE_TEAMS[team_name] == true
end

-- Infrastructure: save_json (safe tmp-file write)
local function CM_save_json(path, tbl)
    if CM_is_no_save_team() then
        tbl = {}
    end
    local success, str = pcall(json.encode, tbl)
    if not success then
        return false
    end
    local tmp_path = path .. ".tmp"
    local file, err = io.open(tmp_path, "w")
    if not file then
        return false
    end
    local ok_w, w_err = file:write(str)
    file:close()
    if ok_w then
        os.remove(path)
        os.rename(tmp_path, path)
        return true
    end
    return false
end

-- Infrastructure: load_json (BOM handling, tmp fallback)
local function CM_load_json(path)
    if CM_is_no_save_team() then
        return nil
    end
    local file = io.open(path, "r")
    if not file then
        local tmp_file = io.open(path .. ".tmp", "r")
        if tmp_file then
            local tmp_content = tmp_file:read("*all")
            tmp_file:close()
            if tmp_content and tmp_content ~= "" then
                os.remove(path)
                os.rename(path .. ".tmp", path)
                local s, r = pcall(json.decode, tmp_content)
                if s then return r end
            end
        end
        return nil
    end
    local content = file:read("*all")
    file:close()
    if not content or content == "" then
        local tmp_file = io.open(path .. ".tmp", "r")
        if tmp_file then
            local tmp_content = tmp_file:read("*all")
            tmp_file:close()
            if tmp_content and tmp_content ~= "" then
                os.remove(path)
                os.rename(path .. ".tmp", path)
                local s, r = pcall(json.decode, tmp_content)
                if s then return r end
            end
        end
        return nil
    end
    if string.sub(content, 1, 3) == "\239\187\191" then
        content = string.sub(content, 4)
    end
    local success, result = pcall(json.decode, content)
    if success then
        return result
    end
    return nil
end

-- Infrastructure: get_map_type
local function CM_get_map_type()
    local map_name = session.GetMapName()
    local map_cls = GetClass("Map", map_name)
    local map_type = map_cls.MapType
    return map_type
end

-- Infrastructure: setup_hook (simplified for standalone)
local function CM_setup_hook(origin_func_name, my_func_name)
    g.FUNCS = g.FUNCS or {}
    if not g.FUNCS[origin_func_name] then
        g.FUNCS[origin_func_name] = _G[origin_func_name]
    end
    local origin_func = g.FUNCS[origin_func_name]
    _G[origin_func_name] = function(...)
        local original_results = {origin_func(...)}
        _G[my_func_name](...)
        return table.unpack(original_results)
    end
end

-- Infrastructure: create folder
local function CM_create_folder(path)
    local file = io.open(path .. "/mkdir.txt", "r")
    if not file then
        os.execute('mkdir "' .. path .. '"')
        file = io.open(path .. "/mkdir.txt", "w")
        if file then
            file:write("created")
            file:close()
        end
    else
        file:close()
    end
end

CM_create_folder("../addons")
CM_create_folder("../addons/" .. addonNameLower)

-- 슬롯 리맵. 게임 슬롯 번호는 0=Center, 1=Right, 2=Left 이다(인게임 실측).
-- 프리셋은 1=Center, 2=Left, 3=Right 로 저장하므로 쓸 때 이 표로 변환한다
-- slot remap; game slot numbers are 0=Center, 1=Right, 2=Left (measured in game).
-- presets store 1=Center, 2=Left, 3=Right, so writes go through this table
local CM_SLOT_REMAP = {[0] = 0, [1] = 2, [2] = 1}

-- ⚠️ GET_EQUIP_CUPOLE_LIST() 도 게임 슬롯 순서(1=game0, 2=game1, 3=game2)로 돌려준다.
-- 즉 읽을 때도 같은 변환이 필요한데 그게 빠져 있어서 Left/Right 가 서로 바뀌어 저장됐다
-- (Center 는 game0=1 로 우연히 일치해서 멀쩡했다)
-- GET_EQUIP_CUPOLE_LIST() is indexed by game slot too (1=game0, 2=game1, 3=game2), so reads
-- need the same conversion; it was missing, which stored Left and Right swapped
-- (Center happened to line up, so only left/right looked wrong)
local function CM_equip_index(preset_index)
    return CM_SLOT_REMAP[preset_index - 1] + 1
end

-- ⚠️ 화면 크기 API 는 두 종류이고 좌표계가 다르다.
--   ui.GetClientInitialWidth/Height  = UI 좌표계 (프레임 배치용). SetPos/SetMargin 은 이 값 기준.
--   option.GetClientWidth/Height     = 실제 화면 픽셀. movie.PlayUIEffect 같은 화면 좌표용.
-- 프레임을 화면 중앙에 놓을 땐 반드시 앞의 것을 쓴다(클라 선례: quickslotnexpbar.lua:1695).
-- option 쪽으로 바꿨다가 일반 모니터에서 창이 우하단으로 밀리는 회귀를 냈다(2026-08-16).
-- two different APIs with different coordinate spaces:
--   ui.GetClientInitialWidth/Height = UI space, what SetPos/SetMargin use - use this for frames
--   option.GetClientWidth/Height    = real screen pixels, for things like movie.PlayUIEffect
-- switching to option once pushed the window to the bottom-right on a normal monitor
local function CM_screen_size()
    return ui.GetClientInitialWidth(), ui.GetClientInitialHeight()
end

-- ============================================================
-- Init
-- ============================================================
function CUPOLE_MANAGER_ON_INIT(addon, frame)
    frame:ShowWindow(1)
    g.addon = addon
    g.frame = frame
    g.lang = option.GetCurrentCountry()
    addon:RegisterMsg("GAME_START_3SEC", "CM_GAME_START")
end

function CM_GAME_START()
    g.active_id = tostring(session.loginInfo.GetAID())
    g.cid = tostring(session.GetMySession():GetCID())
    CM_create_folder("../addons/" .. addonNameLower .. "/" .. g.active_id)
    CM_load_settings()
    CM_auto_summon()
    CM_register_hooks()
    CM_make_menu()
    -- HUD only appears in town (fires on every map load via GAME_START_3SEC)
    if CM_get_map_type() == "City" then
        CM_hud_create()
    else
        CM_hud_destroy()
    end
end

-- ============================================================
-- Settings Save/Load
-- ============================================================
function CM_save_settings()
    CM_save_json(g.cupole_manager_path, g.cupole_manager_settings)
end

function CM_load_settings()
    g.cupole_manager_path = string.format("../addons/%s/%s/cupole_manager.json", addonNameLower, g.active_id)
    local changed = false
    local settings = CM_load_json(g.cupole_manager_path)
    if not settings then
        -- migrate from nexus_addons
        local nexus_path = string.format("../addons/%s/%s/cupole_manager.json", "nexus_addons", g.active_id)
        settings = CM_load_json(nexus_path)
        if settings then
            changed = true
        else
            settings = {}
            changed = true
        end
    end
    if not settings.default then
        settings.default = {}
        changed = true
    end
    if not settings.presets then
        settings.presets = {}
        changed = true
    end
    if not settings.hud then
        -- position (x/y) is initialised by CM_hud_create (left-middle default)
        settings.hud = { open = 0 }
        changed = true
    end
    g.cupole_manager_settings = settings
    if changed then
        CM_save_settings()
    end
end

-- ============================================================
-- Auto-Summon
-- ============================================================
function CM_auto_summon()
    if not g.cupole_manager_settings then
        CM_load_settings()
    end
    if not g.cupole_manager_settings[g.cid] then
        g.cupole_manager_settings[g.cid] = {}
        CM_save_settings()
    end
    if CM_get_map_type() == "City" then
        local equip_cupole_list = GET_EQUIP_CUPOLE_LIST()
        for i = 1, 3 do
            if equip_cupole_list[CM_equip_index(i)] == "-1" then
                CM_set_cupole_slots()
                break
            end
        end
    end
end

function CM_register_hooks()
    if CM_get_map_type() == "City" then
        CM_setup_hook("CLOSE_CUPOLE_ITEM", "CM_CLOSE_CUPOLE_ITEM")
        CM_setup_hook("OPEN_CUPOLE_ITEM", "CM_OPEN_CUPOLE_ITEM")
    end
end

-- ============================================================
-- Cupole Item Hooks
-- ============================================================
function CM_OPEN_CUPOLE_ITEM()
    local cupole_item = ui.GetFrame("cupole_item")
    if not cupole_item then
        return
    end
    local manageBG = GET_CHILD_RECURSIVELY(cupole_item, "manageBG")
    local save_btn = manageBG:CreateOrGetControl("button", "save_btn", 1400, 730, 135, 45)
    AUTO_CAST(save_btn)
    save_btn:SetSkinName("cupole_border_btn")
    save_btn:SetText(g.lang == "Japanese" and "{ol}{s15}デフォルト変更" or "{ol}{s15}Change Default")
    save_btn:SetTextTooltip(g.lang == "Japanese" and "{ol}現在のセットをデフォルトに変更します" or
                                "{ol}Change the current set to the default")
    save_btn:SetEventScript(ui.LBUTTONUP, "CM_save_default_settings")
end

function CM_CLOSE_CUPOLE_ITEM(parent, ctrl)
    local equip_cupole_list = GET_EQUIP_CUPOLE_LIST()
    for i = 1, 3 do
        local cupole_cls = GET_CUPOLE_BY_INDEX_IN_CLASSLIST(equip_cupole_list[CM_equip_index(i)])
        local cupole_class_name = TryGetProp(cupole_cls, "ClassName", "None")
        if equip_cupole_list[CM_equip_index(i)] ~= "-1" then
            g.cupole_manager_settings[g.cid][tostring(i)] = {
                id = equip_cupole_list[CM_equip_index(i)],
                name = cupole_class_name
            }
            if not g.cupole_manager_settings["default"][tostring(i)] then
                g.cupole_manager_settings["default"][tostring(i)] = {
                    id = equip_cupole_list[CM_equip_index(i)],
                    name = cupole_class_name
                }
            end
        end
    end
    CM_save_settings()
end

function CM_save_default_settings()
    local equip_cupole_list = GET_EQUIP_CUPOLE_LIST()
    for i = 1, 3 do
        if equip_cupole_list[CM_equip_index(i)] == "-1" then
            ui.SysMsg(g.lang == "Japanese" and "クポルが3体登録されていません" or
                          "3 Cupoles are not registered")
            return
        end
    end
    for i = 1, 3 do
        local cupole_cls = GET_CUPOLE_BY_INDEX_IN_CLASSLIST(equip_cupole_list[CM_equip_index(i)])
        local cupole_class_name = TryGetProp(cupole_cls, "ClassName", "None")
        g.cupole_manager_settings["default"][tostring(i)] = {
            id = equip_cupole_list[CM_equip_index(i)],
            name = cupole_class_name
        }
    end
    CM_save_settings()
    ui.SysMsg(g.lang == "Japanese" and "現在のセットをデフォルトとして保存しました" or
                  "Saved the current set as default")
end

-- ============================================================
-- Set Cupole Slots (auto-summon logic)
-- ============================================================
function CM_set_cupole_slots()
    local function is_valid_set(settings)
        if not settings or not settings["1"] or not settings["2"] or not settings["3"] then
            return false
        end
        if settings["1"].id == "-1" or settings["2"].id == "-1" or settings["3"].id == "-1" then
            return false
        end
        return true
    end
    local cid_settings = g.cupole_manager_settings[g.cid]
    local default_settings = g.cupole_manager_settings["default"]
    if is_valid_set(cid_settings) then
        g.cupole_manager_tbl = cid_settings
    else
        if is_valid_set(default_settings) then
            if next(cid_settings) then
                ui.SysMsg(g.lang == "Japanese" and "デフォルトのクポルセットを適用します" or
                              "Applying the default Cupole set")
            end
            g.cupole_manager_tbl = default_settings
        else
            ui.SysMsg(g.lang == "Japanese" and "デフォルトのクポルセット未登録" or
                          "Default Cupole set is not registered")
            return
        end
    end
    g.cupole_manager_num = 0
    local cm_frame = ui.GetFrame("cupole_manager")
    cm_frame:RunUpdateScript("CM_summon_cupole", 0.3)
end

function CM_summon_cupole(frame)
    if g.cupole_manager_num == 3 then
        frame:StopUpdateScript("CM_summon_cupole")
        return 0
    end
    SummonCupole(tonumber(g.cupole_manager_tbl[tostring(g.cupole_manager_num + 1)].id), CM_SLOT_REMAP[g.cupole_manager_num])
    g.cupole_manager_num = g.cupole_manager_num + 1
    return 1
end

-- ============================================================
-- Norisan Menu
-- ============================================================
-- 이 애드온은 노리산 메뉴에 항목을 올리지 않는다. 프리셋 창은 HUD 의 톱니 버튼으로 연다.
-- 다만 메뉴 구현체는 여기 들어 있으므로(다른 애드온이 쓸 수 있게) 프레임 생성은 유지한다.
-- 예전 항목이 메뉴 설정 json 에 남아 있을 수 있어 등록 해제도 명시적으로 해 준다
-- this addon no longer puts an item on the norisan menu - the gear on the HUD opens the preset
-- window instead. the menu implementation still lives here for other addons, so keep creating
-- the frame, and clear our stale entry which may persist in the menu's settings json
function CM_make_menu()
    _G["norisan"] = _G["norisan"] or {}
    _G["norisan"]["MENU"] = _G["norisan"]["MENU"] or {}
    _G["norisan"]["MENU"]["cupole_preset"] = nil
    local frame_name = _G["norisan"]["MENU"].frame_name
    local menu_frame = ui.GetFrame(frame_name)
    if menu_frame and frame_name ~= "norisan_menu_frame" then
        ui.DestroyFrame(frame_name)
    end
    frame_name = "norisan_menu_frame"
    _G["norisan"]["MENU"].frame_name = frame_name
    g.norisan_menu_create_frame()
end

-- 프리셋 창 배경 스킨. 한 줄만 바꾸면 원래(불투명 test_frame_low)로 되돌릴 수 있다
-- preset window background skin; revert to "test_frame_low" here for the old opaque look
-- HUD(토글 바/패널)와 설정창이 같은 배경을 쓰도록 한 곳에서 정의한다.
-- groupbox 는 SetAlpha 가 없어서 스킨으로만 투명도를 낼 수 있지만, frame 은 SetAlpha 가 되므로
-- 프레임 스킨 bg2 + 알파 쪽이 더 맑고(희끄무레) 톤도 HUD 와 정확히 일치한다
-- one definition so the HUD bars and the settings window share a background.
-- a groupbox can only get transparency from its skin, but a frame takes SetAlpha - the
-- bg2-skin-plus-alpha route looks cleaner and matches the HUD exactly
local CM_UI_SKIN = "bg2"
local CM_UI_ALPHA = 110
-- 탭 판때기 색. 클라에 있는 탭 스킨: tab2(기본, 누런색) tab3 tab4 adventure_tab colony_tab
-- tab plate skin; client tab skins: tab2 (default, the yellow one) tab3 tab4 adventure_tab colony_tab
-- 탭은 게임 tab 컨트롤 대신 직접 그린다. 활성/비활성을 배경 투명도로 구분해
-- 창 전체 테마와 통일한다(활성=진함, 비활성=투명). 선택 상태는 컨트롤이 아니라
-- g.cupole_preset_tab_index 가 들고 있다
-- tabs are drawn by hand instead of the game tab control: active and inactive are told
-- apart by background opacity, matching the rest of the window. the selection lives in
-- g.cupole_preset_tab_index, not in a control
-- 스크롤바. hideplayer 에서 인게임으로 확인한 값을 그대로 쓴다.
-- 스킨을 안 주면 기본 스킨의 손잡이 폭이 트랙과 안 맞아 오른쪽으로 튀어나온다.
-- x 는 클라가 쓰는 값이 항상 2 다(worldmap2_minimap:227, guide_quest:21, squad_manager:399 등).
-- ⚠️ 위 여백을 주는 API 는 없다(SetScrollBarTopMargin 은 클라 전체에 0건, SetScrollBarOffset 의
-- y 도 위 여백이 아니다) → 스크롤은 위아래로 줄인 안쪽 상자에 맡겨서 여백을 구조로 만든다
-- scrollbar values carried over from hideplayer, verified in game. without an explicit skin the
-- default thumb is wider than the track and hangs off the right edge; the client's x is always 2.
-- there is no top-margin API (SetScrollBarTopMargin does not exist and SetScrollBarOffset's y is
-- not one), so an inner box shrunk top and bottom owns the scrolling and makes the margin structural
local CM_SCROLL_SKIN = "worldmap2_scrollbar"
local CM_SCROLL_X = 2
local CM_SCROLL_MARGIN = 4  -- 스크롤바 위아래 여백 / scrollbar inset
local CM_TAB_COUNT = 10
local CM_TAB_H = 26
local CM_TAB_Y = 68
local CM_TAB_SEP_W = 1
local CM_TAB_ACTIVE_SKIN = "blackbox_op_80"
local CM_TAB_IDLE_SKIN = "None"
-- 각 구역을 창 배경보다 한 단계 어둡게 깔아 눈으로 구분되게 한다(hideplayer 와 같은 방식)
-- each region sits a shade darker than the window so the areas read apart
local CM_SECTION_SKIN = "blackbox_op_50"
local CM_PRESET_SAVE_TEXT = "{ol}{s12}Save"

-- ============================================================
-- Credit line ("made by [guild emblem] name")
--   길드 엠블럼은 UI 이미지가 아니라 서버에서 받아오는 PNG 라서 SetImage 가 아니라
--   picture:SetFileName 으로 붙인다 (colony_battle_info.lua:247-268 계약).
--   글자 폭은 상수로 잡으면 엠블럼과 겹치므로 GetTextWidth 로 재서 오른쪽 정렬한다
--   the guild emblem is a downloaded PNG, not a UI image, so it goes in through
--   picture:SetFileName; the caption width is measured, never guessed, or it overlaps
-- ============================================================
local CM_CREDIT_H = 18
local CM_CREDIT_EMBLEM = 16
local CM_CREDIT_GAP = 3
local CM_CREDIT_PAD = 20
local CM_CREDIT_MADEBY_W = 64   -- GetTextWidth 실패 시 예비 폭 / fallback if the measure fails
local CM_CREDIT_NAME_W = 44
local CM_CREDIT_GUILD_ID = "1038076415618784"    -- 고양이젤리
local CM_CREDIT_WHISPER_NAME = "요매"             -- 표기는 언어별로 바뀌어도 귓말 대상은 실제 팀명

-- ⚠️ GetTextWidth / Resize / SetEventScript 는 캐스팅된 ui::CRichText 에만 있다.
-- AUTO_CAST 없이 부르면 에러가 나고, 그러면 이 컨트롤을 만든 창이 통째로 안 열린다
-- (클라 선례도 전부 tolua.cast / GET_CHILD(...,"ui::CRichText") 후 호출한다)
-- these methods live on a cast ui::CRichText; calling them on an uncast control errors out and
-- the whole window silently fails to open - every client precedent casts first
function CM_credit_render(parent, parent_w, y, pad)
    pad = pad or CM_CREDIT_PAD
    local tip = g.lang == "kr" and "{ol}요매에게 귓속말" or "{ol}Whisper to Yomae"

    local made_by = parent:CreateOrGetControl("richtext", "credit_madeby", pad, y, CM_CREDIT_MADEBY_W, CM_CREDIT_H)
    AUTO_CAST(made_by)
    made_by:SetText("{ol}{s12}{#AAAAAA}made by")

    local name = parent:CreateOrGetControl("richtext", "credit_name", pad, y, CM_CREDIT_NAME_W, CM_CREDIT_H)
    AUTO_CAST(name)
    name:SetText("{ol}{s12}" .. (g.lang == "kr" and "요매" or "Yomae"))

    -- 이름 길이가 언어마다 다르므로(요매 < Yomae) 폭은 상수로 잡지 않고 잰다
    -- the name differs in length per language, so measure instead of assuming
    local made_w = made_by:GetTextWidth()
    if not made_w or made_w <= 0 then
        made_w = CM_CREDIT_MADEBY_W
    end
    local name_w = name:GetTextWidth()
    if not name_w or name_w <= 0 then
        name_w = CM_CREDIT_NAME_W
    end
    made_by:Resize(made_w, CM_CREDIT_H)
    name:Resize(name_w, CM_CREDIT_H)

    local total_w = made_w + CM_CREDIT_GAP + CM_CREDIT_EMBLEM + CM_CREDIT_GAP + name_w
    local cx = math.max(0, parent_w - pad - total_w)
    made_by:SetOffset(cx, y)

    local emblem = parent:CreateOrGetControl("picture", "credit_emblem", cx + made_w + CM_CREDIT_GAP,
        y + math.floor((CM_CREDIT_H - CM_CREDIT_EMBLEM) / 2), CM_CREDIT_EMBLEM, CM_CREDIT_EMBLEM)
    AUTO_CAST(emblem)
    emblem:SetEnableStretch(1)

    name:SetOffset(cx + made_w + CM_CREDIT_GAP + CM_CREDIT_EMBLEM + CM_CREDIT_GAP, y)

    -- 누르면 요매에게 귓속말 (ui.WhisperTo 는 팀명을 받는다 / takes the family name)
    -- 클릭은 picture 에만 건다. 런타임에 만든 richtext 에 SetEventScript 를 거는 선례가
    -- 클라에 0건이고 실제로도 반응하지 않았다. picture 는 확실히 동작한다(HUD 토글 아이콘)
    -- only the picture takes the click: there is no client precedent for SetEventScript on a
    -- runtime-created richtext and it did not fire in game; pictures are proven (the HUD icon)
    emblem:EnableHitTest(true)
    emblem:SetEventScript(ui.LBUTTONUP, "CM_credit_whisper")
    emblem:SetTextTooltip(tip)

    -- 엠블럼은 서버에서 받아오므로 비동기다. 실패하면 글자만 남는다
    -- fetching the emblem is async; on failure only the text remains
    pcall(GetGuildEmblemImage, "CM_credit_emblem_loaded", CM_CREDIT_GUILD_ID)
end

function CM_credit_whisper()
    pcall(ui.WhisperTo, CM_CREDIT_WHISPER_NAME)
end

-- 크레딧은 프리셋 창과 HUD 패널 양쪽에 있으므로 둘 다 갱신한다
-- the credit lives in both the preset window and the HUD panel, so update whichever exists
function CM_credit_emblem_loaded(code, return_json)
    if code ~= 200 then
        return
    end
    local ok_w, world_id = pcall(session.party.GetMyWorldIDStr)
    if not ok_w then
        return
    end
    local ok_n, image_name = pcall(guild.GetEmblemImageName, CM_CREDIT_GUILD_ID, world_id)
    if not ok_n or not image_name then
        return
    end
    local frame_names = {addonNameLower .. "_preset", addonNameLower .. "_hud_panel"}
    for i = 1, #frame_names do
        local frame = ui.GetFrame(frame_names[i])
        if frame then
            local emblem = GET_CHILD(frame, "credit_emblem")
            if emblem then
                emblem:SetImage("")
                emblem:SetFileName(image_name)
            end
        end
    end
end

-- ============================================================
-- Cupole Manager Preset
-- ============================================================
function CM_preset_get_owned_cupoles()
    local owned = {}
    local pc = GetMyPCObject()
    local acc = GetMyAccountObj()
    if not acc then
        return owned
    end
    local list, cnt = GetClassList("cupole_list")
    if not list then
        return owned
    end
    for i = 0, cnt - 1 do
        local cls = GetClassByIndexFromList(list, i)
        if cls then
            local acc_prop = TryGetProp(cls, "AccountProperty", "None")
            local rank = TryGetProp(acc, acc_prop, 0)
            if rank > 0 then
                local icon = TryGetProp(cls, "Icon", "")
                local dec_name = TryGetProp(cls, "Dec_Name", "")
                local grade = TryGetProp(cls, "Grade", "R")
                local class_name = TryGetProp(cls, "ClassName", "")
                table.insert(owned, {
                    index = i,
                    name = dec_name,
                    class_name = class_name,
                    icon = icon,
                    grade = grade
                })
            end
        end
    end
    return owned
end

function CM_preset_get_active_skill_name(cupole_index)
    local pc = GetMyPCObject()
    local skill_cls, grade, rank = GET_CUPOLE_SKILL_INFO(pc, cupole_index, "Active")
    if skill_cls then
        return TryGetProp(skill_cls, "Skill_Name", "None")
    end
    return "None"
end

-- 창 크기와 세로 배치. 섹션 머리글 + 구분선이 들어가면서 520 -> 580 으로 키웠다
-- window size and vertical rhythm; grew 520 -> 580 to fit section headers and dividers
local CM_PW = 560
local CM_PH = 510
local CM_PPAD = 20
local CM_PINNER = CM_PW - CM_PPAD * 2
local CM_PSEC_INSET = 6             -- 구역 패널 안쪽 여백 / padding inside a region panel
local CM_PEDIT_INSET = 6            -- 입력 edit 이 박스 안으로 들어간 양 / how far the edit is inset
-- 이름과 슬롯을 좌우 반반으로 나눈다 / name and slots share the row, split in half
local CM_PHALF_GAP = 10
local CM_PHALF_W = math.floor((CM_PINNER - CM_PHALF_GAP) / 2)
local CM_PRIGHT_X = CM_PPAD + CM_PHALF_W + CM_PHALF_GAP
local CM_PSLOT_X = CM_PPAD + CM_PEDIT_INSET   -- 슬롯 열 시작 = 왼쪽 절반의 글자 기준선

-- 섹션 머리글: HUD 라벨과 같은 white_16_ol 아웃라인 글꼴 + 아래 구분선(labelline)
-- section header: the same outlined white_16_ol as the HUD label, with a divider under it
-- 머리글 + 구분선 + 그 아래 구역 배경(높이를 주면). 배경을 먼저 깔아야 위 컨트롤이 가려지지 않는다
-- header + divider + the region panel underneath (when a height is given).
-- the panel is created first so later controls stay on top (creation order = z-order)
function CM_preset_section(parent, name, x, y, w, text, body_h, no_line)
    local label = parent:CreateOrGetControl("richtext", name .. "_label", x, y, w, 20)
    AUTO_CAST(label)
    label:SetFontName("white_16_ol")
    label:SetText("{s14}" .. text)
    label:EnableHitTest(false)
    -- 바로 아래에 테두리 있는 목록이 오는 구역은 선이 겹쳐 보여서 생략한다
    -- skip the divider where a bordered list follows right below, or the two lines stack
    if not no_line then
        local line = parent:CreateOrGetControl("labelline", name .. "_line", x, y + 20, w, 3)
        AUTO_CAST(line)
        line:SetSkinName("labelline2")
    end
    if body_h then
        local body = parent:CreateOrGetControl("groupbox", name .. "_body", x, y + 25, w, body_h)
        AUTO_CAST(body)
        body:SetSkinName(CM_SECTION_SKIN)
        body:EnableHittestGroupBox(false)
    end
end

-- 현재 선택된 탭. 컨트롤이 없으므로 우리가 들고 있는 값이 진실이다
-- the selected tab; with no tab control, our own value is the source of truth
function CM_preset_tab_index()
    return g.cupole_preset_tab_index or 0
end

-- 탭 스트립을 다시 그린다. 활성 탭만 배경을 진하게 주고 나머지는 투명하게 둔다.
-- 탭 사이에는 얇은 세로 구분선을 넣는다
-- redraw the strip: only the active tab gets a solid-ish background, the rest stay clear,
-- with a thin vertical separator between them
function CM_preset_tabs_render(frame)
    local selected = CM_preset_tab_index()
    local strip = frame:CreateOrGetControl("groupbox", "tab_strip", CM_PINNER, CM_TAB_H + 4, ui.LEFT, ui.TOP,
        CM_PPAD, CM_TAB_Y - 2, 0, 0)
    AUTO_CAST(strip)
    strip:SetSkinName(CM_SECTION_SKIN)
    strip:EnableHittestGroupBox(false)

    local tab_w = math.floor((CM_PINNER - (CM_TAB_COUNT - 1) * CM_TAB_SEP_W) / CM_TAB_COUNT)
    for i = 1, CM_TAB_COUNT do
        local idx = i - 1
        local tx = CM_PPAD + (i - 1) * (tab_w + CM_TAB_SEP_W)
        local preset = g.cupole_manager_settings.presets[tostring(idx)]
        local label = preset and preset.name and preset.name ~= "" and preset.name or ("Set " .. i)
        local btn = frame:CreateOrGetControl("button", "tab_" .. i, tx, CM_TAB_Y, tab_w, CM_TAB_H)
        AUTO_CAST(btn)
        btn:SetSkinName((idx == selected) and CM_TAB_ACTIVE_SKIN or CM_TAB_IDLE_SKIN)
        btn:SetText("{ol}{s12}" .. ((idx == selected) and label or ("{#AAAAAA}" .. label)))
        btn:SetUserValue("TAB_INDEX", idx)
        btn:SetEventScript(ui.LBUTTONUP, "CM_preset_tab_click")
        btn:SetOverSound("button_over")
        if i < CM_TAB_COUNT then
            local sep = frame:CreateOrGetControl("picture", "tab_sep_" .. i, tx + tab_w, CM_TAB_Y + 4,
                CM_TAB_SEP_W, CM_TAB_H - 8)
            AUTO_CAST(sep)
            sep:SetImage("fullblack")
            sep:SetEnableStretch(1)
            sep:EnableHitTest(0)
        end
    end
end

function CM_preset_tab_click(parent, ctrl)
    local idx = ctrl:GetUserIValue("TAB_INDEX")
    g.cupole_preset_tab_index = idx
    local frame = ui.GetFrame(addonNameLower .. "_preset")
    if not frame then
        return
    end
    CM_preset_tabs_render(frame)
    CM_preset_tab_change(frame)
end

function CM_preset_frame_open()
    if not g.cupole_manager_settings then
        CM_load_settings()
    end
    local frame_name = addonNameLower .. "_preset"
    local frame = ui.GetFrame(frame_name)
    if frame and frame:IsVisible() == 1 then
        return
    end
    if not frame then
        frame = ui.CreateNewFrame("notice_on_pc", frame_name, 0, 0, 0, 0)
    end
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(CM_PW, CM_PH)
    frame:SetSkinName(CM_UI_SKIN)
    frame:SetAlpha(CM_UI_ALPHA)
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(92)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)

    local sw, sh = CM_screen_size()
    frame:SetPos((sw - CM_PW) / 2, (sh - CM_PH) / 2)

    -- 반투명 배경 하나로 창 전체를 덮는다(제목 영역까지). groupbox 는 SetAlpha 가 없으므로
    -- 투명도는 스킨으로 낸다 — op_50 계열은 클라에서 13건 전부 groupbox 에 쓰이는 검증된 스킨.
    -- 탭은 자기 스킨으로 그려지므로 배경을 투명하게 해도 그대로 보인다
    -- one translucent panel covers the whole window, title strip included. groupbox has no
    -- SetAlpha, so transparency comes from the skin: every client use of the op_50 family (13)
    -- is on a groupbox. the tab keeps its own skin and renders unaffected
    local bg = frame:CreateOrGetControl("groupbox", "bg", CM_PW, CM_PH, ui.LEFT, ui.TOP, 0, 0, 0, 0)
    AUTO_CAST(bg)
    bg:SetSkinName("None")
    bg:EnableHittestGroupBox(false)

    -- 제목도 섹션 머리글과 같은 왼쪽 기준선(CM_PPAD)에 맞춘다
    -- the title lines up with the section headers on the same left edge
    local title = frame:CreateOrGetControl("richtext", "title", CM_PINNER, 30, ui.LEFT, ui.TOP, CM_PPAD, 18, 0, 0)
    AUTO_CAST(title)
    title:SetText("{@st43}{s22}Cupole Preset Setting{/}")
    title:EnableHitTest(false)

    -- 제목과 본문을 가르는 구분선 (섹션 머리글과 같은 스킨으로 톤을 맞춘다)
    -- divider under the title, same skin as the section headers
    local title_line = frame:CreateOrGetControl("labelline", "title_line", CM_PPAD, 54, CM_PINNER, 3)
    AUTO_CAST(title_line)
    title_line:SetSkinName("labelline2")

    -- 닫기 버튼은 제목 글자와 세로 중앙을 맞춘다(제목 18~48, 중앙 33).
    -- 44px 이면 아래가 제목 구분선(54)에 닿아서 36px 로 줄였다
    -- centre the close button on the title text (18~48, centre 33); at 44px its bottom
    -- touched the title divider at 54, so it is 36px now
    local close = frame:CreateOrGetControl("button", "close", 36, 36, ui.RIGHT, ui.TOP, 0, 15, 17, 0)
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetEventScript(ui.LBUTTONUP, "CM_preset_frame_close")

    CM_preset_tabs_render(frame)

    CM_preset_section(frame, "sec_slot", CM_PPAD, 112, CM_PHALF_W, "SLOTS", 140)

    -- 투명 배경에선 edit 스킨(inventory_serch)이 배경에 묻히고 아래가 잘려 보였다.
    -- 클라 search_editbox 방식: 보이는 박스(groupbox)를 깔고 그 안에 skin 없는 edit 을 넣는다
    -- on a translucent background the edit skin blended in and looked clipped at the bottom;
    -- use the client's search_editbox shape: a visible box with a skinless edit inset in it
    -- 구역 패널과 폭이 같으면 경계가 안 보인다. 안쪽으로 넣고 한 단계 더 진한 스킨을 준다
    -- same width as the region panel means no visible edge: inset it and go a shade darker
    local name_bg = frame:CreateOrGetControl("groupbox", "name_bg", CM_PHALF_W - CM_PSEC_INSET * 2, 28, ui.LEFT,
        ui.TOP, CM_PRIGHT_X + CM_PSEC_INSET, 144, 0, 0)
    AUTO_CAST(name_bg)
    name_bg:SetSkinName("blackbox_op_80")
    name_bg:EnableHitTest(0)

    local name_edit = frame:CreateOrGetControl("edit", "name_edit", CM_PRIGHT_X + CM_PSEC_INSET + CM_PEDIT_INSET, 149,
        CM_PHALF_W - (CM_PSEC_INSET + CM_PEDIT_INSET) * 2, 20)
    AUTO_CAST(name_edit)
    name_edit:SetSkinName("None")
    name_edit:SetFontName("white_14_ol")
    name_edit:SetTextAlign("left", "center")

    CM_preset_section(frame, "sec_name", CM_PRIGHT_X, 112, CM_PHALF_W, "NAME", 140)

    local slot_positions = {[2] = 0, [1] = 1, [3] = 2}
    local slot_labels = {[1] = "Center", [2] = "Left", [3] = "Right"}
    -- 슬롯 열의 시작을 이름 입력칸 '글자'와 같은 선에 맞춘다. 입력 edit 이 박스 안쪽으로
    -- 6px 들어가 있으므로 슬롯도 그만큼 오른쪽으로 민다
    -- start the slot column on the same line as the name field's *text*: the edit is inset 6px
    -- inside its box, so the slots shift right by the same amount
    for slot = 1, 3 do
        -- 슬롯 3칸(60px + 간격 20)을 구역 폭 안에서 가운데로 모은다
        -- centre the three 60px slots (20px apart) inside the region
        local slot_span = 3 * 60 + 2 * 20
        local slot_x0 = CM_PPAD + math.floor((CM_PHALF_W - slot_span) / 2)
        local sx = slot_x0 + slot_positions[slot] * 80
        local slot_label = frame:CreateOrGetControl("richtext", "slot_label_" .. slot, sx, 138, 60, 12)
        AUTO_CAST(slot_label)
        slot_label:SetText("{ol}{s11}{#aaaaaa}" .. slot_labels[slot])
        slot_label:EnableHitTest(false)
        local border = frame:CreateOrGetControl("picture", "slot_border_" .. slot, sx - 3, 150, 66, 66)
        AUTO_CAST(border)
        border:SetImage("cupole_grade_frame_R")
        border:SetEnableStretch(1)
        border:EnableHitTest(0)
        local pic = frame:CreateOrGetControl("picture", "slot_" .. slot, sx, 153, 60, 60)
        AUTO_CAST(pic)
        pic:SetSkinName("inven_slot")
        pic:SetUserValue("SLOT_INDEX", slot)
        pic:SetEventScript(ui.LBUTTONUP, "CM_preset_slot_click")
        pic:SetEventScript(ui.RBUTTONUP, "CM_preset_slot_clear")
        local slot_name = frame:CreateOrGetControl("richtext", "slot_name_" .. slot, sx, 218, 60, 20)
        AUTO_CAST(slot_name)
        slot_name:SetText("{ol}{s12}{#999999}Empty")
        slot_name:EnableHitTest(false)
    end

    local selected_mark = frame:CreateOrGetControl("richtext", "selected_mark", CM_PPAD, 274, 300, 16)
    AUTO_CAST(selected_mark)
    selected_mark:SetText("")
    selected_mark:EnableHitTest(false)

    -- 버튼은 오른쪽 정렬 + 간격 동일. 폭이 제각각이라 절대좌표로 두면 간격이 들쭉날쭉해 보인다
    -- right-aligned with one shared gap: with mixed widths, hard-coded x values look uneven
    -- 버튼 4개를 이름칸 바로 아래, 오른쪽 절반 폭에 딱 맞게 편다.
    -- 남는 자리를 간격으로 나눠 쓰므로 폭을 바꿔도 양끝이 이름칸과 정렬된 채로 유지된다
    -- the four buttons sit right under the name field and span exactly the right half:
    -- leftover space becomes the gap, so both ends stay flush with the name box
    -- 버튼은 두 무리로 나뉜다: 프리셋을 '쓰는' 쪽은 슬롯 열 오른쪽 끝에, '고치는' 쪽은
    -- 이름 열 오른쪽 끝에 맞춘다. 아래끝은 왼쪽 슬롯 이름 줄과 같은 선(238)
    -- two groups: the "use it" pair aligns to the right edge of the slots column, the
    -- "edit it" pair to the right edge of the name column; both bottoms land on 238
    local btn_gap = 8
    local btn_groups = {
        {right = CM_PPAD + CM_PHALF_W - CM_PSEC_INSET * 2, items = {
            {name = "apply_btn", w = 42, text = "{ol}{s12}Use", scp = "CM_preset_apply"},
            {name = "load_btn", w = 88, text = "{ol}{s12}Load Current", scp = "CM_preset_load_current"}
        }},
        {right = CM_PRIGHT_X + CM_PHALF_W - CM_PSEC_INSET, items = {
            {name = "save_btn", w = 42, text = CM_PRESET_SAVE_TEXT, scp = "CM_preset_save"},
            {name = "delete_btn", w = 42, text = "{ol}{s12}{#ff6666}Del", scp = "CM_preset_delete"}
        }}
    }
    for gi = 1, #btn_groups do
        local group = btn_groups[gi]
        local total = (#group.items - 1) * btn_gap
        for i = 1, #group.items do
            total = total + group.items[i].w
        end
        local bx = group.right - total
        for i = 1, #group.items do
            local item = group.items[i]
            local btn = frame:CreateOrGetControl("button", item.name, bx, 246, item.w, 26)
            AUTO_CAST(btn)
            btn:SetText(item.text)
            btn:SetOverSound("button_over")
            btn:SetClickSound("button_click_stats")
            btn:SetEventScript(ui.LBUTTONUP, item.scp)
            bx = bx + item.w + btn_gap
        end
    end

    -- 위쪽(슬롯·이름) 영역과 아래 보유 목록을 가르는 구분선
    -- divides the slots/name area above from the owned list below
    local split_line = frame:CreateOrGetControl("labelline", "sec_split_line", CM_PPAD, 292, CM_PINNER, 3)
    AUTO_CAST(split_line)
    split_line:SetSkinName("labelline2")

    CM_preset_section(frame, "sec_grid", CM_PPAD, 296, CM_PINNER, "OWNED CUPOLES", nil, true)

    -- 등급 필터도 같은 간격으로 오른쪽 정렬해 머리글 줄에 붙인다
    -- the grade filters share the header row, right-aligned with one gap
    local filter_grades = {"All", "UR", "SR", "R"}
    local filter_w, filter_gap = 50, 6
    local fx = CM_PW - CM_PPAD - (#filter_grades * filter_w + (#filter_grades - 1) * filter_gap)
    for fi, grade in ipairs(filter_grades) do
        local fbtn = frame:CreateOrGetControl("button", "filter_" .. grade, fx, 294, filter_w, 22)
        AUTO_CAST(fbtn)
        local grade_colors = {All = "ffffff", UR = "ffcc33", SR = "cc66ff", R = "66ccff"}
        fbtn:SetText("{ol}{s12}{#" .. grade_colors[grade] .. "}" .. grade)
        fbtn:SetUserValue("FILTER_GRADE", grade)
        fbtn:SetEventScript(ui.LBUTTONUP, "CM_preset_filter_click")
        fbtn:SetOverSound("button_over")
        fbtn:SetClickSound("button_click_stats")
        fx = fx + filter_w + filter_gap
    end

    -- 보유 쿠폴 목록은 테두리가 있어야 영역이 구분된다. downbox 가 클라의 "움푹한 영역" 스킨
    -- the owned list needs a visible edge; downbox is the client's inset-area skin
    local grid = frame:CreateOrGetControl("groupbox", "cupole_grid", CM_PINNER, 155, ui.LEFT, ui.TOP, CM_PPAD, 322, 0,
        0)
    AUTO_CAST(grid)
    grid:SetSkinName(CM_SECTION_SKIN)
    grid:EnableScrollBar(0)
    grid:EnableHittestGroupBox(true)

    -- 목록과 스크롤바는 안쪽 상자가 맡는다. 위아래로 CM_SCROLL_MARGIN 만큼 줄여 놓았으므로
    -- 트랙이 그만큼 안으로 들어오고 위아래 여백이 같아진다. 테두리는 바깥 상자가 이미 그렸다
    -- the inner box owns the list and the scrollbar; shrunk by CM_SCROLL_MARGIN top and bottom so
    -- the track sits inset with matching margins. the outer box already drew the border
    local grid_scroll = grid:CreateOrGetControl("groupbox", "cupole_grid_scroll", 0, CM_SCROLL_MARGIN,
        CM_PINNER, 155 - CM_SCROLL_MARGIN * 2)
    AUTO_CAST(grid_scroll)
    grid_scroll:SetSkinName("None")
    grid_scroll:EnableScrollBar(1)
    grid_scroll:EnableHittestGroupBox(true)
    -- 순서도 클라와 같게: 스킨을 먼저 정하고 나서 여백/오프셋을 준다.
    -- 아래 여백은 안쪽 상자가 이미 만들었으므로 0
    -- same order as the client: skin first, then margin and offset. the bottom margin already
    -- comes from the inner box, so 0 here
    grid_scroll:SetScrollBarSkinName(CM_SCROLL_SKIN)
    grid_scroll:SetScrollBarBottomMargin(0)
    grid_scroll:SetScrollBarOffset(CM_SCROLL_X, 0)

    g.cupole_preset_filter_grade = "All"

    -- 장식용이므로 실패해도 창은 열려야 한다 / decorative: must never take the window down
    pcall(CM_credit_render, frame, CM_PW, 482)

    local esc_timer = frame:CreateOrGetControl("timer", "preset_esc_timer", 0, 0)
    AUTO_CAST(esc_timer)
    esc_timer:SetUpdateScript("CM_preset_esc_check")
    esc_timer:Start(0.05)

    g.cupole_preset_selected_slot = nil
    frame:ShowWindow(1)
    CM_preset_tab_change(frame)
end

-- 톱니를 다시 누르면 닫힌다(잘못 눌렀을 때 되돌리기)
-- pressing the gear again closes it, so a mis-click is easy to undo
function CM_preset_frame_toggle()
    local frame = ui.GetFrame(addonNameLower .. "_preset")
    if frame and frame:IsVisible() == 1 then
        CM_preset_frame_close()
        return
    end
    CM_preset_frame_open()
end

-- 창을 파괴하지 않고 숨긴다. 파괴/재생성은 즉시 사라지지만 show/hide 는 프레임 연출을 타서
-- hideplayer 설정창과 여닫는 느낌이 같아진다
-- hide instead of destroying: destroy/recreate pops instantly, while show/hide goes
-- through the frame transition, matching how the hideplayer settings window opens
function CM_preset_frame_close()
    local frame = ui.GetFrame(addonNameLower .. "_preset")
    if frame then
        frame:ShowWindow(0)
    end
end

function CM_preset_esc_check(frame)
    -- 이제 창은 숨겨질 뿐 살아 있으므로 타이머도 계속 돈다. 보이는 동안만 반응한다
    -- the frame now survives hidden, so this timer keeps ticking: only act while visible
    if frame:IsVisible() ~= 1 then
        return
    end
    if keyboard.IsKeyPressed("ESCAPE") == 1 then
        CM_preset_frame_close()
    end
end

function CM_preset_tab_change(frame)
    local tab_index = CM_preset_tab_index()
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]

    local name_edit = GET_CHILD(frame, "name_edit")
    AUTO_CAST(name_edit)
    if preset and preset.name then
        name_edit:SetText(preset.name)
    else
        name_edit:SetText("")
    end

    g.cupole_preset_selected_slot = nil
    local selected_mark = GET_CHILD(frame, "selected_mark")
    selected_mark:SetText("")

    CM_preset_update_slot_borders(frame)
    CM_preset_render_slots(frame, tab_index)
    CM_preset_render_grid(frame)
    local save_btn = GET_CHILD(frame, "save_btn")
    AUTO_CAST(save_btn)
    save_btn:SetText(CM_PRESET_SAVE_TEXT)
end

function CM_preset_render_slots(frame, tab_idx)
    local preset = g.cupole_manager_settings.presets[tostring(tab_idx)]
    for slot = 1, 3 do
        local pic = GET_CHILD(frame, "slot_" .. slot)
        AUTO_CAST(pic)
        pic:SetImage("")
        local slot_name = GET_CHILD(frame, "slot_name_" .. slot)

        if preset and preset[tostring(slot)] then
            local data = preset[tostring(slot)]
            local cupole_cls = GET_CUPOLE_BY_INDEX_IN_CLASSLIST(data.id)
            if cupole_cls then
                local icon = TryGetProp(cupole_cls, "Icon", "")
                local dec_name = TryGetProp(cupole_cls, "Dec_Name", "")
                if icon ~= "" then
                    pic:SetImage(icon)
                    pic:SetEnableStretch(1)
                end
                slot_name:SetText("{ol}{s11}" .. dec_name)
            else
                slot_name:SetText("{ol}{s11}{#ff5555}Missing")
            end
        else
            slot_name:SetText("{ol}{s12}{#999999}Empty")
        end
    end
end

function CM_preset_filter_click(parent, ctrl)
    local frame = ctrl:GetTopParentFrame()
    local grade = ctrl:GetUserValue("FILTER_GRADE")
    g.cupole_preset_filter_grade = grade
    CM_preset_render_grid(frame)
end

function CM_preset_render_grid(frame)
    -- 스크롤 상자는 cupole_grid 의 자식이므로 GET_CHILD(비재귀)로는 못 찾는다
    -- the scrolling box is a child of cupole_grid, so the non-recursive GET_CHILD misses it
    local grid = GET_CHILD_RECURSIVELY(frame, "cupole_grid_scroll")
    if grid == nil then
        return
    end
    AUTO_CAST(grid)
    grid:RemoveAllChild()
    local all_owned = CM_preset_get_owned_cupoles()
    local filter = g.cupole_preset_filter_grade or "All"
    local owned = {}
    for _, cupole in ipairs(all_owned) do
        if filter == "All" or cupole.grade == filter then
            table.insert(owned, cupole)
        end
    end
    local cols = 6
    local cell_w = 82
    local cell_h = 75
    local pad = 5
    for i, cupole in ipairs(owned) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = pad + col * cell_w
        local cy = pad + row * cell_h

        local cell = grid:CreateOrGetControl("groupbox", "cell_" .. i, cx, cy, cell_w - 4, cell_h - 4)
        AUTO_CAST(cell)
        cell:SetSkinName("None")
        cell:EnableHittestGroupBox(true)
        cell:SetUserValue("CUPOLE_INDEX", cupole.index)
        cell:SetUserValue("CUPOLE_NAME", cupole.class_name)
        cell:SetEventScript(ui.LBUTTONUP, "CM_preset_grid_click")

        local pic = cell:CreateOrGetControl("picture", "icon_" .. i, (cell_w - 4 - 50) / 2, 2, 50, 50)
        AUTO_CAST(pic)
        if cupole.icon ~= "" then
            pic:SetImage(cupole.icon)
            pic:SetEnableStretch(1)
        end
        pic:EnableHitTest(0)

        local name_rt = cell:CreateOrGetControl("richtext", "name_" .. i, 0, 54, cell_w - 4, 16)
        AUTO_CAST(name_rt)
        local grade_color = "ffffff"
        if cupole.grade == "UR" then
            grade_color = "ffcc33"
        elseif cupole.grade == "SR" then
            grade_color = "cc66ff"
        elseif cupole.grade == "R" then
            grade_color = "66ccff"
        end
        name_rt:SetText("{ol}{s10}{#" .. grade_color .. "}" .. cupole.name)
        name_rt:SetTextAlign("center", "center")   -- 아이콘 아래 이름 가운데 정렬 / centered under the icon
        name_rt:EnableHitTest(0)
    end
    grid:SetScrollPos(0)
    grid:Invalidate()
end

function CM_preset_update_slot_borders(frame)
    for s = 1, 3 do
        local border = GET_CHILD(frame, "slot_border_" .. s)
        AUTO_CAST(border)
        if g.cupole_preset_selected_slot == s then
            border:SetImage("cupole_grade_frame_UR")
        else
            border:SetImage("cupole_grade_frame_R")
        end
        border:SetEnableStretch(1)
    end
end

function CM_preset_slot_click(parent, ctrl)
    local frame = ctrl:GetTopParentFrame()
    local slot_index = ctrl:GetUserIValue("SLOT_INDEX")
    local selected_mark = GET_CHILD(frame, "selected_mark")
    if g.cupole_preset_selected_slot == slot_index then
        g.cupole_preset_selected_slot = nil
        selected_mark:SetText("")
    else
        g.cupole_preset_selected_slot = slot_index
        local slot_labels = {[1] = "Center", [2] = "Left", [3] = "Right"}
        selected_mark:SetText("{ol}{s12}{#00ccff}" .. slot_labels[slot_index] .. " selected - click a Cupole below to assign")
    end
    CM_preset_update_slot_borders(frame)
end

function CM_preset_slot_clear(parent, ctrl)
    local frame = ctrl:GetTopParentFrame()
    local slot_index = ctrl:GetUserIValue("SLOT_INDEX")
    local tab_index = CM_preset_tab_index()
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]
    if preset and preset[tostring(slot_index)] then
        preset[tostring(slot_index)] = nil
        CM_preset_render_slots(frame, tab_index)
    end
end

function CM_preset_grid_click(parent, ctrl)
    local frame = ctrl:GetTopParentFrame()
    local tab_index = CM_preset_tab_index()
    if not g.cupole_preset_selected_slot then
        if not g.cupole_manager_settings.presets[tostring(tab_index)] then
            g.cupole_manager_settings.presets[tostring(tab_index)] = {}
        end
        local preset = g.cupole_manager_settings.presets[tostring(tab_index)]
        local fill_order = {2, 1, 3}
        local target = nil
        for _, s in ipairs(fill_order) do
            if not preset[tostring(s)] then
                target = s
                break
            end
        end
        if not target then
            ui.SysMsg("[Cupole Preset] All slots are filled. Click a slot to replace.")
            return
        end
        g.cupole_preset_selected_slot = target
    end
    local frame = ctrl:GetTopParentFrame()
    local tab_index = CM_preset_tab_index()
    local cupole_index = ctrl:GetUserIValue("CUPOLE_INDEX")
    local cupole_name = ctrl:GetUserValue("CUPOLE_NAME")

    if not g.cupole_manager_settings.presets[tostring(tab_index)] then
        g.cupole_manager_settings.presets[tostring(tab_index)] = {}
    end
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]

    for s = 1, 3 do
        if preset[tostring(s)] and preset[tostring(s)].id == tostring(cupole_index) then
            if s ~= g.cupole_preset_selected_slot then
                local current_in_target = preset[tostring(g.cupole_preset_selected_slot)]
                preset[tostring(s)] = current_in_target
            end
            break
        end
    end

    preset[tostring(g.cupole_preset_selected_slot)] = {
        id = tostring(cupole_index),
        name = cupole_name
    }

    g.cupole_preset_selected_slot = nil
    local selected_mark = GET_CHILD(frame, "selected_mark")
    selected_mark:SetText("")
    CM_preset_update_slot_borders(frame)
    CM_preset_render_slots(frame, tab_index)
end

function CM_preset_load_current(frame, ctrl)
    local equip_cupole_list = GET_EQUIP_CUPOLE_LIST()
    for i = 1, 3 do
        if equip_cupole_list[CM_equip_index(i)] == "-1" then
            ui.SysMsg("[Cupole Preset] 3 Cupoles must be equipped to load")
            return
        end
    end
    local tab_index = CM_preset_tab_index()
    if not g.cupole_manager_settings.presets[tostring(tab_index)] then
        g.cupole_manager_settings.presets[tostring(tab_index)] = {}
    end
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]
    for i = 1, 3 do
        local cupole_cls = GET_CUPOLE_BY_INDEX_IN_CLASSLIST(equip_cupole_list[CM_equip_index(i)])
        local cupole_class_name = TryGetProp(cupole_cls, "ClassName", "None")
        preset[tostring(i)] = {
            id = equip_cupole_list[CM_equip_index(i)],
            name = cupole_class_name
        }
    end
    CM_preset_render_slots(frame, tab_index)
    ui.SysMsg("[Cupole Preset] Current Cupoles loaded to slots (press Save to keep)")
end

-- Rebuild the editor so the top tab labels refresh (the tab control does not
-- repaint in place after ClearItem/AddItem). DestroyFrame is DEFERRED, so we
-- must close on one tick and reopen on the next -- recreating in the same event
-- lets the pending destroy clobber the new frame (window just closes). Driven
-- by the always-alive main "cupole_manager" frame.
function CM_preset_reopen(frame, tab_index)
    g.cupole_preset_reopen = { index = tab_index, x = frame:GetX(), y = frame:GetY(), phase = 0 }
    local mf = ui.GetFrame("cupole_manager")
    if mf then
        mf:RunUpdateScript("CM_preset_reopen_step", 0.02)
    end
end

function CM_preset_reopen_step(mf)
    local st = g.cupole_preset_reopen
    if not st then
        mf:StopUpdateScript("CM_preset_reopen_step")
        return 0
    end
    if st.phase == 0 then
        CM_preset_frame_close()   -- queue destroy of the old frame
        st.phase = 1
        return 1                  -- wait one tick for the destroy to flush
    end
    mf:StopUpdateScript("CM_preset_reopen_step")
    g.cupole_preset_reopen = nil
    CM_preset_frame_open()
    local nf = ui.GetFrame(addonNameLower .. "_preset")
    if nf then
        nf:SetPos(st.x, st.y)
        g.cupole_preset_tab_index = st.index
        CM_preset_tabs_render(nf)
        CM_preset_tab_change(nf)
    end
    return 0
end

function CM_preset_save(frame, ctrl)
    local tab_index = CM_preset_tab_index()
    if not g.cupole_manager_settings.presets[tostring(tab_index)] then
        g.cupole_manager_settings.presets[tostring(tab_index)] = {}
    end
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]
    local name_edit = GET_CHILD(frame, "name_edit")
    AUTO_CAST(name_edit)
    local set_name = name_edit:GetText()
    if not set_name or set_name == "" then
        set_name = "Set " .. (tab_index + 1)
        name_edit:SetText(set_name)
    end
    preset.name = set_name
    CM_save_settings()
    CM_hud_refresh()
    ui.SysMsg("[Cupole Preset] Saved: " .. set_name)
    CM_preset_reopen(frame, tab_index)
end

-- fully removes the preset (name + slots) from settings
function CM_preset_delete(frame, ctrl)
    local tab_index = CM_preset_tab_index()
    g.cupole_manager_settings.presets[tostring(tab_index)] = nil
    CM_save_settings()
    CM_hud_refresh()
    ui.SysMsg("[Cupole Preset] Deleted Set " .. (tab_index + 1))
    CM_preset_reopen(frame, tab_index)
end

function CM_preset_apply(frame, ctrl)
    local tab_index = CM_preset_tab_index()
    CM_preset_apply_by_index(tab_index)
end

function CM_preset_apply_by_index(tab_index)
    if g.cupole_preset_apply_num and g.cupole_preset_apply_num < 3 then
        ui.SysMsg("[Cupole Preset] Apply is already in progress")
        return
    end
    if CM_get_map_type() ~= "City" then
        ui.SysMsg("[Cupole Preset] Cupoles can only be changed in town")
        return
    end
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]
    if not preset or not preset["1"] or not preset["2"] or not preset["3"] then
        ui.SysMsg("[Cupole Preset] All 3 slots must be filled before applying")
        return
    end
    for i = 1, 3 do
        local cupole_id = tonumber(preset[tostring(i)].id)
        local cls = GET_CUPOLE_CLASS_BY_INDEX(cupole_id)
        if not cls then
            ui.SysMsg("[Cupole Preset] Slot " .. i .. " Cupole not found")
            return
        end
        local acc = GetMyAccountObj()
        local acc_prop = TryGetProp(cls, "AccountProperty", "None")
        local rank = TryGetProp(acc, acc_prop, 0)
        if rank == 0 then
            local dec_name = TryGetProp(cls, "Dec_Name", "Unknown")
            ui.SysMsg("[Cupole Preset] " .. dec_name .. " is not owned")
            return
        end
    end

    g.cupole_preset_alive_before = {}
    for i = 1, MAX_QUICKSLOT_CNT do
        local slot_info = quickslot.GetInfoByIndex(i - 1)
        if slot_info and slot_info.category == "Skill" and session.GetSkill(slot_info.type) then
            g.cupole_preset_alive_before[i] = slot_info.type
        end
    end

    g.cupole_preset_new_skill_name = CM_preset_get_active_skill_name(tonumber(preset["1"].id))

    g.cupole_preset_apply_tbl = preset
    g.cupole_preset_apply_num = 0

    local overlay_name = addonNameLower .. "_overlay"
    local overlay = ui.CreateNewFrame("chat_memberlist", overlay_name, 0, 0, 0, 0)
    AUTO_CAST(overlay)
    overlay:RemoveAllChild()
    overlay:SetSkinName("None")
    overlay:SetTitleBarSkin("None")
    local sw, sh = CM_screen_size()
    overlay:Resize(sw, sh)
    overlay:SetPos(0, 0)
    overlay:SetLayerLevel(999)
    overlay:EnableHittestFrame(1)
    overlay:EnableMove(0)
    local msg = overlay:CreateOrGetControl("richtext", "msg", 0, 0, sw, 40)
    msg:SetGravity(ui.CENTER_HORZ, ui.CENTER_VERT)
    msg:SetText("{@st43}{s24}{#ffcc33}{ol}Applying Cupole Preset...{/}")
    msg:SetTextAlign("center", "center")
    msg:EnableHitTest(0)
    overlay:SetUserValue("OVERLAY_TIMEOUT", 0)
    overlay:RunUpdateScript("CM_preset_overlay_check", 0.5)
    overlay:ShowWindow(1)

    local cm_frame = ui.GetFrame("cupole_manager")
    cm_frame:RunUpdateScript("CM_preset_summon", 0.3)
    ui.SysMsg("[Cupole Preset] Applying preset...")
end

-- ============================================================
-- Preset HUD (toggle button + separate compact preset panel)
--   Two frames: the toggle button frame is created once and never
--   destroyed (so clicking it can't make it vanish); the panel frame
--   is (re)built / destroyed on toggle. Position + open state persist.
-- ============================================================
local CM_HUD_ICON_W = 51    -- on/off toggle icon (matches tosfighter pvpmodeBtn 51x22)
local CM_HUD_ICON_H = 22
local CM_HUD_ICON_MARGIN = 12   -- gap from the right edge (keeps icon off the border)
local CM_HUD_BTN_W = 152    -- toggle bar width == list panel width below (gear + on/off icon)
local CM_HUD_GEAR = 24      -- 프리셋 설정창을 여는 톱니 버튼 / gear that opens the preset window
local CM_HUD_BTN_H = 40
local CM_HUD_ROW_H = 24
local CM_HUD_GAP = 3
local CM_HUD_PAD = 6
local CM_HUD_ALPHA = CM_UI_ALPHA    -- translucency (tosfighter uses ~50; lower = more see-through)
local CM_HUD_POS_VER = 4    -- bump to re-apply the default start position on next load

function CM_hud_get_rows()
    local presets = g.cupole_manager_settings.presets or {}
    local rows = {}
    for idx = 0, 9 do
        local p = presets[tostring(idx)]
        if p and p["1"] and p["2"] and p["3"] then
            local label = p.name and p.name ~= "" and p.name or ("Set " .. (idx + 1))
            table.insert(rows, {idx = idx, label = label})
        end
    end
    return rows
end

-- far-right edge, vertically centered (tosfighter-style)
function CM_hud_default_pos(hud)
    local sw, sh = CM_screen_size()
    hud.x = sw - CM_HUD_BTN_W - 4
    hud.y = math.floor(sh / 2) - math.floor(CM_HUD_BTN_H / 2)
end

-- reflect open/closed state on the toggle bar: ability on/off icon
function CM_hud_set_toggle_visual(frame, open)
    local icon = GET_CHILD(frame, "hud_icon")
    if icon then
        icon:SetImage((open == 1) and "ability_on" or "ability_off")
    end
    local label = GET_CHILD(frame, "hud_label")
    if label then
        local name = g.lang == "Japanese" and "クポル{nl}プリセット" or "Cupole{nl}Preset"
        label:SetText("{s10}" .. name)   -- small, tosfighter-sized
    end
end

-- destroy both HUD frames (used when leaving town)
function CM_hud_destroy()
    local names = { addonNameLower .. "_hud_panel", addonNameLower .. "_hud" }
    for _, name in ipairs(names) do
        if ui.GetFrame(name) then
            ui.DestroyFrame(name)
        end
    end
end

-- creates the always-visible toggle button frame (idempotent)
function CM_hud_create()
    if not g.cupole_manager_settings then
        return
    end
    local hud = g.cupole_manager_settings.hud
    if not hud then
        hud = { open = 0 }
        g.cupole_manager_settings.hud = hud
    end

    -- (re)apply default start position when the layout version changes
    if hud.ver ~= CM_HUD_POS_VER then
        CM_hud_default_pos(hud)
        hud.ver = CM_HUD_POS_VER
        CM_save_settings()
    end
    -- heal invalid / off-screen positions
    local sw, sh = CM_screen_size()
    if type(hud.x) ~= "number" or type(hud.y) ~= "number" or
        hud.x < 0 or hud.x > sw - 20 or hud.y < 0 or hud.y > sh - 20 then
        CM_hud_default_pos(hud)
        CM_save_settings()
    end

    local frame_name = addonNameLower .. "_hud"
    local frame = ui.GetFrame(frame_name)
    if not frame then
        frame = ui.CreateNewFrame("notice_on_pc", frame_name, 0, 0, 0, 0)
    end
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(CM_HUD_BTN_W, CM_HUD_BTN_H)
    frame:SetSkinName(CM_UI_SKIN)     -- translucent bar background (with SetAlpha)
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(90)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)
    frame:SetPos(hud.x, hud.y)
    frame:SetAlpha(CM_HUD_ALPHA)
    -- drag: frame handles move + position save (LBUTTONUP fires on the frame
    -- only when it was dragged; a plain click routes to the icon below)
    frame:SetEventScript(ui.LBUTTONUP, "CM_hud_drag")

    -- title label on the LEFT, two lines, vertically centered (tosfighter
    -- style). Hit test OFF so drags on it pass through to the frame.
    local label = frame:CreateOrGetControl("richtext", "hud_label", CM_HUD_BTN_W - CM_HUD_ICON_W -
        CM_HUD_ICON_MARGIN - CM_HUD_GEAR - 20, 30, ui.LEFT, ui.CENTER_VERT, 8, 0, 0, 0)
    label:SetFontName("white_16_ol")
    label:EnableHitTest(false)

    -- 프리셋 설정창을 여는 톱니 버튼. 노리산 메뉴 항목을 뺐으므로 이게 유일한 진입점이다.
    -- on/off 아이콘 왼쪽에 두고, 드래그를 먹지 않게 button 이 아니라 picture 로 만든다
    -- gear that opens the preset window; with the menu entry gone this is the only way in.
    -- sits left of the on/off icon and is a picture, not a button, so drags still work
    local gear = frame:CreateOrGetControl("picture", "hud_gear", CM_HUD_GEAR, CM_HUD_GEAR, ui.RIGHT, ui.CENTER_VERT, 0,
        0, CM_HUD_ICON_MARGIN + CM_HUD_ICON_W + 6, 0)
    AUTO_CAST(gear)
    gear:SetImage("config_button_normal")
    gear:SetEnableStretch(1)
    gear:EnableHitTest(1)
    gear:SetTextTooltip(g.lang == "kr" and "{ol}쿠폴 프리셋 설정" or
                            (g.lang == "Japanese" and "{ol}クポルプリセット設定" or "{ol}Cupole preset settings"))
    gear:SetEventScript(ui.LBUTTONUP, "CM_preset_frame_toggle")

    -- clickable toggle icon on the RIGHT, vertically centered: a PICTURE (not a
    -- button) so it does not capture the mouse and block frame dragging
    -- (tosfighter/norisan pattern). Shows ability_on (open) / ability_off (closed).
    -- args: w, h, gravH, gravV, marginLeft, marginTop, marginRight, marginBottom.
    -- With ui.RIGHT the gap comes from marginRight (7th arg), NOT marginLeft.
    local icon = frame:CreateOrGetControl("picture", "hud_icon", CM_HUD_ICON_W, CM_HUD_ICON_H, ui.RIGHT, ui.CENTER_VERT, 0, 0, CM_HUD_ICON_MARGIN, 0)
    AUTO_CAST(icon)
    icon:SetEnableStretch(1)
    icon:EnableHitTest(1)
    icon:SetTextTooltip(g.lang == "Japanese" and "{ol}クポルプリセット 開閉" or "{ol}Toggle Cupole presets")
    icon:SetEventScript(ui.LBUTTONUP, "CM_hud_toggle")

    CM_hud_set_toggle_visual(frame, hud.open)

    frame:ShowWindow(1)

    CM_hud_panel_render()
end

-- (re)builds or destroys the preset panel frame based on open state
function CM_hud_panel_render()
    local hud = g.cupole_manager_settings and g.cupole_manager_settings.hud
    if not hud then
        return
    end
    local panel_name = addonNameLower .. "_hud_panel"
    if ui.GetFrame(panel_name) then
        ui.DestroyFrame(panel_name)
    end
    if hud.open ~= 1 then
        return
    end

    local rows = CM_hud_get_rows()
    local n = #rows
    local inner_h = (n == 0) and 22 or (n * (CM_HUD_ROW_H + CM_HUD_GAP) - CM_HUD_GAP)
    local panel_w = CM_HUD_BTN_W                     -- same width as the toggle bar
    local row_w = CM_HUD_BTN_W - CM_HUD_PAD * 2
    local panel_h = inner_h + CM_HUD_PAD * 2 + CM_CREDIT_H + CM_HUD_GAP

    local _, sh = CM_screen_size()
    local px = hud.x
    local py = hud.y + CM_HUD_BTN_H + 2
    if py + panel_h > sh then
        py = math.max(0, sh - panel_h)
    end

    local panel = ui.CreateNewFrame("notice_on_pc", panel_name, 0, 0, 0, 0)
    AUTO_CAST(panel)
    panel:RemoveAllChild()
    panel:Resize(panel_w, panel_h)
    panel:SetSkinName(CM_UI_SKIN)     -- translucent window background (with SetAlpha)
    panel:SetTitleBarSkin("None")
    panel:SetLayerLevel(90)
    panel:EnableHittestFrame(1)
    panel:EnableMove(0)
    panel:SetPos(px, py)
    panel:SetAlpha(CM_HUD_ALPHA)   -- translucent window (tosfighter pattern)

    if n == 0 then
        local empty = panel:CreateOrGetControl("richtext", "empty", CM_HUD_PAD, CM_HUD_PAD, row_w, 20)
        empty:SetText("{ol}{s12}{#aaaaaa}" ..
                          (g.lang == "Japanese" and "プリセットなし" or "No presets"))
        empty:EnableHitTest(false)
    else
        for i, row in ipairs(rows) do
            local y = CM_HUD_PAD + (i - 1) * (CM_HUD_ROW_H + CM_HUD_GAP)
            local rb = panel:CreateOrGetControl("button", "hud_apply_" .. i, CM_HUD_PAD, y, row_w, CM_HUD_ROW_H)
            AUTO_CAST(rb)
            rb:SetText("{ol}{s14}" .. row.label)
            rb:SetUserValue("PRESET_INDEX", row.idx)
            rb:SetEventScript(ui.LBUTTONUP, "CM_hud_apply")
            rb:SetOverSound("button_over")
            rb:SetClickSound("button_click_stats")
        end
    end

    -- 프리셋 창과 같은 제작자 표기. 장식이므로 실패해도 패널은 떠야 한다
    -- same credit as the preset window; decorative, so it must never break the panel
    pcall(CM_credit_render, panel, panel_w, panel_h - CM_HUD_PAD - CM_CREDIT_H, CM_HUD_PAD)

    panel:ShowWindow(1)
end

function CM_hud_toggle()
    local hud = g.cupole_manager_settings and g.cupole_manager_settings.hud
    if not hud then
        return
    end
    hud.open = (hud.open == 1) and 0 or 1
    CM_save_settings()
    -- update the toggle label in place (do not rebuild the frame handling this
    -- click) then show/hide the panel
    local frame = ui.GetFrame(addonNameLower .. "_hud")
    if frame then
        CM_hud_set_toggle_visual(frame, hud.open)
    end
    CM_hud_panel_render()
end

function CM_hud_drag(frame, ctrl)
    if not frame then
        return
    end
    local hud = g.cupole_manager_settings and g.cupole_manager_settings.hud
    if not hud then
        return
    end
    hud.x = frame:GetX()
    hud.y = frame:GetY()
    CM_save_settings()
    -- keep the open panel attached under the button while dragging
    if hud.open == 1 then
        local panel = ui.GetFrame(addonNameLower .. "_hud_panel")
        if panel then
            local _, sh = CM_screen_size()
            local py = hud.y + CM_HUD_BTN_H + 2
            local ph = panel:GetHeight()
            if py + ph > sh then
                py = math.max(0, sh - ph)
            end
            panel:SetPos(hud.x, py)
        end
    end
end

function CM_hud_apply(parent, ctrl)
    local idx = ctrl:GetUserIValue("PRESET_INDEX")
    CM_preset_apply_by_index(idx)
end

-- refresh HUD panel after presets change
function CM_hud_refresh()
    if g.cupole_manager_settings and g.cupole_manager_settings.hud then
        CM_hud_panel_render()
    end
end

-- ============================================================
-- Overlay / Summon / Skill Swap
-- ============================================================
function CM_preset_overlay_check(overlay)
    local count = overlay:GetUserIValue("OVERLAY_TIMEOUT") + 1
    overlay:SetUserValue("OVERLAY_TIMEOUT", count)
    if g.cupole_preset_apply_num == nil or count >= 20 then
        overlay:StopUpdateScript("CM_preset_overlay_check")
        CM_preset_remove_overlay()
        return 0
    end
    return 1
end

function CM_preset_remove_overlay()
    local overlay_name = addonNameLower .. "_overlay"
    local overlay = ui.GetFrame(overlay_name)
    if overlay then
        ui.DestroyFrame(overlay_name)
    end
end

function CM_preset_summon(frame)
    if g.cupole_preset_apply_num == 4 then
        frame:StopUpdateScript("CM_preset_summon")
        g.cupole_preset_apply_num = nil
        CM_preset_swap_skill()
        CM_preset_remove_overlay()
        ui.SysMsg("[Cupole Preset] Preset applied")
        return 0
    end
    if g.cupole_preset_apply_num < 3 then
        local slot_data = g.cupole_preset_apply_tbl[tostring(g.cupole_preset_apply_num + 1)]
        SummonCupole(tonumber(slot_data.id), CM_SLOT_REMAP[g.cupole_preset_apply_num])
    end
    g.cupole_preset_apply_num = g.cupole_preset_apply_num + 1
    return 1
end

function CM_preset_swap_skill()
    local alive_before = g.cupole_preset_alive_before
    local new_skill_name = g.cupole_preset_new_skill_name
    if not new_skill_name or new_skill_name == "None" then
        g.cupole_preset_alive_before = nil
        g.cupole_preset_new_skill_name = nil
        return
    end
    local new_skl = session.GetSkillByName(new_skill_name)
    if not new_skl then
        g.cupole_preset_alive_before = nil
        g.cupole_preset_new_skill_name = nil
        return
    end
    local new_sklObj = GetIES(new_skl:GetObject())
    local new_skill_id = new_sklObj.ClassID

    local quickslotnexpbar = ui.GetFrame("quickslotnexpbar")
    if not quickslotnexpbar then
        g.cupole_preset_alive_before = nil
        g.cupole_preset_new_skill_name = nil
        return
    end
    local swapped = false
    for i = 1, MAX_QUICKSLOT_CNT do
        local slot_info = quickslot.GetInfoByIndex(i - 1)
        if slot_info and slot_info.category == "Skill" and slot_info.type ~= new_skill_id then
            local is_cupole = false
            local cls = GetClassByType("Skill", slot_info.type)
            if cls then
                local cn = TryGetProp(cls, "ClassName", "")
                if string.find(cn, "^Kupole_") then
                    is_cupole = true
                end
            end
            if not is_cupole then
                local skl = session.GetSkill(slot_info.type)
                if skl then
                    local sklIES = GetIES(skl:GetObject())
                    local cn = TryGetProp(sklIES, "ClassName", "")
                    if string.find(cn, "^Kupole_") then
                        is_cupole = true
                    end
                elseif alive_before and alive_before[i] and alive_before[i] == slot_info.type then
                    is_cupole = true
                end
            end
            if is_cupole then
                local slot = GET_CHILD_RECURSIVELY(quickslotnexpbar, "slot" .. i)
                AUTO_CAST(slot)
                SET_QUICK_SLOT(quickslotnexpbar, slot, "Skill", new_skill_id, nil, 0, true, true)
                swapped = true
            end
        end
    end
    if swapped then
        quickslot.RequestSave()
        QUICKSLOTNEXPBAR_UPDATE_HOTKEYNAME(quickslotnexpbar)
        DebounceScript("QUICKSLOTNEXTBAR_UPDATE_ALL_SLOT", 0.1)
        DebounceScript("JOYSTICK_QUICKSLOT_UPDATE_ALL_SLOT", 0.1)
        ui.SysMsg("[Cupole Preset] Quickslot skill swapped")
    end
    g.cupole_preset_alive_before = nil
    g.cupole_preset_new_skill_name = nil
end

-- ============================================================
-- Norisan Menu System (shared across standalone addons)
-- ============================================================
local norisan_menu_addons = string.format("../%s", "addons")
local norisan_menu_addons_mkfile = string.format("../%s/mkdir.txt", "addons")
local norisan_menu_settings = string.format("../addons/%s/settings.json", "norisan_menu")
local norisan_menu_folder = string.format("../addons/%s", "norisan_menu")
local norisan_menu_mkfile = string.format("../addons/%s/mkdir.txt", "norisan_menu")
_G["norisan"] = _G["norisan"] or {}
_G["norisan"]["MENU"] = _G["norisan"]["MENU"] or {}

local function norisan_menu_create_folder_file()
    local addons_file = io.open(norisan_menu_addons_mkfile, "r")
    if not addons_file then
        os.execute('mkdir "' .. norisan_menu_addons .. '"')
        addons_file = io.open(norisan_menu_addons_mkfile, "w")
        if addons_file then
            addons_file:write("created")
            addons_file:close()
        end
    else
        addons_file:close()
    end
    local file = io.open(norisan_menu_mkfile, "r")
    if not file then
        os.execute('mkdir "' .. norisan_menu_folder .. '"')
        file = io.open(norisan_menu_mkfile, "w")
        if file then
            file:write("created")
            file:close()
        end
    else
        file:close()
    end
end
norisan_menu_create_folder_file()

local function norisan_menu_save_json(path, tbl)
    local data_to_save = {
        x = tbl.x,
        y = tbl.y,
        move = tbl.move,
        open = tbl.open,
        layer = tbl.layer
    }
    local file = io.open(path, "w")
    if file then
        local str = json.encode(data_to_save)
        file:write(str)
        file:close()
    end
end

local function norisan_menu_load_json(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        if content and content ~= "" then
            local decoded, err = json.decode(content)
            if decoded then
                return decoded
            end
        end
    end
    return nil
end

function _G.norisan_menu_move_drag(frame, ctrl)
    if not frame then
        return
    end
    local current_frame_y = frame:GetY()
    local current_frame_h = frame:GetHeight()
    local base_button_h = 40
    local y_to_save = current_frame_y
    if current_frame_h > base_button_h and (_G["norisan"]["MENU"].open == 1) then
        local items_area_h_calculated = current_frame_h - base_button_h
        y_to_save = current_frame_y + items_area_h_calculated
    end
    _G["norisan"]["MENU"].x = frame:GetX()
    _G["norisan"]["MENU"].y = y_to_save
    norisan_menu_save_json(norisan_menu_settings, _G["norisan"]["MENU"])
end

function _G.norisan_menu_setting_frame_ctrl(setting, ctrl)
    local ctrl_name = ctrl:GetName()
    local frame_name = _G["norisan"]["MENU"].frame_name
    local frame = ui.GetFrame(frame_name)
    if ctrl_name == "layer_edit" then
        local layer = tonumber(ctrl:GetText())
        if layer then
            _G["norisan"]["MENU"].layer = layer
            frame:SetLayerLevel(layer)
            norisan_menu_save_json(norisan_menu_settings, _G["norisan"]["MENU"])
            local notice = _G["norisan"]["MENU"].lang == "Japanese" and "{ol}レイヤーを変更" or
                               "{ol}Change Layer"
            ui.SysMsg(notice)
            _G.norisan_menu_create_frame()
            setting:ShowWindow(0)
            return
        end
    end
    if ctrl_name == "def_setting" then
        _G["norisan"]["MENU"].x = 1190
        _G["norisan"]["MENU"].y = 30
        _G["norisan"]["MENU"].move = true
        _G["norisan"]["MENU"].open = 0
        _G["norisan"]["MENU"].layer = 79
        norisan_menu_save_json(norisan_menu_settings, _G["norisan"]["MENU"])
        _G.norisan_menu_create_frame()
        setting:ShowWindow(0)
        return
    end
    if ctrl_name == "close" then
        setting:ShowWindow(0)
        return
    end
    local is_check = ctrl:IsChecked()
    if ctrl_name == "move_toggle" then
        if is_check == 1 then
            _G["norisan"]["MENU"].move = false
        else
            _G["norisan"]["MENU"].move = true
        end
        frame:EnableMove(_G["norisan"]["MENU"].move == true and 1 or 0)
        norisan_menu_save_json(norisan_menu_settings, _G["norisan"]["MENU"])
        return
    elseif ctrl_name == "open_toggle" then
        _G["norisan"]["MENU"].open = is_check
        norisan_menu_save_json(norisan_menu_settings, _G["norisan"]["MENU"])
        _G.norisan_menu_create_frame()
        return
    end
end

function _G.norisan_menu_setting_frame(frame, ctrl)
    local setting = ui.CreateNewFrame("chat_memberlist", "norisan_menu_setting", 0, 0, 0, 0)
    AUTO_CAST(setting)
    setting:SetTitleBarSkin("None")
    setting:SetSkinName("chat_window")
    setting:Resize(260, 135)
    setting:SetLayerLevel(999)
    setting:EnableHitTest(1)
    setting:EnableMove(1)
    setting:SetPos(frame:GetX() + 200, frame:GetY())
    setting:ShowWindow(1)
    local close = setting:CreateOrGetControl("button", "close", 0, 0, 30, 30)
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetGravity(ui.RIGHT, ui.TOP)
    close:SetEventScript(ui.LBUTTONUP, "norisan_menu_setting_frame_ctrl")
    local def_setting = setting:CreateOrGetControl("button", "def_setting", 10, 5, 150, 30)
    AUTO_CAST(def_setting)
    local notice = _G["norisan"]["MENU"].lang == "Japanese" and "{ol}デフォルトに戻す" or "{ol}Reset to default"
    def_setting:SetText(notice)
    def_setting:SetEventScript(ui.LBUTTONUP, "norisan_menu_setting_frame_ctrl")
    local move_toggle = setting:CreateOrGetControl('checkbox', "move_toggle", 10, 35, 30, 30)
    AUTO_CAST(move_toggle)
    move_toggle:SetCheck(_G["norisan"]["MENU"].move == true and 0 or 1)
    move_toggle:SetEventScript(ui.LBUTTONDOWN, 'norisan_menu_setting_frame_ctrl')
    local notice = _G["norisan"]["MENU"].lang == "Japanese" and "{ol}チェックするとフレーム固定" or
                       "{ol}Check to fix frame"
    move_toggle:SetText(notice)
    local open_toggle = setting:CreateOrGetControl('checkbox', "open_toggle", 10, 70, 30, 30)
    AUTO_CAST(open_toggle)
    open_toggle:SetCheck(_G["norisan"]["MENU"].open)
    open_toggle:SetEventScript(ui.LBUTTONDOWN, 'norisan_menu_setting_frame_ctrl')
    local notice = _G["norisan"]["MENU"].lang == "Japanese" and "{ol}チェックすると上開き" or
                       "{ol}Check to open upward"
    open_toggle:SetText(notice)
    local layer_text = setting:CreateOrGetControl('richtext', 'layer_text', 10, 105, 50, 20)
    AUTO_CAST(layer_text)
    local notice = _G["norisan"]["MENU"].lang == "Japanese" and "{ol}レイヤー設定" or "{ol}Set Layer"
    layer_text:SetText(notice)
    local layer_edit = setting:CreateOrGetControl('edit', 'layer_edit', 130, 105, 70, 20)
    AUTO_CAST(layer_edit)
    layer_edit:SetFontName("white_16_ol")
    layer_edit:SetTextAlign("center", "center")
    layer_edit:SetText(_G["norisan"]["MENU"].layer or 79)
    layer_edit:SetEventScript(ui.ENTERKEY, "norisan_menu_setting_frame_ctrl")
end

function _G.norisan_menu_toggle_items_display(frame, ctrl, open_dir)
    local open_up = (open_dir == 1)
    local menu_src = _G["norisan"]["MENU"]
    local max_cols = 5
    local item_w = 35
    local item_h = 35
    local y_off_down = 35
    local items = {}
    if menu_src then
        for key, data in pairs(menu_src) do
            if type(data) == "table" then
                if key ~= "x" and key ~= "y" and key ~= "open" and key ~= "move" and data.name and data.func and
                    ((data.image and data.image ~= "") or (data.icon and data.icon ~= "")) then
                    table.insert(items, {
                        key = key,
                        data = data
                    })
                end
            end
        end
    end
    local num_items = #items
    local num_rows = math.ceil(num_items / max_cols)
    local items_h = num_rows * item_h
    local frame_h_new = 40 + items_h
    local frame_y_new = _G["norisan"]["MENU"].y or 30
    if open_up then
        frame_y_new = frame_y_new - items_h
    end
    local frame_w_new
    if num_rows == 1 then
        frame_w_new = math.max(40, num_items * item_w)
    else
        frame_w_new = math.max(40, max_cols * item_w)
    end
    frame:SetPos(frame:GetX(), frame_y_new)
    frame:Resize(frame_w_new, frame_h_new)
    for idx, entry in ipairs(items) do
        local item_sidx = idx - 1
        local data = entry.data
        local key = entry.key
        local col = item_sidx % max_cols
        local x = col * item_w
        local y = 0
        if open_up then
            local logical_row_from_bottom = math.floor(item_sidx / max_cols)
            y = (frame_h_new - 40) - ((logical_row_from_bottom + 1) * item_h)
        else
            local row_down = math.floor(item_sidx / max_cols)
            y = y_off_down + (row_down * item_h)
        end
        local ctrl_name = "menu_item_" .. key
        local item_elem
        if data.image and data.image ~= "" then
            item_elem = frame:CreateOrGetControl('button', ctrl_name, x, y, item_w, item_h)
            AUTO_CAST(item_elem)
            item_elem:SetSkinName("None")
            item_elem:SetText(data.image)
        else
            item_elem = frame:CreateOrGetControl('picture', ctrl_name, x, y, item_w, item_h)
            AUTO_CAST(item_elem)
            item_elem:SetImage(data.icon)
            item_elem:SetEnableStretch(1)
        end
        if item_elem then
            item_elem:SetTextTooltip("{ol}" .. data.name)
            item_elem:SetEventScript(ui.LBUTTONUP, data.func)
            if data.rfunc then
                item_elem:SetEventScript(ui.RBUTTONUP, data.rfunc)
            end
            item_elem:ShowWindow(1)
        end
    end
    local main_btn = GET_CHILD(frame, "norisan_menu_pic")
    if main_btn then
        if open_up then
            main_btn:SetPos(0, frame_h_new - 40)
        else
            main_btn:SetPos(0, 0)
        end
    end
end

function _G.norisan_menu_frame_open(frame, ctrl)
    if not frame then
        return
    end
    if frame:GetHeight() > 40 then
        local children = {}
        for i = 0, frame:GetChildCount() - 1 do
            local child_obj = frame:GetChildByIndex(i)
            if child_obj then
                table.insert(children, child_obj)
            end
        end
        for _, child_obj in ipairs(children) do
            if child_obj:GetName() ~= "norisan_menu_pic" then
                frame:RemoveChild(child_obj:GetName())
            end
        end
        frame:Resize(40, 40)
        frame:SetPos(frame:GetX(), _G["norisan"]["MENU"].y or 30)
        local main_pic = GET_CHILD(frame, "norisan_menu_pic")
        if main_pic then
            main_pic:SetPos(0, 0)
        end
        return
    end
    local open_dir_val = _G["norisan"]["MENU"].open or 0
    _G.norisan_menu_toggle_items_display(frame, ctrl, open_dir_val)
end

function _G.norisan_menu_create_frame()
    _G["norisan"]["MENU"].lang = option.GetCurrentCountry()
    local loaded_cfg = norisan_menu_load_json(norisan_menu_settings)
    if loaded_cfg and loaded_cfg.layer ~= nil then
        _G["norisan"]["MENU"].layer = loaded_cfg.layer
    elseif _G["norisan"]["MENU"].layer == nil then
        _G["norisan"]["MENU"].layer = 79
    end
    if loaded_cfg and loaded_cfg.move ~= nil then
        _G["norisan"]["MENU"].move = loaded_cfg.move
    elseif _G["norisan"]["MENU"].move == nil then
        _G["norisan"]["MENU"].move = true
    end
    if loaded_cfg and loaded_cfg.open ~= nil then
        _G["norisan"]["MENU"].open = loaded_cfg.open
    elseif _G["norisan"]["MENU"].open == nil then
        _G["norisan"]["MENU"].open = 0
    end
    local default_x = 1190
    local default_y = 30
    local final_x = default_x
    local final_y = default_y
    if _G["norisan"]["MENU"].x ~= nil then
        final_x = _G["norisan"]["MENU"].x
    end
    if _G["norisan"]["MENU"].y ~= nil then
        final_y = _G["norisan"]["MENU"].y
    end
    if loaded_cfg and type(loaded_cfg.x) == "number" then
        final_x = loaded_cfg.x
    end
    if loaded_cfg and type(loaded_cfg.y) == "number" then
        final_y = loaded_cfg.y
    end
    local map_ui = ui.GetFrame("map")
    local screen_w = 1920
    if map_ui and map_ui:IsVisible() then
        screen_w = map_ui:GetWidth()
    end
    if final_x > 1920 and screen_w <= 1920 then
        final_x = default_x
        final_y = default_y
    end
    _G["norisan"]["MENU"].x = final_x
    _G["norisan"]["MENU"].y = final_y
    norisan_menu_save_json(norisan_menu_settings, _G["norisan"]["MENU"])
    local frame = ui.CreateNewFrame("chat_memberlist", "norisan_menu_frame", 0, 0, 0, 0)
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:SetSkinName("None")
    frame:SetTitleBarSkin("None")
    frame:Resize(40, 40)
    frame:SetLayerLevel(_G["norisan"]["MENU"].layer)
    frame:EnableMove(_G["norisan"]["MENU"].move == true and 1 or 0)
    frame:SetPos(_G["norisan"]["MENU"].x, _G["norisan"]["MENU"].y)
    frame:SetEventScript(ui.LBUTTONUP, "norisan_menu_move_drag")
    local norisan_menu_pic = frame:CreateOrGetControl('picture', "norisan_menu_pic", 0, 0, 35, 40)
    AUTO_CAST(norisan_menu_pic)
    norisan_menu_pic:SetImage("sysmenu_sys")
    norisan_menu_pic:SetEnableStretch(1)
    local notice = _G["norisan"]["MENU"].lang == "Japanese" and "{nl}{ol}右クリック: 設定" or
                       "{nl}{ol}Right click: Settings"
    norisan_menu_pic:SetTextTooltip("{ol}Addons Menu" .. notice)
    norisan_menu_pic:SetEventScript(ui.LBUTTONUP, "norisan_menu_frame_open")
    norisan_menu_pic:SetEventScript(ui.RBUTTONUP, "norisan_menu_setting_frame")
    frame:ShowWindow(1)
end

g.norisan_menu_create_frame = _G.norisan_menu_create_frame
