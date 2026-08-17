-- v1.0.0 first release
-- 편의 설정 HUD: 자주 바꾸는 그래픽/전투 옵션 5가지를 화면에서 바로 전환한다
-- 값은 저장하지 않는다: mini_addons 같은 다른 애드온도 같은 옵션을 로그인에 밀어넣으므로,
-- 사본을 들고 있다가 다시 적용하면 서로 덮어쓰는 싸움이 된다. 언제나 현재 값을 읽어 보여준다
-- convenient HUD: flip five frequently-changed graphics/combat options in place.
-- nothing is cached - other addons (mini_addons) push the same options at login, so keeping a
-- private copy and re-applying it would just be a fight over who writes last
local addonName = "convenient_hud"
local version = "1.0.0"
local author = "Yomae"

local addonNameLower = string.lower(addonName)

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]
local json = require("json")

-- Infrastructure: save_json (safe tmp-file write)
local function CH_save_json(path, tbl)
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
local function CH_load_json(path)
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
local function CH_create_folder(path)
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

CH_create_folder("../addons")
CH_create_folder("../addons/" .. addonNameLower)

-- 클라 언어에 따라 한국어 / 일본어 / 영어. option.GetCurrentCountry() 는 user.xml 의 language 를
-- 그대로 돌려주므로 KR=="kr", JP=="Japanese" 이고 나머지는 영어로 떨어뜨린다
-- pick Korean / Japanese / English by client language; GetCurrentCountry returns user.xml's
-- language verbatim, so KR is "kr" and JP is "Japanese", everything else falls back to English
local function CH_t(kr, en, jp)
    if g.lang == "kr" then
        return kr
    elseif g.lang == "Japanese" then
        return jp or en
    end
    return en
end

-- ============================================================
-- Option model
--   선명도는 % 가 아니라 0~255 알파다. 게임 설정창 표시값이 value/255*100 이라
--   버튼 라벨(%)에서 반올림이 맞아떨어지는 raw 값을 쓴다 (191 은 74% 로 보여서 192 사용)
--   clarity is a 0~255 alpha, not a percent: the game shows value/255*100, so these raw
--   values are picked so the label matches what the option window would display
-- ============================================================
local CH_CLARITY = {
    {pct = 10, raw = 26},   -- 게임 슬라이더 최소값 / the option slider's own minimum
    {pct = 25, raw = 64},
    {pct = 50, raw = 128},
    {pct = 75, raw = 192},
    {pct = 100, raw = 255}
}

-- kind 1/2/3 = 내 이펙트 / 다른 캐릭터 이펙트 / 보스 몬스터 이펙트
local CH_CLARITY_KINDS = {
    {key = "my_alpha", getter = "GetMyEffectTransparency", setter = "SetMyEffectTransparency"},
    {key = "other_alpha", getter = "GetOtherEffectTransparency", setter = "SetOtherEffectTransparency"},
    {key = "boss_alpha", getter = "GetBossMonsterEffectTransparency", setter = "SetBossMonsterEffectTransparency"}
}

local function CH_clarity_label(kind)
    if kind == 1 then
        return CH_t("내 이펙트 선명도", "My effect clarity", "自分のエフェクト鮮明度")
    elseif kind == 2 then
        return CH_t("다른 캐릭터 이펙트 선명도", "Other PC effect clarity", "他キャラのエフェクト鮮明度")
    end
    return CH_t("보스 몬스터 이펙트 선명도", "Boss effect clarity", "ボスモンスターのエフェクト鮮明度")
end

-- 설정창에서 직접 슬라이더를 옮기면 버튼값과 정확히 안 맞는다. 그럴 때 가까운 값을 억지로
-- 강조하면 거짓말이 되므로(60% 인데 50 이 켜져 있으면 틀린 표시) 아무것도 강조하지 않고
-- 실제 % 는 라벨에 그대로 보여준다
-- the slider may sit between our steps; highlighting the nearest one would lie (50 lit at 60%),
-- so highlight nothing and let the label carry the real percentage
local function CH_clarity_exact_index(raw)
    for i, step in ipairs(CH_CLARITY) do
        if step.raw == raw then
            return i
        end
    end
    return nil
end

-- 게임 설정창과 같은 방식으로 % 표시 (systemoption.lua:640)
local function CH_alpha_to_pct(raw)
    return math.floor((tonumber(raw) or 0) / 255 * 100)
end

local function CH_to_flag(value)
    if value == true then
        return 1
    elseif value == false then
        return 0
    end
    return (tonumber(value) == 1) and 1 or 0
end

-- ============================================================
-- Game option read / write
--   값은 저장하지 않는다. 이 옵션들은 mini_addons 같은 다른 애드온도 로그인 때 건드리므로,
--   우리가 따로 들고 있다가 다시 밀어넣으면 서로 덮어쓰는 싸움이 된다.
--   HUD 는 언제나 클라의 현재 값을 읽어 보여주고, 클릭한 값만 바꾼다
--   nothing is cached: other addons (mini_addons) push their own values at login, so keeping
--   a private copy and re-applying it would just be a fight over who writes last.
--   the HUD always reads the live client config and only writes what was clicked
-- ============================================================
-- 큐폴 자동물약. toggle_cupole_potion 애드온이 \ 키로 하는 것과 완전히 같은 경로를 쓴다.
-- 상태는 PC 오브젝트의 확장 속성에 있고(1=사용중), 전환은 서버 TX 한 번이다.
-- TX 이름의 'PORITON' 오타는 게임 쪽 이름이므로 그대로 써야 한다
-- same path the toggle_cupole_potion addon uses for its \ key: the state lives on the PC
-- object (1 = on) and the switch is a single server TX. the 'PORITON' typo is the game's own
local function CH_read_cupole_potion()
    local ok_p, player = pcall(GetMyPCObject)
    if not ok_p or not player then
        return 0
    end
    local ok_v, v = pcall(GetExProp, player, "cupole_auto_potion")
    return (ok_v and tonumber(v) == 1) and 1 or 0
end

-- 쿠폴 창에 있는 물약 아이콘도 같이 갱신한다(원본 애드온과 동일). 창이 없으면 그냥 넘어간다
-- also refresh the potion icon in the cupole windows, exactly as the original does
local function CH_set_potion_icon(frame, value)
    if not frame then
        return
    end
    local toggle = GET_CHILD_RECURSIVELY(frame, "PotionToggle")
    if not toggle then
        return
    end
    toggle:SetImage((value == 0) and "potionhudon" or "potionhudoff")
end

local function CH_toggle_cupole_potion()
    -- 도시에서는 전환이 막혀 있다. 원본과 같은 안내만 띄우고 아무것도 하지 않는다
    -- toggling is blocked in cities; show the same notice the original does and stop
    local ok_city, in_city = pcall(IS_IN_CITY)
    if ok_city and in_city == 1 then
        ui.SysMsg("[Cupole Potion] Cannot toggle in city")
        return false
    end
    local ok_p, player = pcall(GetMyPCObject)
    if not ok_p or not player then
        return false
    end
    local ok_v, cur = pcall(GetExProp, player, "cupole_auto_potion")
    if not ok_v then
        return false
    end
    pcall(CH_set_potion_icon, ui.GetFrame("cupole_external_addon"), cur)
    pcall(CH_set_potion_icon, ui.GetFrame("cupole_item"), cur)
    pc.ReqExecuteTx_Item("CUPOLE_PORITON_AUTO_USE_TOGGLE", 0, 0)
    CHAT_SYSTEM("[Cupole Potion] Auto-use → " .. ((cur == 0) and "ON" or "OFF"))
    return true
end

local function CH_read_cfg()
    local cfg = {}
    cfg.cupole_potion = CH_read_cupole_potion()
    cfg.other_pc_effect = CH_to_flag(config.GetXMLConfig("EnableOtherPCEffect"))
    local ok_ac, ac = pcall(config.GetEnableAutoCasting)
    cfg.auto_casting = ok_ac and CH_to_flag(ac) or 0
    for _, kind in ipairs(CH_CLARITY_KINDS) do
        local ok_v, v = pcall(config[kind.getter])
        cfg[kind.key] = (ok_v and tonumber(v)) or 0
    end
    return cfg
end

-- 게임 설정창이 체크박스를 누를 때 실제로 부르는 함수를 그대로 쓴다.
-- 정의는 script_client.ipf 안에 있어 소스를 못 읽지만, 런타임에는 전역이라 호출은 된다
-- (systemoption.lua:1090-1091 이 이 이름으로 호출한다).
-- 형제 함수 EFFECT_TRANSPARENCY_ON 이 그렇듯 systemoption 프레임을 만질 가능성이 높아,
-- 설정창을 한 번도 안 연 세션에서는 프레임이 없어 실패할 수 있다 -> pcall 후 config 경로로 대체.
-- 어느 쪽이든 ChangeXMLConfig 로 값은 반드시 남기므로 최소한 다음 접속에는 반영된다
-- call exactly what the option window's checkbox calls. its definition lives in
-- script_client.ipf (unreadable - encrypted), but it is a global at runtime.
-- like its sibling EFFECT_TRANSPARENCY_ON it probably touches the systemoption frame, which
-- may not exist in a session that never opened the options window - hence pcall + fallback.
-- either way ChangeXMLConfig stores the value, so it applies on the next login at worst
local function CH_apply_other_pc_effect(flag)
    local fn = (flag == 1) and _G.ENABLE_OTHER_PC_EFFECT_CHECK or _G.ENABLE_OTHER_PC_EFFECT_UNCHECK
    local applied = false
    if type(fn) == "function" then
        applied = pcall(fn)
    end
    if not applied then
        pcall(config.EnableOtherPCEffect, flag)
    end
    config.ChangeXMLConfig("EnableOtherPCEffect", tostring(flag))
end

local function CH_apply_auto_casting(flag)
    pcall(config.SetEnableAutoCasting, flag)
end

-- 선명도 3종은 "이펙트 선명도 조절 사용" 이 꺼져 있으면 설정창이 열릴 때 전부 255 로 되돌아간다
-- (systemoption.lua:487). 이 항목은 config.ies 에 ClientScp 가 없어 저장만 하면 된다
-- with the master toggle off, opening the option window resets all three sliders to 255;
-- the entry has no ClientScp in config.ies, so storing it is enough
local function CH_apply_clarity(kind_index, raw)
    local kind = CH_CLARITY_KINDS[kind_index]
    if not kind then
        return
    end
    config.ChangeXMLConfig("EnableEffectTransparency", "1")
    pcall(config[kind.setter], raw)
end

-- ============================================================
-- Init
-- ============================================================
function CONVENIENT_HUD_ON_INIT(addon, frame)
    frame:ShowWindow(1)
    g.addon = addon
    g.frame = frame
    g.lang = option.GetCurrentCountry()
    addon:RegisterMsg("GAME_START_3SEC", "CH_GAME_START")
end

function CH_GAME_START()
    g.active_id = tostring(session.loginInfo.GetAID())
    CH_create_folder("../addons/" .. addonNameLower .. "/" .. g.active_id)
    CH_load_settings()
    CH_hud_create()
    -- TP 상점이 닫아버린 HUD 를 되살리는 감시. 등록은 한 번만 한다
    -- (GAME_START_3SEC 는 캐릭터 입장마다 오므로 매번 RegisterMsg 하면 중복 등록된다)
    -- watch that restores a HUD the TP shop closed; registered once
    if not g.hud_guard_on then
        g.hud_guard_on = true
        g.addon:RegisterMsg("ESCAPE_PRESSED", "CH_hud_guard")
    end
    g.frame:StopUpdateScript("CH_hud_guard_tick")
    g.frame:RunUpdateScript("CH_hud_guard_tick", 2.0)
end

-- ============================================================
-- Settings Save/Load
--   저장하는 것은 HUD 위치와 열림 상태뿐이다 (게임 옵션 값은 저장하지 않는다)
--   only the HUD's own position and open state are stored - never the game option values
-- ============================================================
function CH_save_settings()
    CH_save_json(g.settings_path, g.settings)
end

function CH_load_settings()
    g.settings_path = string.format("../addons/%s/%s/%s.json", addonNameLower, g.active_id, addonNameLower)
    local changed = false
    local settings = CH_load_json(g.settings_path)
    if not settings then
        settings = {}
        changed = true
    end
    if not settings.hud then
        -- position (x/y) is initialised by CH_hud_create (right edge, vertically centered)
        settings.hud = {open = 0}
        changed = true
    end
    -- 열림 상태는 이어받지 않는다. mini_addons 처럼 우리보다 늦게 로드되는 애드온이 옵션 값을
    -- 나중에 바꾸므로, 접속 직후에 패널이 열려 있으면 그 시점의 낡은 값을 그려놓게 된다.
    -- 항상 닫힌 채로 시작하고, 사용자가 열 때 현재 값을 새로 읽는다
    -- never restore the open state: addons that load after us (mini_addons) change these options
    -- later, so a panel that is already open at login would be showing pre-change values.
    -- start closed every time and read the live values when the user opens it
    if settings.hud.open ~= 0 then
        settings.hud.open = 0
        changed = true
    end
    -- v1.0.0 이 캐릭터별로 들고 있던 옵션 값. 더 이상 쓰지 않으므로 정리한다
    -- per-character option values kept by v1.0.0; no longer used, so drop them
    if settings.chars then
        settings.chars = nil
        changed = true
    end
    g.settings = settings
    if changed then
        CH_save_settings()
    end
end

-- ============================================================
-- HUD (toggle bar + option panel)
--   토글 바 프레임은 한 번 만들고 유지하고, 패널 프레임만 열고 닫을 때 다시 만든다.
--   패널 버튼을 누른 핸들러 안에서 패널을 부수면 안 되므로 갱신은 제자리에서 한다
--   the toggle bar frame is created once and kept; only the panel is rebuilt on toggle.
--   a panel button's own handler must not destroy the panel, so refreshes happen in place
-- ============================================================
local CH_BAR_W = 140
local CH_BAR_H = 40
local CH_ICON_W = 51
local CH_ICON_H = 22
local CH_ICON_MARGIN = 12
local CH_PANEL_W = 244
local CH_PAD = 8
local CH_SECTION_GAP = 6
local CH_TOGGLE_ROW_H = 26
local CH_LABEL_H = 18
local CH_BTN_H = 24
local CH_CLARITY_BTN_W = 43
local CH_CLARITY_BTN_GAP = 3
local CH_ALPHA = 110
local CH_POS_VER = 2    -- bump to re-apply the default start position on next load

local CH_TOGGLE_BTN_W = 84
local CH_TOGGLE_LABEL_W = CH_PANEL_W - CH_PAD * 2 - CH_TOGGLE_BTN_W - 4

-- ⚠️ 화면 크기 API 는 두 종류이고 좌표계가 다르다.
--   ui.GetClientInitialWidth/Height  = UI 좌표계 (프레임 배치용). SetPos/SetMargin 은 이 값 기준.
--   option.GetClientWidth/Height     = 실제 화면 픽셀. movie.PlayUIEffect 같은 화면 좌표용.
-- 프레임을 화면 중앙에 놓을 땐 반드시 앞의 것을 쓴다(클라 선례: quickslotnexpbar.lua:1695).
-- option 쪽으로 바꿨다가 일반 모니터에서 창이 우하단으로 밀리는 회귀를 냈다(2026-08-16).
-- two different APIs with different coordinate spaces:
--   ui.GetClientInitialWidth/Height = UI space, what SetPos/SetMargin use - use this for frames
--   option.GetClientWidth/Height    = real screen pixels, for things like movie.PlayUIEffect
-- switching to option once pushed the window to the bottom-right on a normal monitor
local function CH_screen_size()
    return ui.GetClientInitialWidth(), ui.GetClientInitialHeight()
end

-- far-right edge, vertically centered
local function CH_hud_default_pos(hud)
    local sw, sh = CH_screen_size()
    hud.x = sw - CH_BAR_W - 4
    hud.y = math.floor(sh / 2) - math.floor(CH_BAR_H / 2)
end

-- 제작자 표기 줄. 길드 엠블럼은 서버에서 받아오는 이미지라 picture:SetFileName 으로 붙인다
-- credit line; the guild emblem is a downloaded file, so it goes in via picture:SetFileName
local CH_CREDIT_H = 18
local CH_CREDIT_EMBLEM = 16
local CH_CREDIT_GAP = 3
-- GetTextWidth 가 0 을 돌려줄 때만 쓰는 예비 폭 / fallback widths, used only if the measure fails
local CH_CREDIT_MADEBY_W = 64
local CH_CREDIT_NAME_W = 44
local CH_CREDIT_GUILD_ID = "1038076415618784"    -- 고양이젤리
local CH_CREDIT_WHISPER_NAME = "요매"             -- 표기는 언어별로 바뀌어도 귓말 대상은 실제 팀명

local function CH_panel_height()
    local toggles = (CH_TOGGLE_ROW_H + CH_SECTION_GAP) * 3
    local clarity = (CH_LABEL_H + CH_BTN_H + CH_SECTION_GAP) * 3
    return toggles + clarity + CH_CREDIT_H + CH_PAD * 2
end

-- ============================================================
-- 마우스 오버 밝기 / hover highlight
--   클라 기본 창은 xml 속성으로 처리한다: MouseOnAnim="btn_mouseover" MouseOffAnim="btn_mouseoff"
--   (accountwarehouse.xml:19 등). 런타임에 만든 컨트롤에는 그 속성을 줄 수 없다 —
--   `SetAnimation` 의 Lua 선례는 ingamealert.lua:38 의 openAnim/closeAnim 둘뿐이라
--   "MouseOnAnim" 키가 통한다는 근거가 없다.
--   대신 MOUSEON/MOUSEOFF 에 SetColorTone 을 건다 (picture 에 MOUSEON: job_select_guide.lua:98 /
--   button 에 SetColorTone: tpitem.lua:3690)
--   ⚠️ SetColorTone 은 곱연산이라 원색(FFFFFFFF)보다 밝게는 못 만든다. 평상시를 한 단계
--   낮추고 오버에서 원색으로 되돌리는 방식이다
--   the client uses xml attributes we cannot set on runtime-made controls, so the tone change
--   rides on MOUSEON/MOUSEOFF instead. tones multiply, so the resting one is stepped down
-- ============================================================
local CH_TONE_IDLE = "FFD2D2D2"
local CH_TONE_HOVER = "FFFFFFFF"

function CH_HOVER_ON(frame, ctrl)
    if ctrl == nil then
        return
    end
    local tone = ctrl:GetUserValue("CH_TONE_HOVER")
    -- 값이 없는 UserValue 는 "None" 을 돌려준다 / an unset user value reads back as "None"
    if tone ~= nil and tone ~= "" and tone ~= "None" then
        ctrl:SetColorTone(tone)
    end
end

function CH_HOVER_OFF(frame, ctrl)
    if ctrl == nil then
        return
    end
    local tone = ctrl:GetUserValue("CH_TONE_IDLE")
    if tone ~= nil and tone ~= "" and tone ~= "None" then
        ctrl:SetColorTone(tone)
    end
end

local function CH_hover(ctrl, idle, hover)
    if ctrl == nil then
        return
    end
    idle = idle or CH_TONE_IDLE
    hover = hover or CH_TONE_HOVER
    ctrl:SetUserValue("CH_TONE_IDLE", idle)
    ctrl:SetUserValue("CH_TONE_HOVER", hover)
    ctrl:SetColorTone(idle)
    ctrl:SetEventScript(ui.MOUSEON, "CH_HOVER_ON")
    ctrl:SetEventScript(ui.MOUSEOFF, "CH_HOVER_OFF")
end

local function CH_on_off_text(flag)
    if flag == 1 then
        return "{ol}{s14}{#66FF66}ON"
    end
    return "{ol}{s14}{#BBBBBB}OFF"
end

local function CH_clarity_text(pct, selected)
    if selected then
        return "{ol}{s14}{#FF3333}" .. pct
    end
    return "{ol}{s14}" .. pct
end

-- 라벨에 실제 % 를 같이 보여준다. 버튼과 안 맞는 값이어도 지금 값이 얼마인지는 항상 보인다
-- the live percentage rides along with the label, so the real value shows even when it does
-- not line up with any button
local function CH_clarity_section_text(kind, raw)
    return "{ol}{s13}" .. CH_clarity_label(kind) .. " {#AAAAAA}(" .. CH_alpha_to_pct(raw) .. "%)"
end

-- reflect open/closed state on the toggle bar: ability on/off icon
function CH_hud_set_toggle_visual(frame, open)
    local icon = GET_CHILD(frame, "hud_icon")
    if icon then
        icon:SetImage((open == 1) and "ability_on" or "ability_off")
    end
    local label = GET_CHILD(frame, "hud_label")
    if label then
        -- 제목은 언어와 무관하게 항상 같은 이름으로 둔다 (cupole preset 과 같은 2줄 표기)
        -- the caption stays the same in every language, two lines like the cupole preset bar
        label:SetText("{s10}Convenient{nl}HUD")
    end
end

-- 🔑 TP 상점을 열면 클라가 `ui.CloseAllOpenedUI()` 로 우리 HUD 까지 닫는다(tpitem.lua:505).
-- 상점을 닫을 때 부르는 `ui.OpenAllClosedUI()`(tpitem.lua:953)는 **애드온이 런타임에
-- ui.CreateNewFrame 으로 만든 프레임은 되살려주지 않아서** HUD 가 사라진 채 남았다.
-- 게임이 되돌려주기를 기대하지 말고 스스로 다시 세운다 (nexus indun_panel 도 ESCAPE_PRESSED
-- 로 같은 일을 한다). 프레임이 통째로 없을 수 있으므로 생성 경로를 다시 탄다
-- 🔑 the TP shop closes our HUD via ui.CloseAllOpenedUI, and the matching OpenAllClosedUI does
-- not restore frames an addon created at runtime, so we rebuild it ourselves
function CH_hud_guard()
    if not g.settings then
        return
    end
    local frame = ui.GetFrame(addonNameLower .. "_hud")
    if not frame or frame:IsVisible() == 0 then
        CH_hud_create()
    end
end

-- 타이머와 ESC 양쪽에 건다. 상점을 ESC 로 닫든 X 로 닫든 늦어도 2초 안에 돌아온다
-- both a timer and ESC, so either way of closing the shop brings it back within 2s
function CH_hud_guard_tick(frame)
    CH_hud_guard()
    return 1
end

-- creates the always-visible toggle bar frame (idempotent)
function CH_hud_create()
    if not g.settings then
        return
    end
    local hud = g.settings.hud
    if not hud then
        hud = {open = 0}
        g.settings.hud = hud
    end

    -- (re)apply default start position when the layout version changes
    if hud.ver ~= CH_POS_VER then
        CH_hud_default_pos(hud)
        hud.ver = CH_POS_VER
        CH_save_settings()
    end
    -- heal invalid / off-screen positions
    local sw, sh = CH_screen_size()
    -- ⚠️ 상한을 `sw - 20` 으로 잡으면 안 된다. `ui.GetClientInitialWidth` 는 환경에 따라 실제 UI
    -- 폭보다 작게 나오고(바로 아래 패널 보정 주석과 같은 이유), 그러면 HUD 를 오른쪽에 둔
    -- 사용자는 **맵을 옮길 때마다** 이 검사에 걸려 기본 위치로 되돌아갔다.
    -- 이건 설정이 깨졌을 때만 걸리면 되는 안전망이다 — 사용자가 직접 옮긴 좌표를 의심하지 말 것
    -- ⚠️ never bound this by sw - 20: ui.GetClientInitialWidth can read narrower than the real UI
    -- width, which made the guard fire on every map change and reset a right-hand HUD to default
    local max_x = math.max(sw, 1920) * 2
    local max_y = math.max(sh, 1080) * 2
    if type(hud.x) ~= "number" or type(hud.y) ~= "number" or hud.x < 0 or hud.x > max_x or hud.y < 0 or hud.y >
        max_y then
        CH_hud_default_pos(hud)
        CH_save_settings()
    end

    local frame_name = addonNameLower .. "_hud"
    local frame = ui.GetFrame(frame_name)
    if not frame then
        frame = ui.CreateNewFrame("notice_on_pc", frame_name, 0, 0, 0, 0)
    end
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(CH_BAR_W, CH_BAR_H)
    frame:SetSkinName("bg2")
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(90)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)
    frame:SetPos(hud.x, hud.y)
    frame:SetAlpha(CH_ALPHA)
    frame:SetEventScript(ui.LBUTTONUP, "CH_hud_drag")

    local label = frame:CreateOrGetControl("richtext", "hud_label", CH_BAR_W - CH_ICON_W - CH_ICON_MARGIN - 12, 30,
        ui.LEFT, ui.CENTER_VERT, 8, 0, 0, 0)
    label:SetFontName("white_16_ol")
    label:EnableHitTest(false)

    -- 이동 가능한 프레임에서는 button 이 드래그를 먹으므로 picture 를 쓴다
    -- a button would swallow the drag on a movable frame, so use a picture
    local icon = frame:CreateOrGetControl("picture", "hud_icon", CH_ICON_W, CH_ICON_H, ui.RIGHT, ui.CENTER_VERT, 0, 0,
        CH_ICON_MARGIN, 0)
    AUTO_CAST(icon)
    icon:SetEnableStretch(1)
    icon:EnableHitTest(1)
    icon:SetTextTooltip(CH_t("{ol}편의 설정 열기/닫기", "{ol}Toggle the convenient HUD", "{ol}便利設定の開閉"))
    CH_hover(icon)
    icon:SetEventScript(ui.LBUTTONUP, "CH_hud_toggle")

    CH_hud_set_toggle_visual(frame, hud.open)
    frame:ShowWindow(1)

    CH_hud_panel_render()
end

-- (re)builds or destroys the option panel based on open state
function CH_hud_panel_render()
    local hud = g.settings and g.settings.hud
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
    local cfg = CH_read_cfg()

    local panel_h = CH_panel_height()
    local _, sh = CH_screen_size()
    local px = hud.x
    local py = hud.y + CH_BAR_H + 2
    if py + panel_h > sh then
        py = math.max(0, sh - panel_h)
    end
    -- 가로 보정은 하지 않는다. 울트라와이드에서 ui.GetClientInitialWidth 가 실제 UI 폭보다
    -- 작게 잡히면 이 보정이 항상 걸려 패널이 한 자리에 고정되고 바를 따라오지 않았다.
    -- 패널은 바보다 104px 넓을 뿐이라 끝에서 조금 삐져나오는 편이 훨씬 낫다
    -- no horizontal clamp: on ultrawide, ui.GetClientInitialWidth can read narrower than the real
    -- UI width, so this clamp fired constantly and pinned the panel instead of letting it follow.
    -- the panel is only 104px wider than the bar, so a small overhang is the better trade

    local panel = ui.CreateNewFrame("notice_on_pc", panel_name, 0, 0, 0, 0)
    AUTO_CAST(panel)
    panel:RemoveAllChild()
    panel:Resize(CH_PANEL_W, panel_h)
    panel:SetSkinName("bg2")
    panel:SetTitleBarSkin("None")
    panel:SetLayerLevel(90)
    panel:EnableHittestFrame(1)
    panel:EnableMove(0)
    panel:SetPos(px, py)
    panel:SetAlpha(CH_ALPHA)

    local y = CH_PAD

    -- 1) 다른 캐릭터 이펙트 보기 / 2) 캐스팅·채널링 자동 시전
    local toggles = {
        {name = "opt_other_pc", key = "other_pc_effect",
         label = CH_t("다른 캐릭터 이펙트 보기", "Show other PC effects", "他キャラのエフェクト表示"),
         tip = CH_t("{ol}즉시 반영되지 않으면 재접속 후 적용됩니다",
             "{ol}If it does not change at once, it applies after re-entering",
             "{ol}すぐに反映されない場合は再接続後に適用されます")},
        {name = "opt_auto_cast", key = "auto_casting",
         label = CH_t("캐스팅/채널링 자동 시전", "Auto cast while casting", "キャスト/チャネリング自動詠唱"),
         tip = nil},
        {name = "opt_cupole_potion", key = "cupole_potion",
         label = CH_t("큐폴 자동물약 사용", "Cupole auto potion", "クポル自動ポーション"),
         tip = CH_t("{ol}도시에서는 전환할 수 없습니다", "{ol}Cannot be toggled in a city",
             "{ol}都市では切り替えできません")}
    }
    for i, item in ipairs(toggles) do
        local text = panel:CreateOrGetControl("richtext", item.name .. "_text", CH_PAD, y + 4, CH_TOGGLE_LABEL_W, 20)
        text:SetText("{ol}{s13}" .. item.label)
        text:EnableHitTest(false)

        local btn = panel:CreateOrGetControl("button", item.name, CH_PAD + CH_TOGGLE_LABEL_W + 4, y, CH_TOGGLE_BTN_W,
            CH_TOGGLE_ROW_H)
        AUTO_CAST(btn)
        btn:SetText(CH_on_off_text(cfg[item.key]))
        btn:SetUserValue("TOGGLE_INDEX", i)
        CH_hover(btn)
        btn:SetEventScript(ui.LBUTTONUP, "CH_hud_click_toggle")
        btn:SetOverSound("button_over")
        btn:SetClickSound("button_click_stats")
        if item.tip then
            btn:SetTextTooltip(item.tip)
        end
        y = y + CH_TOGGLE_ROW_H + CH_SECTION_GAP
    end

    -- 3~5) 선명도 3종
    for kind = 1, 3 do
        local raw = cfg[CH_CLARITY_KINDS[kind].key]
        local text = panel:CreateOrGetControl("richtext", "clar_text_" .. kind, CH_PAD, y, CH_PANEL_W - CH_PAD * 2,
            CH_LABEL_H)
        text:SetText(CH_clarity_section_text(kind, raw))
        text:EnableHitTest(false)
        y = y + CH_LABEL_H

        local selected = CH_clarity_exact_index(raw)
        for i, step in ipairs(CH_CLARITY) do
            local bx = CH_PAD + (i - 1) * (CH_CLARITY_BTN_W + CH_CLARITY_BTN_GAP)
            local btn = panel:CreateOrGetControl("button", string.format("clar_%d_%d", kind, i), bx, y,
                CH_CLARITY_BTN_W, CH_BTN_H)
            AUTO_CAST(btn)
            btn:SetText(CH_clarity_text(step.pct, i == selected))
            btn:SetUserValue("CLARITY_KIND", kind)
            btn:SetUserValue("CLARITY_STEP", i)
            CH_hover(btn)
            btn:SetEventScript(ui.LBUTTONUP, "CH_hud_click_clarity")
            btn:SetOverSound("button_over")
            btn:SetClickSound("button_click_stats")
        end
        y = y + CH_BTN_H + CH_SECTION_GAP
    end

    -- 제작자 표기: made by [길드 엠블럼]요매 — 패널 맨 아래 오른쪽.
    -- 글자 폭을 상수로 어림잡았더니 엠블럼과 겹쳤다. GetTextWidth 로 실제 폭을 재고
    -- 그 값으로 오른쪽 정렬해 다시 배치한다 (adventure_book_achieve_ui.lua:486 패턴)
    -- guessing the caption width made it collide with the emblem; measure the real width with
    -- GetTextWidth and lay the row out right-aligned from it
    -- 장식용이므로 실패해도 패널은 떠야 한다 / decorative: must never break the panel
    pcall(CH_credit_render, panel, y)

    panel:ShowWindow(1)
end


-- ⚠️ GetTextWidth / Resize / SetEventScript 는 캐스팅된 ui::CRichText 에만 있다.
-- AUTO_CAST 없이 부르면 에러가 나고, 그 컨트롤을 만든 창이 통째로 안 열린다
-- these live on a cast ui::CRichText; without AUTO_CAST the call errors and the window
-- that was building the control silently fails to appear
function CH_credit_render(panel, y)
    local tip = CH_t("{ol}요매에게 귓속말", "{ol}Whisper to Yomae", "{ol}Yomae にささやく")

    local made_by = panel:CreateOrGetControl("richtext", "credit_madeby", CH_PAD, y, CH_CREDIT_MADEBY_W, CH_CREDIT_H)
    AUTO_CAST(made_by)
    made_by:SetText("{ol}{s12}{#AAAAAA}made by")

    local name = panel:CreateOrGetControl("richtext", "credit_name", CH_PAD, y, CH_CREDIT_NAME_W, CH_CREDIT_H)
    AUTO_CAST(name)
    name:SetText("{ol}{s12}" .. CH_t("요매", "Yomae", "Yomae"))

    -- 글자를 넣은 뒤 실제 폭을 재고, 컨트롤도 그 폭에 맞춘다. 이름은 언어마다 길이가 달라서
    -- (요매 < Yomae) 상수로 잡으면 클릭 범위와 정렬이 어긋난다
    -- measure after setting the text and size the control to it: the name differs per language
    -- (요매 < Yomae), so a constant would misplace both the layout and the click area
    local made_w = made_by:GetTextWidth()
    if not made_w or made_w <= 0 then
        made_w = CH_CREDIT_MADEBY_W
    end
    local name_w = name:GetTextWidth()
    if not name_w or name_w <= 0 then
        name_w = CH_CREDIT_NAME_W
    end
    made_by:Resize(made_w, CH_CREDIT_H)
    name:Resize(name_w, CH_CREDIT_H)

    local total_w = made_w + CH_CREDIT_GAP + CH_CREDIT_EMBLEM + CH_CREDIT_GAP + name_w
    local cx = math.max(0, CH_PANEL_W - CH_PAD - total_w)
    made_by:SetOffset(cx, y)

    local emblem = panel:CreateOrGetControl("picture", "credit_emblem", cx + made_w + CH_CREDIT_GAP,
        y + math.floor((CH_CREDIT_H - CH_CREDIT_EMBLEM) / 2), CH_CREDIT_EMBLEM, CH_CREDIT_EMBLEM)
    AUTO_CAST(emblem)
    emblem:SetEnableStretch(1)

    name:SetOffset(cx + made_w + CH_CREDIT_GAP + CH_CREDIT_EMBLEM + CH_CREDIT_GAP, y)

    -- 크레딧 전체를 누르면 귓속말 창이 열린다 (richtext 클릭은 클라에도 선례 다수)
    -- clicking anywhere on the credit opens a whisper; clickable richtext is common in the client
    -- 클릭은 picture 에만 건다. 런타임에 만든 richtext 에 SetEventScript 를 거는 선례가
    -- 클라에 0건이고 실제로도 반응하지 않았다. picture 는 확실히 동작한다(HUD 토글 아이콘)
    -- only the picture takes the click: there is no client precedent for SetEventScript on a
    -- runtime-created richtext and it did not fire in game; pictures are proven (the HUD icon)
    emblem:EnableHitTest(true)
    CH_hover(emblem)
    emblem:SetEventScript(ui.LBUTTONUP, "CH_credit_whisper")
    emblem:SetTextTooltip(tip)

    -- 엠블럼은 서버에서 받아와야 하므로 비동기다. 실패하면 그림 없이 글자만 남는다
    -- the emblem has to be fetched, so this is async; on failure the text stands alone
    pcall(GetGuildEmblemImage, "CH_credit_emblem_loaded", CH_CREDIT_GUILD_ID)
end

-- GetGuildEmblemImage 의 콜백 (colony_battle_info.lua:247 과 같은 계약)
-- callback for GetGuildEmblemImage, same contract as colony_battle_info.lua:247
function CH_credit_emblem_loaded(code, return_json)
    if code ~= 200 then
        return
    end
    local panel = ui.GetFrame(addonNameLower .. "_hud_panel")
    if not panel then
        return
    end
    local emblem = GET_CHILD(panel, "credit_emblem")
    if not emblem then
        return
    end
    local ok_w, world_id = pcall(session.party.GetMyWorldIDStr)
    if not ok_w then
        return
    end
    local ok_n, image_name = pcall(guild.GetEmblemImageName, CH_CREDIT_GUILD_ID, world_id)
    if not ok_n or not image_name then
        return
    end
    emblem:SetImage("")
    emblem:SetFileName(image_name)
end

-- 패널을 부수지 않고 글자만 갱신한다 (버튼 자신의 클릭 핸들러에서 호출되므로)
-- refresh captions in place; called from a button's own handler, so never rebuild
function CH_hud_refresh_panel()
    local panel = ui.GetFrame(addonNameLower .. "_hud_panel")
    if not panel then
        return
    end
    local cfg = CH_read_cfg()
    local other_pc = GET_CHILD(panel, "opt_other_pc")
    if other_pc then
        other_pc:SetText(CH_on_off_text(cfg.other_pc_effect))
    end
    local potion = GET_CHILD(panel, "opt_cupole_potion")
    if potion then
        potion:SetText(CH_on_off_text(cfg.cupole_potion))
    end
    local auto_cast = GET_CHILD(panel, "opt_auto_cast")
    if auto_cast then
        auto_cast:SetText(CH_on_off_text(cfg.auto_casting))
    end
    for kind = 1, 3 do
        local raw = cfg[CH_CLARITY_KINDS[kind].key]
        local text = GET_CHILD(panel, "clar_text_" .. kind)
        if text then
            text:SetText(CH_clarity_section_text(kind, raw))
        end
        local selected = CH_clarity_exact_index(raw)
        for i, step in ipairs(CH_CLARITY) do
            local btn = GET_CHILD(panel, string.format("clar_%d_%d", kind, i))
            if btn then
                btn:SetText(CH_clarity_text(step.pct, i == selected))
            end
        end
    end
end

function CH_hud_toggle()
    local hud = g.settings and g.settings.hud
    if not hud then
        return
    end
    hud.open = (hud.open == 1) and 0 or 1
    CH_save_settings()
    local frame = ui.GetFrame(addonNameLower .. "_hud")
    if frame then
        CH_hud_set_toggle_visual(frame, hud.open)
    end
    CH_hud_panel_render()
end

function CH_hud_drag(frame, ctrl)
    if not frame then
        return
    end
    local hud = g.settings and g.settings.hud
    if not hud then
        return
    end
    hud.x = frame:GetX()
    hud.y = frame:GetY()
    CH_save_settings()
    -- keep the open panel attached under the bar while dragging
    if hud.open == 1 then
        local panel = ui.GetFrame(addonNameLower .. "_hud_panel")
        if panel then
            local _, sh = CH_screen_size()
            local py = hud.y + CH_BAR_H + 2
            local ph = panel:GetHeight()
            if py + ph > sh then
                py = math.max(0, sh - ph)
            end
            panel:SetPos(hud.x, py)
        end
    end
end

function CH_hud_click_toggle(parent, ctrl)
    local index = ctrl:GetUserIValue("TOGGLE_INDEX")
    local cfg = CH_read_cfg()
    if index == 3 then
        -- 자동물약은 클라 설정이 아니라 서버 TX 라서 SaveConfig 대상이 아니다.
        -- 서버 응답이 오기 전에는 GetExProp 이 예전 값을 주므로, 성공했으면 뒤집힌 값을
        -- 버튼에 먼저 반영한다(다시 열 때 실제 값으로 맞춰진다)
        -- this one is a server TX, not a client config, so SaveConfig does not apply.
        -- GetExProp still reports the old value until the server answers, so on success show
        -- the flipped value right away; reopening the panel re-reads the real state
        local ok = CH_toggle_cupole_potion()
        CH_hud_refresh_panel()
        if ok then
            local panel = ui.GetFrame(addonNameLower .. "_hud_panel")
            local btn = panel and GET_CHILD(panel, "opt_cupole_potion")
            if btn then
                btn:SetText(CH_on_off_text((cfg.cupole_potion == 1) and 0 or 1))
            end
        end
        return
    end
    if index == 1 then
        CH_apply_other_pc_effect((cfg.other_pc_effect == 1) and 0 or 1)
    else
        CH_apply_auto_casting((cfg.auto_casting == 1) and 0 or 1)
    end
    pcall(config.SaveConfig)
    CH_hud_refresh_panel()
end

function CH_hud_click_clarity(parent, ctrl)
    local kind = ctrl:GetUserIValue("CLARITY_KIND")
    local step_index = ctrl:GetUserIValue("CLARITY_STEP")
    local step = CH_CLARITY[step_index]
    if not step or not CH_CLARITY_KINDS[kind] then
        return
    end
    CH_apply_clarity(kind, step.raw)
    pcall(config.SaveConfig)
    CH_hud_refresh_panel()
end

-- 크레딧을 누르면 요매에게 귓속말 (ui.WhisperTo 는 팀명을 받는다 / takes the family name)
function CH_credit_whisper()
    pcall(ui.WhisperTo, CH_CREDIT_WHISPER_NAME)
end
