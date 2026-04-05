local addonName = "auto_ads"
local version = "1.0.0"
local author = "Yomae"

local addonNameLower = string.lower(addonName)

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]
local acutil = require("acutil")
local json = require("json")

-- ============================================================
-- i18n
-- ============================================================
local AA_LANG = {
    kor = {
        loaded              = "[Auto Ads] 로드 완료.",
        not_ready           = "[Auto Ads] 아직 로딩 중입니다. 잠시 후 다시 시도해주세요.",
        min_interval        = "[Auto Ads] 최소 주기는 %d초입니다. %d초로 설정됩니다.",
        empty_message       = "[Auto Ads] 메시지가 비어있습니다. 설정에서 메시지를 입력해주세요.",
        started             = "[Auto Ads] 시작 (%s, 주기: %d초)",
        not_running         = "[Auto Ads] 실행 중이 아닙니다.",
        stopped             = "[Auto Ads] 종료 (총 %d회 전송)",
        no_megaphone        = "[Auto Ads] 확성기가 없어 자동 종료합니다.",
        sent                = "[Auto Ads] 전송 #%d",
        msg_type_label      = "메시지 종류:",
        interval_label      = "전송 주기(초):",
        message_label       = "메시지:",
        btn_start           = "시작",
        btn_stop            = "종료",
        status_stopped      = "상태: 정지",
        status_running      = "상태: 실행 중 (%s)",
        start_time          = "시작 시각: %s",
        send_count          = "전송 횟수: %d",
        megaphone_count     = "확성기: %d개",
        type_normal         = "일반",
        type_shout          = "외침",
        type_guild          = "길드",
        type_guild_notice   = "길드강조",
    },
    eng = {
        loaded              = "[Auto Ads] Loaded.",
        not_ready           = "[Auto Ads] Still loading. Please try again shortly.",
        min_interval        = "[Auto Ads] Minimum interval is %d sec. Set to %d sec.",
        empty_message       = "[Auto Ads] Message is empty. Please enter a message.",
        started             = "[Auto Ads] Started (%s, interval: %d sec)",
        not_running         = "[Auto Ads] Not running.",
        stopped             = "[Auto Ads] Stopped (total %d sent)",
        no_megaphone        = "[Auto Ads] No megaphones left. Auto-stopped.",
        sent                = "[Auto Ads] Sent #%d",
        msg_type_label      = "Message type:",
        interval_label      = "Interval (sec):",
        message_label       = "Message:",
        btn_start           = "Start",
        btn_stop            = "Stop",
        status_stopped      = "Status: Stopped",
        status_running      = "Status: Running (%s)",
        start_time          = "Start time: %s",
        send_count          = "Sent: %d",
        megaphone_count     = "Megaphones: %d",
        type_normal         = "Normal",
        type_shout          = "Shout",
        type_guild          = "Guild",
        type_guild_notice   = "Guild Notice",
    },
}

local function AA_L(key)
    local lang = (g.settings and g.settings.lang) or "kor"
    return AA_LANG[lang][key] or AA_LANG["kor"][key] or key
end

-- ============================================================
-- Infrastructure: JSON I/O (atomic tmp+rename)
-- ============================================================
local function AA_save_json(path, tbl)
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

local function AA_load_json(path)
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

-- Infrastructure: create folder
local function AA_create_folder(path)
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

AA_create_folder("../addons")
AA_create_folder("../addons/" .. addonNameLower)

-- ============================================================
-- Init
-- ============================================================
function AUTO_ADS_ON_INIT(addon, frame)
    frame:ShowWindow(1)
    g.addon = addon
    g.frame = frame
    acutil.slashCommand("/ads", AA_SLASH)
    addon:RegisterMsg("GAME_START_3SEC", "AA_GAME_START")
end

function AA_GAME_START()
    g.active_id = tostring(session.loginInfo.GetAID())
    AA_create_folder("../addons/" .. addonNameLower .. "/" .. g.active_id)
    AA_load_settings()
    g.ready = true
    g.running = false
    g.shout_count = 0
    g.start_time_str = "--:--:--"
    g.start_time = nil
    AA_make_menu()
    CHAT_SYSTEM(AA_L("loaded"))
end

-- ============================================================
-- Settings Save/Load
-- ============================================================
function AA_save_settings()
    AA_save_json(g.settings_path, g.settings)
end

function AA_load_settings()
    g.settings_path = string.format("../addons/%s/%s/auto_ads.json", addonNameLower, g.active_id)
    local settings = AA_load_json(g.settings_path)
    if not settings then
        settings = { interval = 60, message = "", msg_type = "/y", lang = "kor" }
        g.settings = settings
        AA_save_settings()
    else
        if not settings.interval then settings.interval = 60 end
        if not settings.message then settings.message = "" end
        if not settings.msg_type then settings.msg_type = "/y" end
        if not settings.lang then settings.lang = "kor" end
        g.settings = settings
    end
end

-- ============================================================
-- Slash Command
-- ============================================================
function AA_SLASH(command)
    local cmd = ""
    if command then
        cmd = string.match(command, "^%s*(%S+)") or ""
        cmd = string.lower(cmd)
    end
    if cmd == "start" then
        AA_start()
    elseif cmd == "stop" then
        AA_stop()
    end
end

-- ============================================================
-- Start / Stop
-- ============================================================
function AA_start()
    if not g.ready then
        CHAT_SYSTEM(AA_L("not_ready"))
        return
    end
    if not g.settings then
        AA_load_settings()
    end
    local interval = tonumber(g.settings.interval) or 60
    local cmd = g.settings.msg_type or "/y"
    local min_interval = (cmd == "/y") and 60 or 10
    if interval < min_interval then
        interval = min_interval
        g.settings.interval = min_interval
        CHAT_SYSTEM(string.format(AA_L("min_interval"), min_interval, min_interval))
    end
    local msg = g.settings.message or ""
    if msg == "" then
        CHAT_SYSTEM(AA_L("empty_message"))
        return
    end

    g.running = true
    g.shout_count = 0
    g.start_time = os.time()
    g.start_time_str = os.date("%H:%M:%S")

    -- periodic shout (timer control, fires immediately on Start)
    local shout_timer = g.frame:CreateOrGetControl("timer", "shout_timer", 0, 0)
    AUTO_CAST(shout_timer)
    shout_timer:SetUpdateScript("AA_shout")
    shout_timer:Stop()
    shout_timer:Start(interval)

    AA_save_settings()
    local type_label = {
        ["/s"] = AA_L("type_normal"), ["/y"] = AA_L("type_shout"),
        ["/g"] = AA_L("type_guild"), ["/gn"] = AA_L("type_guild_notice"),
    }
    local tl = type_label[g.settings.msg_type] or AA_L("type_shout")
    CHAT_SYSTEM(string.format(AA_L("started"), tl, interval))
    AA_refresh_ui()
end

function AA_stop()
    if not g.running then
        CHAT_SYSTEM(AA_L("not_running"))
        return
    end
    g.running = false
    local shout_timer = GET_CHILD(g.frame, "shout_timer")
    if shout_timer then
        AUTO_CAST(shout_timer)
        shout_timer:Stop()
    end
    CHAT_SYSTEM(string.format(AA_L("stopped"), g.shout_count))
    AA_refresh_ui()
end

-- ============================================================
-- Shout (timer callback)
-- ============================================================
function AA_shout()
    if not g.running then
        return
    end
    local msg = g.settings.message or ""
    if msg == "" then
        AA_stop()
        return
    end
    local cmd = g.settings.msg_type or "/y"
    if cmd == "/y" then
        local megaphone_count = 0
        pcall(function()
            megaphone_count = session.GetInvItemCountByType(645001) or 0
        end)
        if megaphone_count <= 0 then
            CHAT_SYSTEM(AA_L("no_megaphone"))
            AA_stop()
            return
        end
    end
    if cmd == "/s" then
        ui.Chat(msg)
    else
        ui.Chat(cmd .. " " .. msg)
    end
    g.shout_count = g.shout_count + 1
    CHAT_SYSTEM(string.format(AA_L("sent"), g.shout_count))
end

-- ============================================================
-- UI
-- ============================================================
local FRAME_W = 800
local FRAME_H = 350

local MSG_TYPES = {
    { cmd = "/s", label_key = "type_normal",       color = "#00ff00" },
    { cmd = "/y", label_key = "type_shout",        color = "#00ff00" },
    { cmd = "/g", label_key = "type_guild",        color = "#00ff00" },
    { cmd = "/gn", label_key = "type_guild_notice", color = "#4488ff" },
}

function AA_open_frame()
    if not g.ready then
        CHAT_SYSTEM(AA_L("not_ready"))
        return
    end
    if not g.settings then
        AA_load_settings()
    end
    local frame_name = addonNameLower .. "_main"
    local frame = ui.GetFrame(frame_name)
    if frame and frame:IsVisible() == 1 then
        AA_close_frame()
        return
    end
    frame = ui.CreateNewFrame("notice_on_pc", frame_name, 0, 0, 0, 0)
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(FRAME_W, FRAME_H)
    frame:SetSkinName("None")
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(92)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)

    local sw = ui.GetClientInitialWidth()
    local sh = ui.GetClientInitialHeight()
    frame:SetPos((sw - FRAME_W) / 2, (sh - FRAME_H) / 2)

    -- background
    local bg = frame:CreateOrGetControl("groupbox", "bg", FRAME_W, FRAME_H - 40, ui.LEFT, ui.TOP, 0, 40, 0, 0)
    AUTO_CAST(bg)
    bg:SetSkinName("test_frame_low")
    bg:EnableHittestGroupBox(false)

    -- title bar
    local title_bg = frame:CreateOrGetControl("groupbox", "title_bg", FRAME_W, 61, ui.LEFT, ui.TOP, 0, 0, 0, 0)
    AUTO_CAST(title_bg)
    title_bg:SetSkinName("test_frame_top")
    title_bg:EnableHittestGroupBox(false)

    local title = frame:CreateOrGetControl("richtext", "title", 100, 30, ui.CENTER_HORZ, ui.TOP, 0, 18, 0, 0)
    title:SetText("{@st43}{s18}Auto Ads{/}")
    title:EnableHitTest(false)

    local close = frame:CreateOrGetControl("button", "close", 44, 44, ui.RIGHT, ui.TOP, 0, 20, 17, 0)
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetEventScript(ui.LBUTTONUP, "AA_close_frame")

    -- language toggle button
    local lang = g.settings.lang or "kor"
    local lang_text = (lang == "kor") and "KOR" or "ENG"
    local btn_lang = frame:CreateOrGetControl("button", "btn_lang", 50, 22, ui.RIGHT, ui.TOP, 0, 58, 17, 0)
    AUTO_CAST(btn_lang)
    btn_lang:SetText("{ol}{s12}{#aaaaaa}" .. lang_text)
    btn_lang:SetOverSound("button_over")
    btn_lang:SetClickSound("button_click_stats")
    btn_lang:SetEventScript(ui.LBUTTONUP, "AA_on_lang_click")

    -- message type buttons
    local y = 60
    local lbl_type = frame:CreateOrGetControl("richtext", "lbl_type", 20, y, 120, 25)
    lbl_type:SetText("{ol}{s14}" .. AA_L("msg_type_label"))
    lbl_type:EnableHitTest(false)

    local current_type = g.settings.msg_type or "/y"
    for i, t in ipairs(MSG_TYPES) do
        local bx = 140 + (i - 1) * 80
        local btn = frame:CreateOrGetControl("button", "btn_type_" .. i, bx, y - 2, 75, 28)
        AUTO_CAST(btn)
        if current_type == t.cmd then
            btn:SetText("{ol}{s14}{" .. t.color .. "}" .. AA_L(t.label_key))
        else
            btn:SetText("{ol}{s14}" .. AA_L(t.label_key))
        end
        btn:SetOverSound("button_over")
        btn:SetClickSound("button_click_stats")
        btn:SetUserValue("MSG_CMD", t.cmd)
        btn:SetEventScript(ui.LBUTTONUP, "AA_on_type_click")
    end

    -- interval label + edit
    y = y + 35
    local lbl_interval = frame:CreateOrGetControl("richtext", "lbl_interval", 20, y, 120, 25)
    lbl_interval:SetText("{ol}{s14}" .. AA_L("interval_label"))
    lbl_interval:EnableHitTest(false)

    local edit_interval = frame:CreateOrGetControl("edit", "edit_interval", 140, y - 2, 190, 28)
    AUTO_CAST(edit_interval)
    edit_interval:SetFontName("white_14_ol")
    edit_interval:SetTextAlign("left", "center")
    edit_interval:SetSkinName("inventory_serch")
    edit_interval:SetText(tostring(g.settings.interval or 60))

    -- message label + edit (wide)
    y = y + 35
    local lbl_message = frame:CreateOrGetControl("richtext", "lbl_message", 20, y, 120, 25)
    lbl_message:SetText("{ol}{s14}" .. AA_L("message_label"))
    lbl_message:EnableHitTest(false)

    local edit_message = frame:CreateOrGetControl("edit", "edit_message", 140, y - 2, FRAME_W - 160, 28)
    AUTO_CAST(edit_message)
    edit_message:SetFontName("white_14_ol")
    edit_message:SetTextAlign("left", "center")
    edit_message:SetSkinName("inventory_serch")
    edit_message:SetText(g.settings.message or "")

    -- buttons (centered)
    y = y + 45
    local btn_gap = 20
    local btn_w = 70
    local btn_start_x = (FRAME_W - btn_w * 2 - btn_gap) / 2
    local btn_start = frame:CreateOrGetControl("button", "btn_start", btn_w, 35, ui.LEFT, ui.TOP, btn_start_x, y, 0, 0)
    AUTO_CAST(btn_start)
    btn_start:SetText("{ol}{s14}" .. AA_L("btn_start"))
    btn_start:SetOverSound("button_over")
    btn_start:SetClickSound("button_click_stats")
    btn_start:SetEventScript(ui.LBUTTONUP, "AA_on_start_click")

    local btn_stop = frame:CreateOrGetControl("button", "btn_stop", btn_w, 35, ui.LEFT, ui.TOP, btn_start_x + btn_w + btn_gap, y, 0, 0)
    AUTO_CAST(btn_stop)
    btn_stop:SetText("{ol}{s14}" .. AA_L("btn_stop"))
    btn_stop:SetOverSound("button_over")
    btn_stop:SetClickSound("button_click_stats")
    btn_stop:SetEventScript(ui.LBUTTONUP, "AA_on_stop_click")

    -- status display
    y = y + 50
    local lbl_status = frame:CreateOrGetControl("richtext", "lbl_status", 20, y, FRAME_W - 40, 20)
    lbl_status:SetText("{ol}{s14}" .. AA_L("status_stopped"))
    lbl_status:EnableHitTest(false)

    y = y + 25
    local lbl_start_time = frame:CreateOrGetControl("richtext", "lbl_start_time", 20, y, FRAME_W - 40, 20)
    lbl_start_time:SetText("{ol}{s14}" .. string.format(AA_L("start_time"), "--:--:--"))
    lbl_start_time:EnableHitTest(false)

    y = y + 25
    local lbl_count = frame:CreateOrGetControl("richtext", "lbl_count", 20, y, FRAME_W - 40, 20)
    lbl_count:SetText("{ol}{s14}" .. string.format(AA_L("send_count"), 0))
    lbl_count:EnableHitTest(false)

    y = y + 25
    local lbl_megaphone = frame:CreateOrGetControl("richtext", "lbl_megaphone", 20, y, FRAME_W - 40, 20)
    lbl_megaphone:SetText("{ol}{s14}" .. string.format(AA_L("megaphone_count"), 0))
    lbl_megaphone:EnableHitTest(false)

    -- credit
    local lbl_credit = frame:CreateOrGetControl("richtext", "lbl_credit", 0, 0, FRAME_W - 30, 20)
    lbl_credit:SetGravity(ui.RIGHT, ui.BOTTOM)
    lbl_credit:SetMargin(0, 0, 15, 10)
    lbl_credit:SetText("{ol}{s12}{#999999}made by 요매(고양이젤리)")
    lbl_credit:EnableHitTest(false)

    -- esc close timer
    local esc_timer = frame:CreateOrGetControl("timer", "esc_timer", 0, 0)
    AUTO_CAST(esc_timer)
    esc_timer:SetUpdateScript("AA_esc_check")
    esc_timer:Start(0.05)

    -- status refresh timer (1 sec, on UI frame)
    local refresh_timer = frame:CreateOrGetControl("timer", "refresh_timer", 0, 0)
    AUTO_CAST(refresh_timer)
    refresh_timer:SetUpdateScript("AA_ui_refresh_tick")
    refresh_timer:Start(1.0)

    frame:ShowWindow(1)
    AA_refresh_ui()
end

function AA_close_frame()
    if g.running then
        AA_stop()
    end
    local frame_name = addonNameLower .. "_main"
    local frame = ui.GetFrame(frame_name)
    if frame then
        ui.DestroyFrame(frame_name)
    end
end

function AA_esc_check(frame)
    if keyboard.IsKeyPressed("ESCAPE") == 1 then
        AA_close_frame()
    end
end

function AA_ui_refresh_tick()
    AA_refresh_ui()
end

-- ============================================================
-- UI Button Callbacks
-- ============================================================
function AA_on_type_click(frame, ctrl)
    AUTO_CAST(ctrl)
    local cmd = ctrl:GetUserValue("MSG_CMD")
    g.settings.msg_type = cmd
    AA_save_settings()
    -- refresh type button colors
    local main_frame = ui.GetFrame(addonNameLower .. "_main")
    if not main_frame then return end
    for i, t in ipairs(MSG_TYPES) do
        local btn = GET_CHILD(main_frame, "btn_type_" .. i)
        AUTO_CAST(btn)
        if t.cmd == cmd then
            btn:SetText("{ol}{s14}{" .. t.color .. "}" .. AA_L(t.label_key))
        else
            btn:SetText("{ol}{s14}" .. AA_L(t.label_key))
        end
    end
end

function AA_on_start_click()
    local frame_name = addonNameLower .. "_main"
    local frame = ui.GetFrame(frame_name)
    if not frame then return end

    local edit_interval = GET_CHILD(frame, "edit_interval")
    AUTO_CAST(edit_interval)
    local edit_message = GET_CHILD(frame, "edit_message")
    AUTO_CAST(edit_message)

    local interval = tonumber(edit_interval:GetText()) or 60
    local message = edit_message:GetText() or ""

    g.settings.interval = interval
    g.settings.message = message

    AA_start()
end

function AA_on_stop_click()
    AA_stop()
end

function AA_on_lang_click()
    local lang = g.settings.lang or "kor"
    g.settings.lang = (lang == "kor") and "eng" or "kor"
    AA_save_settings()
    -- destroy current frame, then reopen after a short delay
    local frame_name = addonNameLower .. "_main"
    local frame = ui.GetFrame(frame_name)
    if frame then
        ui.DestroyFrame(frame_name)
    end
    local reopen_timer = g.frame:CreateOrGetControl("timer", "lang_reopen_timer", 0, 0)
    AUTO_CAST(reopen_timer)
    reopen_timer:SetUpdateScript("AA_lang_reopen")
    reopen_timer:Start(0.05)
end

function AA_lang_reopen()
    local reopen_timer = GET_CHILD(g.frame, "lang_reopen_timer")
    if reopen_timer then
        AUTO_CAST(reopen_timer)
        reopen_timer:Stop()
    end
    AA_open_frame()
end

-- ============================================================
-- UI Refresh
-- ============================================================
function AA_refresh_ui()
    local frame_name = addonNameLower .. "_main"
    local frame = ui.GetFrame(frame_name)
    if not frame or frame:IsVisible() ~= 1 then
        return
    end

    local lbl_status = GET_CHILD(frame, "lbl_status")
    local lbl_start_time = GET_CHILD(frame, "lbl_start_time")
    local lbl_count = GET_CHILD(frame, "lbl_count")
    local lbl_megaphone = GET_CHILD(frame, "lbl_megaphone")

    if g.running then
        local elapsed = os.time() - (g.start_time or os.time())
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = elapsed % 60
        local elapsed_str = string.format("%02d:%02d:%02d", h, m, s)
        lbl_status:SetText("{ol}{s14}{#00ff00}" .. string.format(AA_L("status_running"), elapsed_str))
    else
        lbl_status:SetText("{ol}{s14}" .. AA_L("status_stopped"))
    end

    lbl_start_time:SetText("{ol}{s14}" .. string.format(AA_L("start_time"), g.start_time_str or "--:--:--"))
    lbl_count:SetText("{ol}{s14}" .. string.format(AA_L("send_count"), g.shout_count or 0))

    local msg_type = g.settings and g.settings.msg_type or "/y"
    if msg_type == "/y" then
        local megaphone_count = 0
        pcall(function()
            megaphone_count = session.GetInvItemCountByType(645001) or 0
        end)
        lbl_megaphone:SetText("{ol}{s14}" .. string.format(AA_L("megaphone_count"), megaphone_count))
    else
        lbl_megaphone:SetText("")
    end
end

-- ============================================================
-- Norisan Menu
-- ============================================================
function AA_make_menu()
    _G["norisan"] = _G["norisan"] or {}
    _G["norisan"]["MENU"] = _G["norisan"]["MENU"] or {}
    _G["norisan"]["MENU"]["AUTO_ADS"] = {
        name = "Auto Ads",
        icon = "sysmenu_sys",
        func = "AA_open_frame",
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

-- norisan_menu system (shared across addons)
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
