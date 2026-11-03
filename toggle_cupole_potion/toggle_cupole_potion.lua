-- v1.0.0 first release
-- v1.0.1 KR rev 409316 (2026-11-03): stop overriding SET_POTION_TOGGLE_STATE (its argument meaning flipped), send the wanted value
local addonName = "toggle_cupole_potion"
local acutil = require("acutil")

local lastToggleTime = 0
local DEBOUNCE_SEC = 0.5
local POLL_INTERVAL = 0.01
local version = "1.0.1"
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
    local state = (cur == 0) and "ON" or "OFF"
    if ON_CUPOLE_AUTO_POTION_STATE ~= nil then
        -- new client (KR rev 409316+): send the wanted value; the server confirmation
        -- (CUPOLE_AUTO_POTION_STATE) redraws the cupole window icons
        pc.ReqExecuteTx_Item("CUPOLE_PORITON_AUTO_USE_TOGGLE", 0, 1 - cur)
    else
        -- old client: draw from the pre-toggle value, then send (0, 0)
        if SET_POTION_TOGGLE_STATE ~= nil then
            SET_POTION_TOGGLE_STATE(ui.GetFrame("cupole_external_addon"), cur)
            SET_POTION_TOGGLE_STATE(ui.GetFrame("cupole_item"), cur)
        end
        pc.ReqExecuteTx_Item("CUPOLE_PORITON_AUTO_USE_TOGGLE", 0, 0)
    end
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

-- SET_POTION_TOGGLE_STATE is the client's own function: overriding it with the old meaning
-- (value = pre-toggle state) draws the icon backwards on clients since KR rev 409316