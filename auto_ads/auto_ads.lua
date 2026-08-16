-- v1.0.0 first release
-- v1.1.0 restyle the window to the shared theme and fix ESC stopping a closed run
local addonName = "auto_ads"
local version = "1.1.0"
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
        msg_type_label      = "CHANNEL",
        settings_label      = "SETTINGS",
        status_label        = "STATUS",
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
        credit_name         = "요매",
        credit_tip          = "{ol}요매에게 귓속말",
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
        msg_type_label      = "CHANNEL",
        settings_label      = "SETTINGS",
        status_label        = "STATUS",
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
        credit_name         = "Yomae",
        credit_tip          = "{ol}Whisper to Yomae",
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
-- 창 배경은 스킨 + 알파로 낸다. groupbox 는 SetAlpha 가 없어서 구역 투명도는 스킨으로만 낸다
-- (cupole_manager / hideplayer 와 같은 값. `.claude/docs/addon-theme-style.md` §2)
-- the window gets its translucency from skin + alpha; a groupbox has no SetAlpha, so the
-- regions can only get theirs from a skin. same values as cupole_manager and hideplayer
local AA_UI_SKIN = "bg2"
local AA_UI_ALPHA = 110
local AA_SECTION_SKIN = "blackbox_op_50"     -- 구역 패널 / region panel
local AA_INPUT_SKIN = "blackbox_op_80"       -- 입력칸·선택된 버튼 / inputs and the active button

local FRAME_W = 560
local FRAME_H = 410
local PAD = 14                       -- 창 좌우 여백 / window side padding
local INNER = FRAME_W - PAD * 2
local SEC_INSET = 6                  -- 구역 패널 안쪽 여백 / padding inside a region panel
local CLOSE_SIZE = 36                -- 제목 {s22} 에 맞춘 크기 / sized to the {s22} title

-- 세로 배치. 구역마다 머리글 -> 패널 순서이고, 패널이 끝나면 다음 머리글까지 12px 띄운다
-- vertical layout: heading then panel per region, 12px before the next heading
local TITLE_Y = 10
local TITLE_LINE_Y = 48
local S1_HEAD_Y, S1_PANEL_Y, S1_PANEL_H = 58, 80, 42
local S2_HEAD_Y, S2_PANEL_Y, S2_PANEL_H = 134, 156, 76
local BTN_Y, BTN_H = 244, 32
local S3_HEAD_Y, S3_PANEL_Y, S3_PANEL_H = 288, 310, 60
local CREDIT_Y = 380

-- 선택된 채널 글자색 = 게임 채팅창의 채널 버튼 색 그대로.
-- 값 출처는 클라 `chat/chat.xml` 의 userconfig `COLOR_BTN_*` (채팅 종류 버튼에 SetColorTone 으로
-- 쓰이는 값. chat_type.lua:44 참조). 인덱스는 1 일반 / 2 외침 / 3 파티 / 4 길드 / 5 귓속말 / 9 길드강조.
-- 길드강조가 9 인 것은 chatframe.xml 의 TEXTCHAT_FONTSTYLE_GUILD_NOTICE(#FF44FF) 와
-- COLOR_BTN_9 가 정확히 같은 값이라 확인된다
-- the selected channel takes the colour of the game's own chat-type button. values come from the
-- client's chat/chat.xml userconfig COLOR_BTN_* (fed to SetColorTone in chat_type.lua:44).
-- index 9 is guild notice, confirmed because it matches TEXTCHAT_FONTSTYLE_GUILD_NOTICE exactly
local MSG_TYPES = {
    { cmd = "/s",  label_key = "type_normal",       color = "#FFFFFF" },   -- COLOR_BTN_1 일반
    { cmd = "/y",  label_key = "type_shout",        color = "#FF8A00" },   -- COLOR_BTN_2 외침
    { cmd = "/g",  label_key = "type_guild",        color = "#E596FF" },   -- COLOR_BTN_4 길드
    -- 길드강조만 버튼 색(COLOR_BTN_9 = #FF44FF)을 안 쓴다. 그 값은 자홍에 가까워 바로 위의
    -- 길드(#E596FF)와 잘 구분되지 않는다. 대신 같은 chat.xml 의 길드 대화 본문 색을 쓴다
    -- guild notice is the one channel that does not take its button colour (COLOR_BTN_9 = #FF44FF):
    -- that value reads as magenta and sits too close to guild above it. this is the guild message
    -- body colour from the same chat.xml instead
    { cmd = "/gn", label_key = "type_guild_notice", color = "#A735DC" },   -- COLOR_MY_GUILD 진한 보라
}

-- 구역 머리글 + 그 아래 패널. 패널을 먼저 만들면 머리글이 가려지므로 머리글을 먼저 만든다
-- (TOS 는 생성 순서가 곧 z-order)
-- a region heading and the panel under it. the heading is created first because TOS draws in
-- creation order and a later panel would cover it
local function AA_section(frame, key, y, text, panel_y, panel_h)
    local head = frame:CreateOrGetControl("richtext", key .. "_head", PAD + 2, y, INNER, 20)
    AUTO_CAST(head)
    head:SetFontName("white_16_ol")
    head:SetText("{ol}{s14}" .. text)
    head:EnableHitTest(false)

    local panel = frame:CreateOrGetControl("groupbox", key .. "_panel", PAD, panel_y, INNER, panel_h)
    AUTO_CAST(panel)
    panel:SetSkinName(AA_SECTION_SKIN)
    panel:EnableScrollBar(0)
    panel:EnableHittestGroupBox(false)
    return panel
end

-- 클라 search_editbox 방식: 보이는 박스를 깔고 그 안에 skin 없는 edit 을 넣어야
-- 캐럿이 테두리에 붙지 않는다. 박스는 hittest 를 꺼서 클릭을 edit 에 넘긴다
-- the client's search_editbox shape: a visible box with a skinless edit inside, so the caret
-- keeps its inset. the box has hit test off so the edit still takes the click
local function AA_input(frame, key, x, y, w, text)
    local box = frame:CreateOrGetControl("groupbox", key .. "_bg", x, y, w, 26)
    AUTO_CAST(box)
    box:SetSkinName(AA_INPUT_SKIN)
    box:EnableScrollBar(0)
    box:EnableHittestGroupBox(false)

    local edit = frame:CreateOrGetControl("edit", key, x + 6, y + 3, w - 12, 20)
    AUTO_CAST(edit)
    edit:SetSkinName("None")
    edit:SetFontName("white_14_ol")
    edit:SetTextAlign("left", "center")
    edit:SetText(text or "")
    return edit
end

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
    -- 창은 파괴하지 않고 숨기므로(테마 §5) 이미 있으면 그대로 다시 쓴다
    -- the window is hidden rather than destroyed, so reuse it when it already exists
    if not frame then
        frame = ui.CreateNewFrame("notice_on_pc", frame_name, 0, 0, 0, 0)
        AUTO_CAST(frame)
        local sw = ui.GetClientInitialWidth()
        local sh = ui.GetClientInitialHeight()
        frame:SetPos((sw - FRAME_W) / 2, (sh - FRAME_H) / 2)
    end
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(FRAME_W, FRAME_H)
    frame:SetSkinName(AA_UI_SKIN)
    frame:SetAlpha(AA_UI_ALPHA)
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(92)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)

    AA_build_frame(frame)

    -- ESC 닫기 타이머. 숨겨도 프레임과 타이머는 계속 살아 있으므로 IsVisible 가드가 필수다
    -- the frame and its timers keep running while hidden, hence the IsVisible guard in the tick
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

-- 창 내용 전체를 다시 그린다. 언어를 바꿀 때도 이 함수만 다시 부르면 된다
-- redraws the whole window; switching the language just calls this again
function AA_build_frame(frame)
    local title = frame:CreateOrGetControl("richtext", "title", PAD + 2, TITLE_Y, 240, 32)
    AUTO_CAST(title)
    title:SetText("{ol}{s22}{b}Auto Ads")
    title:EnableHitTest(false)

    -- 닫기 버튼. SetImage 가 크기를 이미지 원본으로 되돌리므로 반드시 뒤에서 Resize 한다(테마 §11).
    -- 제목 글자(위 10, 높이 32)의 세로 중앙 26 에 맞춘다 -> 위 여백 = 26 - 크기/2
    -- SetImage resets the control to the image's native size, so Resize AFTER it. centred on the
    -- title text (top 10, height 32 -> centre 26): top margin = 26 - size/2
    local close = frame:CreateOrGetControl("picture", "close", CLOSE_SIZE, CLOSE_SIZE, ui.RIGHT, ui.TOP, 0,
        26 - CLOSE_SIZE / 2, PAD, 0)
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetEnableStretch(1)
    close:Resize(CLOSE_SIZE, CLOSE_SIZE)
    close:SetMargin(0, 26 - CLOSE_SIZE / 2, PAD, 0)
    close:EnableHitTest(1)
    close:SetEventScript(ui.LBUTTONUP, "AA_close_frame")

    -- 한/영 전환. 닫기 버튼 왼쪽에 간격 8 을 두고 붙인다
    -- language toggle, 8px left of the close button
    local lang = g.settings.lang or "kor"
    local btn_lang = frame:CreateOrGetControl("button", "btn_lang", 46, 22, ui.RIGHT, ui.TOP, 0, 26 - 11,
        PAD + CLOSE_SIZE + 8, 0)
    AUTO_CAST(btn_lang)
    btn_lang:SetSkinName(AA_INPUT_SKIN)
    btn_lang:SetText("{ol}{s12}" .. ((lang == "kor") and "KOR" or "ENG"))
    btn_lang:SetOverSound("button_over")
    btn_lang:SetClickSound("button_click_stats")
    btn_lang:SetEventScript(ui.LBUTTONUP, "AA_on_lang_click")

    local title_line = frame:CreateOrGetControl("labelline", "title_line", PAD, TITLE_LINE_Y, INNER, 3)
    AUTO_CAST(title_line)
    title_line:SetSkinName("labelline2")

    -- 구역 1: 메시지 종류 / region 1: message channel
    AA_section(frame, "sec_type", S1_HEAD_Y, AA_L("msg_type_label"), S1_PANEL_Y, S1_PANEL_H)

    local type_w = math.floor((INNER - SEC_INSET * 2 - 8 * 3) / 4)
    local type_y = S1_PANEL_Y + math.floor((S1_PANEL_H - 28) / 2)
    for i, t in ipairs(MSG_TYPES) do
        local bx = PAD + SEC_INSET + (i - 1) * (type_w + 8)
        local btn = frame:CreateOrGetControl("button", "btn_type_" .. i, bx, type_y, type_w, 28)
        AUTO_CAST(btn)
        btn:SetOverSound("button_over")
        btn:SetClickSound("button_click_stats")
        btn:SetUserValue("MSG_CMD", t.cmd)
        btn:SetEventScript(ui.LBUTTONUP, "AA_on_type_click")
    end
    AA_set_type_visual(frame)

    -- 구역 2: 주기와 메시지 / region 2: interval and message
    AA_section(frame, "sec_input", S2_HEAD_Y, AA_L("settings_label"), S2_PANEL_Y, S2_PANEL_H)

    local label_x = PAD + SEC_INSET + 4
    local input_x = PAD + SEC_INSET + 120
    local input_right = PAD + INNER - SEC_INSET
    local row1_y = S2_PANEL_Y + 10
    local row2_y = S2_PANEL_Y + 44

    local lbl_interval = frame:CreateOrGetControl("richtext", "lbl_interval", label_x, row1_y + 4, 116, 20)
    AUTO_CAST(lbl_interval)
    lbl_interval:SetText("{ol}{s13}" .. AA_L("interval_label"))
    lbl_interval:EnableHitTest(false)
    AA_input(frame, "edit_interval", input_x, row1_y, 140, tostring(g.settings.interval or 60))

    local lbl_message = frame:CreateOrGetControl("richtext", "lbl_message", label_x, row2_y + 4, 116, 20)
    AUTO_CAST(lbl_message)
    lbl_message:SetText("{ol}{s13}" .. AA_L("message_label"))
    lbl_message:EnableHitTest(false)
    AA_input(frame, "edit_message", input_x, row2_y, input_right - input_x, g.settings.message or "")

    -- 시작 / 정지. 가운데 정렬 / start and stop, centred
    local btn_w, btn_gap = 100, 20
    local btn_x = math.floor((FRAME_W - btn_w * 2 - btn_gap) / 2)
    local btn_start = frame:CreateOrGetControl("button", "btn_start", btn_x, BTN_Y, btn_w, BTN_H)
    AUTO_CAST(btn_start)
    btn_start:SetText("{ol}{s14}" .. AA_L("btn_start"))
    btn_start:SetOverSound("button_over")
    btn_start:SetClickSound("button_click_stats")
    btn_start:SetEventScript(ui.LBUTTONUP, "AA_on_start_click")

    local btn_stop = frame:CreateOrGetControl("button", "btn_stop", btn_x + btn_w + btn_gap, BTN_Y, btn_w, BTN_H)
    AUTO_CAST(btn_stop)
    btn_stop:SetText("{ol}{s14}" .. AA_L("btn_stop"))
    btn_stop:SetOverSound("button_over")
    btn_stop:SetClickSound("button_click_stats")
    btn_stop:SetEventScript(ui.LBUTTONUP, "AA_on_stop_click")

    -- 구역 3: 상태. 2x2 로 놓아야 4줄로 늘어놓는 것보다 창이 낮아진다
    -- region 3: status, laid out 2x2 so the window stays shorter than four stacked lines
    AA_section(frame, "sec_status", S3_HEAD_Y, AA_L("status_label"), S3_PANEL_Y, S3_PANEL_H)

    local col1_x = PAD + SEC_INSET + 4
    local col2_x = PAD + math.floor(INNER / 2) + 4
    local col_w = math.floor(INNER / 2) - SEC_INSET - 8
    local srow1_y = S3_PANEL_Y + 8
    local srow2_y = srow1_y + 24
    local status_cells = {
        { "lbl_status", col1_x, srow1_y },
        { "lbl_start_time", col2_x, srow1_y },
        { "lbl_count", col1_x, srow2_y },
        { "lbl_megaphone", col2_x, srow2_y },
    }
    for _, cell in ipairs(status_cells) do
        local lbl = frame:CreateOrGetControl("richtext", cell[1], cell[2], cell[3], col_w, 20)
        AUTO_CAST(lbl)
        lbl:EnableHitTest(false)
    end

    -- 제작자 표기는 장식이므로 실패해도 창은 떠야 한다 / decorative: must never take the window down
    pcall(AA_credit_render, frame, FRAME_W, CREDIT_Y, PAD)
end

-- 선택된 종류만 진한 배경 + 색 글씨, 나머지는 투명 + 회색 (테마 §4 의 탭과 같은 규칙)
-- the selected channel gets the darker background and coloured text; the rest stay transparent
-- and grey, the same rule the theme uses for tabs
function AA_set_type_visual(frame)
    local current = (g.settings and g.settings.msg_type) or "/y"
    for i, t in ipairs(MSG_TYPES) do
        local btn = GET_CHILD(frame, "btn_type_" .. i)
        if btn then
            AUTO_CAST(btn)
            if current == t.cmd then
                btn:SetSkinName(AA_INPUT_SKIN)
                btn:SetText("{ol}{s13}{" .. t.color .. "}" .. AA_L(t.label_key))
            else
                btn:SetSkinName("None")
                btn:SetText("{ol}{s13}{#AAAAAA}" .. AA_L(t.label_key))
            end
        end
    end
end

-- ============================================================
-- 제작자 표기 ("made by [길드 엠블럼] 요매")
--   길드 엠블럼은 UI 이미지가 아니라 서버에서 받아오는 PNG 라서 SetImage 가 아니라
--   picture:SetFileName 으로 붙인다. 글자 폭은 상수로 잡으면 다국어에서 엠블럼과 겹치므로
--   GetTextWidth 로 재서 오른쪽 정렬한다. 클릭은 picture 에만 건다 --
--   런타임에 만든 richtext 는 클릭 이벤트를 받지 못한다
--   the emblem is a downloaded PNG, so it goes in via picture:SetFileName; the caption width is
--   measured, never guessed; and only the picture takes the click (runtime richtext cannot)
-- ============================================================
local AA_CREDIT_H = 18
local AA_CREDIT_EMBLEM = 16
local AA_CREDIT_GAP = 3
local AA_CREDIT_MADEBY_W = 64   -- GetTextWidth 실패 시 예비 폭 / fallback if the measure fails
local AA_CREDIT_NAME_W = 44
local AA_CREDIT_GUILD_ID = "1038076415618784"    -- 고양이젤리
local AA_CREDIT_WHISPER_NAME = "요매"

function AA_credit_render(parent, parent_w, y, pad)
    -- ⚠️ 이름과 툴팁은 AA_L 로 뽑는다. 다른 애드온은 클라 언어(option.GetCurrentCountry())를
    -- 따르지만 auto_ads 는 창 안에 KOR/ENG 토글이 따로 있어서, 클라 언어를 보면 ENG 로 바꿔도
    -- "요매" 가 그대로 남는다
    -- ⚠️ the name and tooltip come from AA_L. the other addons follow the client language, but
    -- auto_ads has its own KOR/ENG toggle: reading the client language left the Korean name in
    -- place after switching the window to English
    local made_by = parent:CreateOrGetControl("richtext", "credit_madeby", pad, y, AA_CREDIT_MADEBY_W, AA_CREDIT_H)
    AUTO_CAST(made_by)
    made_by:SetText("{ol}{s12}{#AAAAAA}made by")

    local name = parent:CreateOrGetControl("richtext", "credit_name", pad, y, AA_CREDIT_NAME_W, AA_CREDIT_H)
    AUTO_CAST(name)
    name:SetText("{ol}{s12}" .. AA_L("credit_name"))

    -- 폭이 바뀌므로 매번 다시 재야 한다. 이름 길이가 다르면(요매 vs Yomae) 엠블럼 위치도 밀린다
    -- the width must be re-measured every time: a different name length moves the emblem too
    local made_w = made_by:GetTextWidth()
    if not made_w or made_w <= 0 then
        made_w = AA_CREDIT_MADEBY_W
    end
    local name_w = name:GetTextWidth()
    if not name_w or name_w <= 0 then
        name_w = AA_CREDIT_NAME_W
    end
    made_by:Resize(made_w, AA_CREDIT_H)
    name:Resize(name_w, AA_CREDIT_H)

    local total_w = made_w + AA_CREDIT_GAP + AA_CREDIT_EMBLEM + AA_CREDIT_GAP + name_w
    local cx = math.max(0, parent_w - pad - total_w)
    made_by:SetOffset(cx, y)

    local emblem = parent:CreateOrGetControl("picture", "credit_emblem", cx + made_w + AA_CREDIT_GAP,
        y + math.floor((AA_CREDIT_H - AA_CREDIT_EMBLEM) / 2), AA_CREDIT_EMBLEM, AA_CREDIT_EMBLEM)
    AUTO_CAST(emblem)
    -- ⚠️ CreateOrGetControl 은 이미 있는 컨트롤을 다시 배치하지 않는다. 언어를 바꾸면 이름 폭이
    -- 달라져(요매 vs Yomae) 엠블럼이 옛 자리에 남으므로 매번 SetOffset 으로 다시 놓는다
    -- ⚠️ CreateOrGetControl does not reposition an existing control. switching the language
    -- changes the name width, so the emblem has to be placed again every time
    emblem:SetOffset(cx + made_w + AA_CREDIT_GAP, y + math.floor((AA_CREDIT_H - AA_CREDIT_EMBLEM) / 2))
    emblem:SetEnableStretch(1)
    emblem:EnableHitTest(true)
    emblem:SetEventScript(ui.LBUTTONUP, "AA_credit_whisper")
    emblem:SetTextTooltip(AA_L("credit_tip"))

    name:SetOffset(cx + made_w + AA_CREDIT_GAP + AA_CREDIT_EMBLEM + AA_CREDIT_GAP, y)

    pcall(GetGuildEmblemImage, "AA_credit_emblem_loaded", AA_CREDIT_GUILD_ID)
end

function AA_credit_whisper()
    pcall(ui.WhisperTo, AA_CREDIT_WHISPER_NAME)
end

function AA_credit_emblem_loaded(code, return_json)
    if code ~= 200 then
        return
    end
    local frame = ui.GetFrame(addonNameLower .. "_main")
    if not frame then
        return
    end
    local emblem = GET_CHILD(frame, "credit_emblem")
    if not emblem then
        return
    end
    local ok_w, world_id = pcall(session.party.GetMyWorldIDStr)
    if not ok_w then
        return
    end
    local ok_n, image_name = pcall(guild.GetEmblemImageName, AA_CREDIT_GUILD_ID, world_id)
    if not ok_n or not image_name then
        return
    end
    AUTO_CAST(emblem)
    emblem:SetImage("")
    emblem:SetFileName(image_name)
end

function AA_close_frame()
    if g.running then
        AA_stop()
    end
    local frame_name = addonNameLower .. "_main"
    local frame = ui.GetFrame(frame_name)
    if frame then
        frame:ShowWindow(0)
    end
end

function AA_esc_check(frame)
    -- 창을 숨겨도 타이머는 계속 돌기 때문에, 가드가 없으면 창이 닫힌 상태에서 ESC 를 누를 때마다
    -- AA_close_frame 이 불려 실행 중인 전송이 멈춘다
    -- the timer keeps ticking while the window is hidden; without this guard every ESC would call
    -- AA_close_frame and stop a running broadcast
    if not frame or frame:IsVisible() ~= 1 then
        return
    end
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
    local main_frame = ui.GetFrame(addonNameLower .. "_main")
    if not main_frame then return end
    AA_set_type_visual(main_frame)
    AA_refresh_ui()
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
    -- 창을 부수고 다시 여는 대신 내용만 다시 그린다. 부수면 AA_close_frame 을 타지 않더라도
    -- 창이 한 번 사라졌다 나타나 깜빡이고, 타이머도 다시 만들어야 했다
    -- redraw in place instead of destroying and reopening: the old path made the window blink and
    -- forced the timers to be rebuilt
    local frame = ui.GetFrame(addonNameLower .. "_main")
    if not frame then
        return
    end
    AUTO_CAST(frame)
    -- 입력 중이던 값은 유지한다. 언어를 바꿨다고 사용자가 쓰던 메시지가 날아가면 안 된다
    -- keep what is typed: switching the language must not throw away the user's message
    local edit_interval = GET_CHILD(frame, "edit_interval")
    local edit_message = GET_CHILD(frame, "edit_message")
    if edit_interval then
        AUTO_CAST(edit_interval)
        g.settings.interval = tonumber(edit_interval:GetText()) or g.settings.interval
    end
    if edit_message then
        AUTO_CAST(edit_message)
        g.settings.message = edit_message:GetText() or g.settings.message
    end
    AA_build_frame(frame)
    AA_refresh_ui()
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
        lbl_status:SetText("{ol}{s13}{#00FF66}" .. string.format(AA_L("status_running"), elapsed_str))
    else
        lbl_status:SetText("{ol}{s13}{#AAAAAA}" .. AA_L("status_stopped"))
    end

    lbl_start_time:SetText("{ol}{s13}" .. string.format(AA_L("start_time"), g.start_time_str or "--:--:--"))
    lbl_count:SetText("{ol}{s13}" .. string.format(AA_L("send_count"), g.shout_count or 0))

    local msg_type = g.settings and g.settings.msg_type or "/y"
    if msg_type == "/y" then
        local megaphone_count = 0
        pcall(function()
            megaphone_count = session.GetInvItemCountByType(645001) or 0
        end)
        lbl_megaphone:SetText("{ol}{s13}" .. string.format(AA_L("megaphone_count"), megaphone_count))
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
