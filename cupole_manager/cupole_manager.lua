-- v1.0.0 first release
local addonName = "cupole_manager"
local version = "1.0.0"
local author = "Yomae"

local addonNameLower = string.lower(addonName)

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]
local acutil = require("acutil")
local json = require("json")

-- Infrastructure: save_json (safe tmp-file write)
local function CM_save_json(path, tbl)
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
            if equip_cupole_list[i] == "-1" then
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
        local cupole_cls = GET_CUPOLE_BY_INDEX_IN_CLASSLIST(equip_cupole_list[i])
        local cupole_class_name = TryGetProp(cupole_cls, "ClassName", "None")
        if equip_cupole_list[i] ~= "-1" then
            g.cupole_manager_settings[g.cid][tostring(i)] = {
                id = equip_cupole_list[i],
                name = cupole_class_name
            }
            if not g.cupole_manager_settings["default"][tostring(i)] then
                g.cupole_manager_settings["default"][tostring(i)] = {
                    id = equip_cupole_list[i],
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
        if equip_cupole_list[i] == "-1" then
            ui.SysMsg(g.lang == "Japanese" and "クポルが3体登録されていません" or
                          "3 Cupoles are not registered")
            return
        end
    end
    for i = 1, 3 do
        local cupole_cls = GET_CUPOLE_BY_INDEX_IN_CLASSLIST(equip_cupole_list[i])
        local cupole_class_name = TryGetProp(cupole_cls, "ClassName", "None")
        g.cupole_manager_settings["default"][tostring(i)] = {
            id = equip_cupole_list[i],
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
    cm_frame:RunUpdateScript("CM_summon_cupole", 1.0)
end

function CM_summon_cupole(frame)
    if g.cupole_manager_num == 3 then
        frame:StopUpdateScript("CM_summon_cupole")
        return 0
    end
    SummonCupole(tonumber(g.cupole_manager_tbl[tostring(g.cupole_manager_num + 1)].id), g.cupole_manager_num)
    g.cupole_manager_num = g.cupole_manager_num + 1
    return 1
end

-- ============================================================
-- Norisan Menu
-- ============================================================
function CM_make_menu()
    _G["norisan"] = _G["norisan"] or {}
    _G["norisan"]["MENU"] = _G["norisan"]["MENU"] or {}
    _G["norisan"]["MENU"]["cupole_preset"] = {
        name = "Cupole Preset",
        icon = "sysmenu_cupole_info",
        func = "CM_preset_frame_open",
        rfunc = "CM_preset_quick_frame_open",
        image = ""
    }
    local frame_name = _G["norisan"]["MENU"].frame_name
    local menu_frame = ui.GetFrame(frame_name)
    if menu_frame and frame_name ~= "norisan_menu_frame" then
        ui.DestroyFrame(frame_name)
    end
    frame_name = "norisan_menu_frame"
    _G["norisan"]["MENU"].frame_name = frame_name
    g.norisan_menu_create_frame()
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

function CM_preset_frame_open()
    if not g.cupole_manager_settings then
        CM_load_settings()
    end
    local frame_name = addonNameLower .. "_preset"
    local frame = ui.GetFrame(frame_name)
    if frame and frame:IsVisible() == 1 then
        return
    end
    frame = ui.CreateNewFrame("notice_on_pc", frame_name, 0, 0, 0, 0)
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(560, 500)
    frame:SetSkinName("None")
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(92)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)

    local sw = ui.GetClientInitialWidth()
    local sh = ui.GetClientInitialHeight()
    frame:SetPos((sw - 560) / 2, (sh - 500) / 2)

    local bg = frame:CreateOrGetControl("groupbox", "bg", 560, 460, ui.LEFT, ui.TOP, 0, 40, 0, 0)
    AUTO_CAST(bg)
    bg:SetSkinName("test_frame_low")
    bg:EnableHittestGroupBox(false)

    local title_bg = frame:CreateOrGetControl("groupbox", "title_bg", 560, 61, ui.LEFT, ui.TOP, 0, 0, 0, 0)
    AUTO_CAST(title_bg)
    title_bg:SetSkinName("test_frame_top")
    title_bg:EnableHittestGroupBox(false)

    local title = frame:CreateOrGetControl("richtext", "title", 100, 30, ui.CENTER_HORZ, ui.TOP, 0, 18, 0, 0)
    title:SetText("{@st43}{s22}Cupole Preset Manager{/}")
    title:EnableHitTest(false)

    local close = frame:CreateOrGetControl("button", "close", 44, 44, ui.RIGHT, ui.TOP, 0, 20, 17, 0)
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetEventScript(ui.LBUTTONUP, "CM_preset_frame_close")

    local tab = frame:CreateOrGetControl("tab", "tab", 520, 40, ui.LEFT, ui.TOP, 20, 65, 0, 0)
    AUTO_CAST(tab)
    tab:SetEventScript(ui.LBUTTONUP, "CM_preset_tab_change")
    tab:SetSkinName("tab2")
    for i = 1, 10 do
        local preset = g.cupole_manager_settings.presets[tostring(i - 1)]
        local tab_label = preset and preset.name and preset.name ~= "" and preset.name or ("Set " .. i)
        tab:AddItem("{@st66b}{s14}" .. tab_label, true, "", "", "", "", "", false)
    end
    tab:SetItemsFixWidth(52)
    tab:SetItemsAdjustFontSizeByWidth(52)

    local name_label = frame:CreateOrGetControl("richtext", "name_label", 20, 110, 80, 30)
    name_label:SetText("{ol}{s14}Set Name:")
    name_label:EnableHitTest(false)

    local name_edit = frame:CreateOrGetControl("edit", "name_edit", 100, 108, 200, 30)
    AUTO_CAST(name_edit)
    name_edit:SetFontName("white_14_ol")
    name_edit:SetTextAlign("left", "center")
    name_edit:SetSkinName("inventory_serch")

    local slot_positions = {[2] = 0, [1] = 1, [3] = 2}
    local slot_labels = {[1] = "Center", [2] = "Left", [3] = "Right"}
    for slot = 1, 3 do
        local sx = 20 + slot_positions[slot] * 80
        local border = frame:CreateOrGetControl("picture", "slot_border_" .. slot, sx - 3, 160, 66, 66)
        AUTO_CAST(border)
        border:SetImage("cupole_grade_frame_R")
        border:SetEnableStretch(1)
        border:EnableHitTest(0)
        local pic = frame:CreateOrGetControl("picture", "slot_" .. slot, sx, 163, 60, 60)
        AUTO_CAST(pic)
        pic:SetSkinName("inven_slot")
        pic:SetUserValue("SLOT_INDEX", slot)
        pic:SetEventScript(ui.LBUTTONUP, "CM_preset_slot_click")
        pic:SetEventScript(ui.RBUTTONUP, "CM_preset_slot_clear")
        local slot_label = frame:CreateOrGetControl("richtext", "slot_label_" .. slot, sx, 151, 60, 12)
        slot_label:SetText("{ol}{s11}{#aaaaaa}" .. slot_labels[slot])
        slot_label:EnableHitTest(false)
        local slot_name = frame:CreateOrGetControl("richtext", "slot_name_" .. slot, sx, 231, 60, 20)
        slot_name:SetText("{ol}{s12}{#999999}Empty")
        slot_name:EnableHitTest(false)
    end

    local selected_mark = frame:CreateOrGetControl("richtext", "selected_mark", 20, 252, 200, 20)
    selected_mark:SetText("")
    selected_mark:EnableHitTest(false)

    local apply_btn = frame:CreateOrGetControl("button", "apply_btn", 20, 275, 70, 35)
    AUTO_CAST(apply_btn)
    apply_btn:SetText("{ol}{s14}Apply")
    apply_btn:SetOverSound("button_over")
    apply_btn:SetClickSound("button_click_stats")
    apply_btn:SetEventScript(ui.LBUTTONUP, "CM_preset_apply")

    local load_btn = frame:CreateOrGetControl("button", "load_btn", 100, 275, 110, 35)
    AUTO_CAST(load_btn)
    load_btn:SetText("{ol}{s14}Load Current")
    load_btn:SetOverSound("button_over")
    load_btn:SetClickSound("button_click_stats")
    load_btn:SetEventScript(ui.LBUTTONUP, "CM_preset_load_current")

    local save_btn = frame:CreateOrGetControl("button", "save_btn", 220, 275, 60, 35)
    AUTO_CAST(save_btn)
    save_btn:SetText("{ol}{s14}Save")
    save_btn:SetOverSound("button_over")
    save_btn:SetClickSound("button_click_stats")
    save_btn:SetEventScript(ui.LBUTTONUP, "CM_preset_save")

    local clear_btn = frame:CreateOrGetControl("button", "clear_btn", 290, 275, 65, 35)
    AUTO_CAST(clear_btn)
    clear_btn:SetText("{ol}{s14}Clear")
    clear_btn:SetOverSound("button_over")
    clear_btn:SetClickSound("button_click_stats")
    clear_btn:SetEventScript(ui.LBUTTONUP, "CM_preset_clear")

    local grid_label = frame:CreateOrGetControl("richtext", "grid_label", 20, 318, 200, 20)
    grid_label:SetText("{ol}{s14}Owned Cupoles:")
    grid_label:EnableHitTest(false)

    local filter_grades = {"All", "UR", "SR", "R"}
    for fi, grade in ipairs(filter_grades) do
        local fx = 150 + (fi - 1) * 55
        local fbtn = frame:CreateOrGetControl("button", "filter_" .. grade, fx, 315, 50, 22)
        AUTO_CAST(fbtn)
        local grade_colors = {All = "ffffff", UR = "ffcc33", SR = "cc66ff", R = "66ccff"}
        fbtn:SetText("{ol}{s12}{#" .. grade_colors[grade] .. "}" .. grade)
        fbtn:SetUserValue("FILTER_GRADE", grade)
        fbtn:SetEventScript(ui.LBUTTONUP, "CM_preset_filter_click")
        fbtn:SetOverSound("button_over")
        fbtn:SetClickSound("button_click_stats")
    end

    local grid = frame:CreateOrGetControl("groupbox", "cupole_grid", 520, 155, ui.LEFT, ui.TOP, 20, 340, 0, 0)
    AUTO_CAST(grid)
    grid:SetSkinName("test_frame_midle")
    grid:EnableScrollBar(1)
    grid:EnableHittestGroupBox(true)

    g.cupole_preset_filter_grade = "All"

    local esc_timer = frame:CreateOrGetControl("timer", "preset_esc_timer", 0, 0)
    AUTO_CAST(esc_timer)
    esc_timer:SetUpdateScript("CM_preset_esc_check")
    esc_timer:Start(0.05)

    g.cupole_preset_selected_slot = nil
    frame:ShowWindow(1)
    CM_preset_tab_change(frame)
end

function CM_preset_frame_close()
    local frame_name = addonNameLower .. "_preset"
    local frame = ui.GetFrame(frame_name)
    if frame then
        ui.DestroyFrame(frame_name)
    end
end

function CM_preset_esc_check(frame)
    if keyboard.IsKeyPressed("ESCAPE") == 1 then
        CM_preset_frame_close()
    end
end

function CM_preset_tab_change(frame)
    local tab = GET_CHILD(frame, "tab")
    AUTO_CAST(tab)
    local tab_index = tab:GetSelectItemIndex()
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
    save_btn:SetText("{ol}{s14}Save")
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
    local grid = GET_CHILD(frame, "cupole_grid")
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
    local tab = GET_CHILD(frame, "tab")
    AUTO_CAST(tab)
    local tab_index = tab:GetSelectItemIndex()
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]
    if preset and preset[tostring(slot_index)] then
        preset[tostring(slot_index)] = nil
        CM_preset_render_slots(frame, tab_index)
        local save_btn = GET_CHILD(frame, "save_btn")
        AUTO_CAST(save_btn)
        save_btn:SetText("{ol}{s14}{#ff3333}Save")
    end
end

function CM_preset_grid_click(parent, ctrl)
    local frame = ctrl:GetTopParentFrame()
    local tab = GET_CHILD(frame, "tab")
    AUTO_CAST(tab)
    local tab_index = tab:GetSelectItemIndex()
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
    local tab = GET_CHILD(frame, "tab")
    AUTO_CAST(tab)
    local tab_index = tab:GetSelectItemIndex()
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
    local save_btn = GET_CHILD(frame, "save_btn")
    AUTO_CAST(save_btn)
    save_btn:SetText("{ol}{s14}{#ff3333}Save")
end

function CM_preset_load_current(frame, ctrl)
    local equip_cupole_list = GET_EQUIP_CUPOLE_LIST()
    for i = 1, 3 do
        if equip_cupole_list[i] == "-1" then
            ui.SysMsg("[Cupole Preset] 3 Cupoles must be equipped to load")
            return
        end
    end
    local tab = GET_CHILD(frame, "tab")
    AUTO_CAST(tab)
    local tab_index = tab:GetSelectItemIndex()
    if not g.cupole_manager_settings.presets[tostring(tab_index)] then
        g.cupole_manager_settings.presets[tostring(tab_index)] = {}
    end
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]
    for i = 1, 3 do
        local cupole_cls = GET_CUPOLE_BY_INDEX_IN_CLASSLIST(equip_cupole_list[i])
        local cupole_class_name = TryGetProp(cupole_cls, "ClassName", "None")
        preset[tostring(i)] = {
            id = equip_cupole_list[i],
            name = cupole_class_name
        }
    end
    CM_preset_render_slots(frame, tab_index)
    local save_btn = GET_CHILD(frame, "save_btn")
    AUTO_CAST(save_btn)
    save_btn:SetText("{ol}{s14}{#ff3333}Save")
    ui.SysMsg("[Cupole Preset] Current Cupoles loaded to slots (press Save to keep)")
end

function CM_preset_save(frame, ctrl)
    local tab = GET_CHILD(frame, "tab")
    AUTO_CAST(tab)
    local tab_index = tab:GetSelectItemIndex()
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
    tab:ClearItem()
    for i = 1, 10 do
        local p = g.cupole_manager_settings.presets[tostring(i - 1)]
        local tab_label = p and p.name and p.name ~= "" and p.name or ("Set " .. i)
        tab:AddItem("{@st66b}{s14}" .. tab_label, true, "", "", "", "", "", false)
    end
    tab:SetItemsFixWidth(52)
    tab:SetItemsAdjustFontSizeByWidth(52)
    tab:SelectTab(tab_index)
    local save_btn = GET_CHILD(frame, "save_btn")
    AUTO_CAST(save_btn)
    save_btn:SetText("{ol}{s14}Save")
    ui.SysMsg("[Cupole Preset] Saved: " .. set_name)
end

function CM_preset_clear(frame, ctrl)
    local tab = GET_CHILD(frame, "tab")
    AUTO_CAST(tab)
    local tab_index = tab:GetSelectItemIndex()
    local preset = g.cupole_manager_settings.presets[tostring(tab_index)]
    if preset then
        preset["1"] = nil
        preset["2"] = nil
        preset["3"] = nil
    end
    CM_preset_render_slots(frame, tab_index)
    local name_edit = GET_CHILD(frame, "name_edit")
    AUTO_CAST(name_edit)
    name_edit:SetText("")
    local save_btn = GET_CHILD(frame, "save_btn")
    AUTO_CAST(save_btn)
    save_btn:SetText("{ol}{s14}{#ff3333}Save")
    ui.SysMsg("[Cupole Preset] Set " .. (tab_index + 1) .. " cleared (press Save to keep)")
end

function CM_preset_apply(frame, ctrl)
    local tab = GET_CHILD(frame, "tab")
    AUTO_CAST(tab)
    local tab_index = tab:GetSelectItemIndex()
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
    local sw = ui.GetClientInitialWidth()
    local sh = ui.GetClientInitialHeight()
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
    cm_frame:RunUpdateScript("CM_preset_summon", 1.0)
    ui.SysMsg("[Cupole Preset] Applying preset...")
end

-- ============================================================
-- Quick Apply Frame
-- ============================================================
function CM_preset_quick_frame_open()
    if not g.cupole_manager_settings then
        CM_load_settings()
    end
    local frame_name = addonNameLower .. "_quick"
    local frame = ui.GetFrame(frame_name)
    if frame and frame:IsVisible() == 1 then
        frame:ShowWindow(0)
        return
    end
    local presets = g.cupole_manager_settings.presets or {}
    local rows = {}
    for idx = 0, 9 do
        local p = presets[tostring(idx)]
        if p and p["1"] and p["2"] and p["3"] then
            local label = p.name and p.name ~= "" and p.name or ("Set " .. (idx + 1))
            local names = {}
            for s = 1, 3 do
                local cls = GET_CUPOLE_BY_INDEX_IN_CLASSLIST(p[tostring(s)].id)
                if cls then
                    table.insert(names, TryGetProp(cls, "Dec_Name", "?"))
                else
                    table.insert(names, "?")
                end
            end
            table.insert(rows, {idx = idx, label = label, detail = table.concat(names, " / ")})
        end
    end
    if #rows == 0 then
        ui.SysMsg("[Cupole Preset] No saved presets")
        return
    end

    local row_h = 50
    local padding = 12
    local title_h = 45
    local frame_w = 320
    local frame_h = title_h + (#rows * row_h) + padding * 2

    frame = ui.CreateNewFrame("notice_on_pc", frame_name, 0, 0, 0, 0)
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(frame_w, frame_h)
    frame:SetSkinName("None")
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(100)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)

    local sw = ui.GetClientInitialWidth()
    local sh = ui.GetClientInitialHeight()
    frame:SetPos((sw - frame_w) / 2, (sh - frame_h) / 2)

    local bg = frame:CreateOrGetControl("groupbox", "bg", frame_w, frame_h - 30, ui.LEFT, ui.TOP, 0, 30, 0, 0)
    AUTO_CAST(bg)
    bg:SetSkinName("test_frame_low")
    bg:EnableHittestGroupBox(false)

    local title_bg = frame:CreateOrGetControl("groupbox", "title_bg", frame_w, 50, ui.LEFT, ui.TOP, 0, 0, 0, 0)
    AUTO_CAST(title_bg)
    title_bg:SetSkinName("test_frame_top")
    title_bg:EnableHittestGroupBox(false)

    local title = frame:CreateOrGetControl("richtext", "title", 100, 30, ui.CENTER_HORZ, ui.TOP, 0, 18, 0, 0)
    title:SetText("{@st43}{s18}Cupole Preset{/}")
    title:EnableHitTest(false)

    local close = frame:CreateOrGetControl("button", "close", 34, 34, ui.RIGHT, ui.TOP, 0, 14, 10, 0)
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetEventScript(ui.LBUTTONUP, "CM_preset_quick_frame_close")

    for i, row in ipairs(rows) do
        local y = title_h + padding + (i - 1) * row_h
        local name_rt = frame:CreateOrGetControl("richtext", "qp_name_" .. i, padding, y, frame_w - 100, 20)
        name_rt:SetText("{ol}{s14}{b}" .. row.label)
        name_rt:EnableHitTest(false)

        local detail_rt = frame:CreateOrGetControl("richtext", "qp_detail_" .. i, padding, y + 20, frame_w - 100, 20)
        detail_rt:SetText("{ol}{s11}{#aaaaaa}" .. row.detail)
        detail_rt:EnableHitTest(false)

        local apply_btn = frame:CreateOrGetControl("button", "qp_apply_" .. i, frame_w - padding - 70, y + 8, 70, 30)
        AUTO_CAST(apply_btn)
        apply_btn:SetText("{ol}{s13}Apply")
        apply_btn:SetUserValue("PRESET_INDEX", row.idx)
        apply_btn:SetEventScript(ui.LBUTTONUP, "CM_preset_quick_apply")
        apply_btn:SetOverSound("button_over")
        apply_btn:SetClickSound("button_click_stats")
    end

    local esc_timer = frame:CreateOrGetControl("timer", "qp_esc_timer", 0, 0)
    AUTO_CAST(esc_timer)
    esc_timer:SetUpdateScript("CM_preset_quick_esc_check")
    esc_timer:Start(0.05)

    frame:ShowWindow(1)
end

function CM_preset_quick_frame_close()
    local frame_name = addonNameLower .. "_quick"
    local frame = ui.GetFrame(frame_name)
    if frame then
        frame:ShowWindow(0)
    end
end

function CM_preset_quick_esc_check(frame)
    if keyboard.IsKeyPressed("ESCAPE") == 1 then
        CM_preset_quick_frame_close()
    end
end

function CM_preset_quick_apply(parent, ctrl)
    local idx = ctrl:GetUserIValue("PRESET_INDEX")
    CM_preset_quick_frame_close()
    CM_preset_apply_by_index(idx)
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
        SummonCupole(tonumber(slot_data.id), g.cupole_preset_apply_num)
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
