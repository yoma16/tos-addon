-- v1.0.0 first release
local addonName = "toggle_cupole_potion"
local acutil = require("acutil")

local lastToggleTime = 0
local DEBOUNCE_SEC = 0.5
local POLL_INTERVAL = 0.01
local version = "1.0.0"
local author = "Yomae"

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]


local function tcp_toggle()
    if IS_IN_CITY() == 1 then
        ui.SysMsg("[Cupole Potion] Cannot toggle in city")
        return
    end
    local player = GetMyPCObject()
    if player == nil then
        return
    end
    local cur = GetExProp(player, "cupole_auto_potion")
    local external_addon = ui.GetFrame("cupole_external_addon")
    local cupole_item = ui.GetFrame("cupole_item")

    SET_POTION_TOGGLE_STATE(external_addon, cur)
    SET_POTION_TOGGLE_STATE(cupole_item, cur)

    local state = (cur == 0) and "ON" or "OFF"
    pc.ReqExecuteTx_Item("CUPOLE_PORITON_AUTO_USE_TOGGLE", 0, 0)
    CHAT_SYSTEM("[Cupole Potion] Auto-use → " .. state)
end

function TOGGLE_CUPOLE_POTION_ON_INIT(addon, frame)
    addon:RegisterMsg("GAME_START_3SEC", "TCP_GAME_START")
    acutil.slashCommand("/tcp", TCP_SLASH)
end

function TCP_GAME_START()
    local frame = ui.GetFrame(addonName)
    if frame == nil then
        return
    end
    frame:StopUpdateScript("TCP_KEY_CHECK")
    frame:RunUpdateScript("TCP_KEY_CHECK", POLL_INTERVAL)
end

function TCP_KEY_CHECK(frame)
    local now = imcTime.GetAppTime()
    if keyboard.IsKeyDown("BACKSLASH") == 1 then
        if now - lastToggleTime > DEBOUNCE_SEC then
            lastToggleTime = now
            tcp_toggle()
        end
    end
    return 1
end

function TCP_SLASH(command)
    tcp_toggle()
end

function SET_POTION_TOGGLE_STATE(frame, value)
    local PotionToggle = GET_CHILD_RECURSIVELY(frame, "PotionToggle")
    if value == 0 then
        PotionToggle:SetImage("potionhudon")
    else
        PotionToggle:SetImage("potionhudoff")
    end
end