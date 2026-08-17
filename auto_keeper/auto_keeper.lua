-- v1.0.0 first release
--   네 가지 자동 관리 기능을 HUD 아이콘 하나씩으로 켜고 끈다.
--   기존에 쓰던 autostamina / no_potion / nexus auto_repair / mini_addons rp_charge 를
--   다시 구현하면서 각각의 결함을 고쳤다. 근거는 아래 주석과
--   `.claude/docs/changelog-2026-08-17-auto-keeper.md` 참고
--   four upkeep automations, each toggled by its own HUD icon. these are reimplementations of
--   autostamina / no_potion / nexus auto_repair / mini_addons rp_charge with their defects fixed
local addonName = "auto_keeper"
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
-- i18n — 클라 언어를 따른다 / follows the client language
-- ============================================================
local AK_LANG = {
    kr = {
        loaded = "[Auto Keeper] 로드 완료. /keeper 로 HUD 를 보이거나 숨깁니다.",
        hud_shown = "[Auto Keeper] HUD 를 표시합니다.",
        hud_hidden = "[Auto Keeper] HUD 를 숨깁니다. /keeper 로 다시 켭니다.",
        on = "켜짐",
        off = "꺼짐",
        f_stamina = "스태미나 알약 자동 섭취",
        f_potion = "물약 회복 버프 자동 해제",
        f_relic = "성물 마력 보완 충전",
        f_repair = "장비 자동 수리",
        tip_stamina = "{ol}스태미나가 %d%% 이하로 떨어지면 알약을 먹습니다{nl}도시와 이벤트 맵에서는 동작하지 않습니다",
        tip_potion = "{ol}체력이 %d%% 이상이 되면 물약 회복 버프를 해제합니다{nl}그 아래에서는 그대로 둡니다",
        tip_relic = "{ol}던전 입장창에서 성물 마력이 덜 찼으면 엑토나이트로 채웁니다{nl}도시와 성역은 게임 기본 자동충전이 이미 처리합니다",
        tip_repair = "{ol}내구도가 %d%% 미만인 장비를 수리 도구로 수리합니다",
        no_kit = "[Auto Keeper] 수리 도구가 없습니다.",
        no_fix = "[Auto Keeper] 수리 도구로 고칠 수 없는 장비입니다(Lv.550 초과). 자동 수리를 멈춥니다.",
        no_pill = "[Auto Keeper] 쓸 수 있는 스태미나 알약이 없습니다(없거나·잠김·쿨다운).",
        no_ecto = "[Auto Keeper] 엑토나이트가 없어 성물 충전을 건너뜁니다.",
        relic_done = "[Auto Keeper] 성물 마력 충전 완료.",
        relic_fail = "[Auto Keeper] 성물 마력을 다 채우지 못했습니다.",
        potion_removed = "[Auto Keeper] 물약 회복 버프를 해제했습니다.",
        kit_bought = "[Auto Keeper] 수리 도구 %d개를 구매했습니다.",
        buy_on = "[Auto Keeper] 수리 도구 자동 구매 : 켜짐",
        buy_off = "[Auto Keeper] 수리 도구 자동 구매 : 꺼짐",
        cfg_autobuy = "수리 도구 자동 구매",
        cfg_autobuy_tip = "{ol}내구도가 닳았을 때 필요한 수량만큼 확인 없이 바로 구매합니다",
        cfg_qty = "1회 최대 구매 수량",
        tip_rclick = "{ol}{#FFDD55}우클릭 : 설정",
    },
    jp = {
        loaded = "[Auto Keeper] ロード完了。/keeper で HUD の表示を切り替えます。",
        hud_shown = "[Auto Keeper] HUD を表示します。",
        hud_hidden = "[Auto Keeper] HUD を隠します。/keeper で再表示します。",
        on = "オン",
        off = "オフ",
        f_stamina = "スタミナ丸薬の自動使用",
        f_potion = "回復ポーションバフの自動解除",
        f_relic = "レリック魔力の補完チャージ",
        f_repair = "装備の自動修理",
        tip_stamina = "{ol}スタミナが %d%% 以下になると丸薬を使います{nl}街とイベントマップでは動作しません",
        tip_potion = "{ol}HP が %d%% 以上になるとポーションの回復バフを解除します{nl}それ未満ではそのままにします",
        tip_relic = "{ol}ダンジョン入場画面でレリック魔力が満タンでなければエクトナイトで補充します{nl}街と聖域はゲーム標準の自動チャージが処理します",
        tip_repair = "{ol}耐久度が %d%% 未満の装備を修理道具で修理します",
        no_kit = "[Auto Keeper] 修理道具がありません。",
        no_fix = "[Auto Keeper] 修理道具では直せない装備です(Lv.550 超)。自動修理を止めます。",
        no_pill = "[Auto Keeper] 使用できるスタミナ丸薬がありません(未所持・ロック・クールダウン)。",
        no_ecto = "[Auto Keeper] エクトナイトがないためチャージをスキップします。",
        relic_done = "[Auto Keeper] レリック魔力チャージ完了。",
        relic_fail = "[Auto Keeper] レリック魔力を満たせませんでした。",
        potion_removed = "[Auto Keeper] 回復ポーションバフを解除しました。",
        kit_bought = "[Auto Keeper] 修理道具を %d 個購入しました。",
        buy_on = "[Auto Keeper] 修理道具の自動購入 : オン",
        buy_off = "[Auto Keeper] 修理道具の自動購入 : オフ",
        cfg_autobuy = "修理道具の自動購入",
        cfg_autobuy_tip = "{ol}耐久度が減った時に必要な数だけ確認なしで購入します",
        cfg_qty = "1回の最大購入数",
        tip_rclick = "{ol}{#FFDD55}右クリック : 設定",
    },
    en = {
        loaded = "[Auto Keeper] Loaded. Use /keeper to show or hide the HUD.",
        hud_shown = "[Auto Keeper] HUD shown.",
        hud_hidden = "[Auto Keeper] HUD hidden. Use /keeper to bring it back.",
        on = "on",
        off = "off",
        f_stamina = "Auto stamina pill",
        f_potion = "Auto remove potion heal buff",
        f_relic = "Relic power top-up",
        f_repair = "Auto repair gear",
        tip_stamina = "{ol}Eats a pill when stamina drops to %d%% or less{nl}Does nothing in cities and event maps",
        tip_potion = "{ol}Removes the potion heal buff once HP reaches %d%%{nl}Below that it is left alone",
        tip_relic = "{ol}Tops relic power up with Ectonite at the dungeon entry window{nl}Cities and the Sanctuary are already covered by the built-in auto charge",
        tip_repair = "{ol}Repairs gear below %d%% durability with repair kits",
        no_kit = "[Auto Keeper] No repair kit.",
        no_fix = "[Auto Keeper] This gear is above Lv.550 and the kit cannot repair it. Stopping.",
        no_pill = "[Auto Keeper] No usable stamina pill (missing, locked or on cooldown).",
        no_ecto = "[Auto Keeper] No Ectonite, skipping the relic charge.",
        relic_done = "[Auto Keeper] Relic power charged.",
        relic_fail = "[Auto Keeper] Could not fill the relic power.",
        potion_removed = "[Auto Keeper] Removed the potion heal buff.",
        kit_bought = "[Auto Keeper] Bought %d repair kits.",
        buy_on = "[Auto Keeper] Repair kit auto-buy: on",
        buy_off = "[Auto Keeper] Repair kit auto-buy: off",
        cfg_autobuy = "Auto-buy repair kits",
        cfg_autobuy_tip = "{ol}Buys exactly what a repair needs, without a confirmation",
        cfg_qty = "Max per purchase",
        tip_rclick = "{ol}{#FFDD55}Right click: settings",
    }
}

local function AK_t(key)
    local country = option.GetCurrentCountry()
    local pack = AK_LANG.en
    if country == "kr" then
        pack = AK_LANG.kr
    elseif country == "Japanese" then
        pack = AK_LANG.jp
    end
    return pack[key] or AK_LANG.en[key] or key
end

-- ============================================================
-- Tunables
-- ============================================================
-- 스태미나: 절대값이 아니라 비율로 판단한다. 최대 스태미나는 캐릭터·장비마다 달라서
-- 원본 autostamina 의 고정값 5000 은 누군가에겐 20%, 누군가에겐 50% 였다
-- stamina is judged as a ratio: max stamina differs per character, so the original addon's
-- fixed 5000 meant 20% for one character and 50% for another
local AK_STA_RATIO = 0.20
-- 물약 회복 버프는 HP 가 이 값 **이상**일 때 해제한다(원본 no_potion 과 같다).
-- 아래일 때는 그대로 둬서 물약이 제 일을 하게 두고, 기준선을 넘는 순간 끊는다.
-- ⚠️ 이 조건이 원래 맞았는데, 여기에 "바카리네 5셋일 때만"을 덧붙였던 것이 진짜 고장이었다.
-- 레이드에서 장비가 자동 탈착되면 그 판정이 조용히 거짓이 되어 기능 전체가 죽었다
-- removed when HP is at or above this, exactly like the original no_potion: below the line the
-- potion is left to do its job, and the moment HP crosses back over it the buff is cut.
-- ⚠️ this condition was right all along - the breakage was the "only with the 5-piece Vakarine
-- set" gate stacked on top of it, which went quietly false whenever raid gear was swapped
local AK_HP_RATIO = 0.40
-- 내구도 기준은 게임 자신의 경고 기준과 맞춘다.
-- ⚠️ 클라의 `IS_DUR_UNDER_10PER` 는 **이름과 달리 `Dur / MaxDur < 0.3` 을 본다**
-- (durnotify.lua:110). 게임이 띄우는 경고도 `DurUnder30` 이고, nexus auto_repair 의 발동
-- 조건도 그 함수다. 처음에 이름만 보고 0.10 으로 잡은 것이 오독이었다 —
-- 게임은 30% 에서 "수리하라"고 말하는데 우리는 10% 까지 아무것도 안 했다
-- ⚠️ the client's IS_DUR_UNDER_10PER tests < 0.3 despite its name, the warning it drives is
-- DurUnder30, and nexus auto_repair triggers off that same function. reading the name instead of
-- the body is what put this at 0.10, i.e. silent through the whole span where the game warns
local AK_DUR_RATIO = 0.30          -- 이 미만이면 수리 / repair below this
local AK_USE_GAP = 1.0             -- 같은 기능의 연속 사용 최소 간격(초) / min gap between uses
-- 알약은 먹어도 스태미나가 곧바로 오르지 않는다. 1초 간격이면 효과가 반영되기 전에
-- 다음 알약을 먹어 과소비할 수 있어 조금 더 길게 잡는다
-- a pill's effect does not register instantly; a 1s gap could eat the next one before the first
-- lands, so stamina gets a longer gap of its own
local AK_STA_GAP = 3.0
-- 쓸 수 있는 알약이 하나도 없을 때 21종을 매 STA_UPDATE 마다 다시 훑지 않도록 쉬는 시간
-- back-off so an empty inventory does not rescan all 21 names on every STA_UPDATE
local AK_NOPILL_RETRY = 5.0

-- 성물 충전에 쓰는 소모품과 트랜잭션 이름. 게임의 성물 관리창과 같은 것을 쓴다
-- (relicmanager.lua:474-484)
local AK_ECTONITE = {"misc_Ectonite", "misc_Ectonite_Care"}
local AK_RELIC_TX = "RELIC_CHARGE_RP"

-- 수리 도구: 아우스테야 증서 / repair kit: Austeja certificate
local AK_REPAIR_ITEM_CLSID = 11201388
local AK_REPAIR_SHOP_ITEM = "AustejaCertificate_14"    -- ItemTradeShop 항목 / shop entry
local AK_REPAIR_SHOP_TYPE = "AustejaCertificate"
local AK_REPAIR_SHOP_TX = "Certificate_SHOP"
local AK_BUY_GAP = 30.0                                -- 자동 구매 최소 간격(초) / min gap between buys
-- 증서 1장이 올려주는 내구도(내부 단위). item_EP13.ies 11201388 의 NumberArg1 = 1000 이고,
-- 아이템 설명은 "내구도를 +10 회복"이다 = 표시값의 100배가 내부값이다(MaxDur 5000 = 표시 50).
-- 🔑 장비 하나가 아니라 **착용 장비 전체**를 이만큼씩 올린다. NumberArg2 = 550 은 대상 레벨 상한
-- one kit's durability gain in internal units: NumberArg1 = 1000 and the item text says "+10",
-- so internal = displayed x100. it lifts every equipped item, not one. NumberArg2 = 550 is the
-- level cap of what it can repair
local AK_KIT_HEAL = 1000

-- 해제 대상 물약 버프. buff.ies 에서 이름이 Drug_...HealHP... 인 것 전부다.
-- 원본 no_potion 은 4139/4724 둘만 봤는데, 물약 종류에 따라 다른 ID 가 붙는다.
-- ⚠️ SP 회복(4010/4138/4146/4634)은 뺐다. HP 를 낮게 유지하는 것과 상관이 없다.
-- ⚠️ 챌린지 반복 회복 물약(4602/4631)도 뺐다 — 회복 물약 버프이긴 하나 챌린지 전용 지급
--    버프라 지우는 게 맞는지 확실하지 않다. 필요하면 여기 추가하면 된다
-- every Drug_...HealHP... buff in buff.ies. the original watched only 4139/4724, but which id
-- you get depends on the potion. SP-only heals are excluded (they do not raise HP), and so are
-- the challenge-mode repeat heal potions (unclear whether removing those is wanted)
local AK_POTION_BUFFS = {
    [4011] = true,      -- Drug_HealHP_Dot
    [4019] = true,      -- Drug_HealHPSP_Dot
    [4139] = true,      -- Drug_Heal100HP_Dot
    [4147] = true,      -- Drug_HealHP
    [4148] = true,      -- Drug_DotHealHP
    [4635] = true,      -- Drug_HealHP_MHP
    [4724] = true       -- Drug_Heal100HP_Dot2
}

-- 스태미나 알약 전체. 약한 것부터 써서 낭비를 줄인다.
-- ⚠️ 원본 autostamina 는 Drug_Alche_STA13 이 빠져 있었다(12 다음이 14). item.ies 에 실재한다
-- ⚠️ the original list skipped Drug_Alche_STA13; it does exist in item.ies
local AK_STA_PILLS = {
    "Drug_STA1", "Drug_STA2", "Drug_STA3",
    "Drug_STA1_Q", "Drug_STA2_Q", "Drug_STA3_Q",
    "Drug_Alche_STA",
    "Drug_Alche_STA2", "Drug_Alche_STA3", "Drug_Alche_STA4", "Drug_Alche_STA5",
    "Drug_Alche_STA6", "Drug_Alche_STA7", "Drug_Alche_STA8", "Drug_Alche_STA9",
    "Drug_Alche_STA10", "Drug_Alche_STA11", "Drug_Alche_STA12", "Drug_Alche_STA13",
    "Drug_Alche_STA14", "Drug_Alche_STA15"
}

-- ============================================================
-- HUD 레이아웃 / HUD layout
-- ============================================================
local AK_HUD_FRAME = addonNameLower .. "_hud"
local AK_UI_SKIN = "bg2"
local AK_UI_ALPHA = 110
local AK_ICON = 28
local AK_ICON_GAP = 8
local AK_HUD_PAD = 12
-- 높이 40 은 cupole_manager / hideplayer 의 HUD 바와 같은 값이다(테마 §1).
-- 나란히 놓았을 때 어긋나 보이면 안 되므로 맞춘다
-- 40 is the same bar height cupole_manager and hideplayer use, so the bars line up side by side
local AK_HUD_H = 40
-- 왼쪽 애드온 이름. cupole 과 같은 2줄 {s10} 캡션 / two-line {s10} caption like cupole's
local AK_LABEL_X = 8
local AK_LABEL_W = 52
local AK_ICON_X = AK_LABEL_X + AK_LABEL_W + 8
local AK_HUD_W = AK_ICON_X + AK_ICON * 4 + AK_ICON_GAP * 3 + AK_HUD_PAD
local AK_HUD_POS_VER = 2       -- 레이아웃이 바뀌면 올려서 기본 위치를 다시 잡는다

-- 켜짐 = 원래 색, 꺼짐 = 어둡게. picture 에 SetColorTone 을 쓰는 선례는
-- adventure_book_achieve_ui.lua:407 (icon_pic 은 xml 에서 <picture>)
-- on = original colour, off = darkened. SetColorTone on a picture is precedented there
-- ⚠️ 켜짐을 FFFFFFFF 로 두면 마우스를 올렸을 때 더 밝게 할 방법이 없다(SetColorTone 은
-- 곱연산이라 원색보다 밝아지지 않는다). 그래서 평상시를 한 단계 낮추고 오버에서 원색으로 간다
-- ⚠️ SetColorTone multiplies, so nothing can be brighter than FFFFFFFF - the resting tone is
-- stepped down one notch so that hovering can return it to full
local AK_TONE_ON = "FFDCDCDC"
local AK_TONE_ON_HOVER = "FFFFFFFF"
local AK_TONE_OFF = "FF383838"
local AK_TONE_OFF_HOVER = "FF6E6E6E"
-- 상태색이 따로 없는 버튼(닫기 X, 토글 아이콘 등)의 기본 짝
-- the default pair for controls without an on/off state of their own
local AK_TONE_IDLE = "FFD2D2D2"
local AK_TONE_HOVER = "FFFFFFFF"

-- 기능 정의. 순서가 곧 HUD 아이콘 순서다 / definition order is the icon order
local AK_FEATURES = {
    {key = "stamina", icon = "item_STA_pill_1", label = "f_stamina", tip = "tip_stamina",
     tip_arg = AK_STA_RATIO},
    -- ⚠️ buff.ies 의 Icon 값(4139 = "cross")을 그대로 쓰면 안 된다. 클라는 버프 아이콘에
    -- 'icon_' 을 붙여서 쓴다(GET_BUFF_ICON_NAME: 'icon_' .. buffCls.Icon). 그래서 "cross" 는
    -- 빈칸으로 떴다. 여기서는 뜻이 더 분명한 HP 포션 아이템 아이콘을 쓴다
    -- ⚠️ a buff's Icon value is not an image name on its own: the client prefixes it with
    -- 'icon_'. "cross" rendered blank. this uses the HP potion item icon instead, which also
    -- reads more clearly as "potion"
    {key = "potion", icon = "item_HP_oil_2", label = "f_potion", tip = "tip_potion",
     tip_arg = AK_HP_RATIO},
    {key = "relic", icon = "icon_item_ectonite", label = "f_relic", tip = "tip_relic"},
    {key = "repair", icon = "icon_item_repairkit_550", label = "f_repair", tip = "tip_repair",
     tip_arg = AK_DUR_RATIO}
}

-- ============================================================
-- Infrastructure: JSON I/O (atomic tmp+rename)
-- ============================================================
local function AK_save_json(path, tbl)
    local ok, str = pcall(json.encode, tbl)
    if not ok then
        return false
    end
    local tmp = path .. ".tmp"
    local file = io.open(tmp, "w")
    if not file then
        return false
    end
    local ok_w = file:write(str)
    file:close()
    if ok_w then
        os.remove(path)
        os.rename(tmp, path)
        return true
    end
    return false
end

local function AK_load_json(path)
    local file = io.open(path, "r")
    if not file then
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
    local ok, result = pcall(json.decode, content)
    if ok then
        return result
    end
    return nil
end

local function AK_create_folder(path)
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

-- ============================================================
-- Settings — 계정 단위 / account wide
-- ============================================================
local function AK_default_hud_pos()
    local sw = ui.GetClientInitialWidth()
    local sh = ui.GetClientInitialHeight()
    g.settings.hud_x = sw - AK_HUD_W - 4
    g.settings.hud_y = math.floor(sh / 2) - math.floor(AK_HUD_H / 2) - 40
end

function AK_save_settings()
    if not g.settings or not g.settings_path then
        return
    end
    AK_save_json(g.settings_path, g.settings)
end

function AK_load_settings()
    g.settings_path = string.format("../addons/%s/%s/%s.json", addonNameLower, g.active_id, addonNameLower)
    local s = AK_load_json(g.settings_path)
    if not s then
        s = {}
    end
    -- 기본은 전부 꺼짐. 자동으로 아이템을 쓰는 기능이라 사용자가 켜는 게 맞다
    -- everything defaults to off: these spend items, so the user opts in
    for _, f in ipairs(AK_FEATURES) do
        if s[f.key] ~= 1 then
            s[f.key] = 0
        end
    end
    if s.hud_open ~= 0 then
        s.hud_open = 1
    end
    -- 자동 구매는 재화를 쓰므로 기본 꺼짐 / auto-buy spends currency, so it defaults to off
    if s.repair_autobuy ~= 1 then
        s.repair_autobuy = 0
    end
    if type(s.repair_buy_qty) ~= "number" or s.repair_buy_qty < 1 or s.repair_buy_qty > 999 then
        s.repair_buy_qty = 50
    end
    g.settings = s
    if s.hud_ver ~= AK_HUD_POS_VER or type(s.hud_x) ~= "number" or type(s.hud_y) ~= "number" then
        AK_default_hud_pos()
        g.settings.hud_ver = AK_HUD_POS_VER
    end
    AK_save_settings()
end

local function AK_on(key)
    return g.settings ~= nil and g.settings[key] == 1
end

-- ============================================================
-- 마우스 오버 밝기 / hover highlight
--   클라 기본 창은 xml 속성으로 처리한다: MouseOnAnim="btn_mouseover" MouseOffAnim="btn_mouseoff"
--   (accountwarehouse.xml:19 등). 런타임에 만든 컨트롤에는 그 속성을 줄 수 없다 —
--   `SetAnimation` 의 Lua 선례는 ingamealert.lua:38 의 openAnim/closeAnim 둘뿐이라
--   "MouseOnAnim" 키가 통한다는 근거가 없다.
--   대신 MOUSEON/MOUSEOFF 이벤트에 SetColorTone 을 건다 (picture 에 MOUSEON 을 거는 선례:
--   job_select_guide.lua:98 / button 에 SetColorTone 을 쓰는 선례: tpitem.lua:3690)
--   the client does this with xml attributes we cannot set on runtime-made controls, so the
--   MOUSEON/MOUSEOFF events carry the tone change instead
-- ============================================================
function AK_HOVER_ON(frame, ctrl)
    if ctrl == nil then
        return
    end
    local tone = ctrl:GetUserValue("AK_TONE_HOVER")
    -- 값이 없는 UserValue 는 "None" 을 돌려준다 / an unset user value reads back as "None"
    if tone ~= nil and tone ~= "" and tone ~= "None" then
        ctrl:SetColorTone(tone)
    end
end

function AK_HOVER_OFF(frame, ctrl)
    if ctrl == nil then
        return
    end
    local tone = ctrl:GetUserValue("AK_TONE_IDLE")
    if tone ~= nil and tone ~= "" and tone ~= "None" then
        ctrl:SetColorTone(tone)
    end
end

-- 평상시/오버 색을 컨트롤에 붙여 둔다. 상태색이 있는 아이콘은 상태가 바뀔 때 다시 부르면 된다
-- stores the pair on the control; call again when a stateful icon changes state
local function AK_hover(ctrl, idle, hover)
    if ctrl == nil then
        return
    end
    idle = idle or AK_TONE_IDLE
    hover = hover or AK_TONE_HOVER
    ctrl:SetUserValue("AK_TONE_IDLE", idle)
    ctrl:SetUserValue("AK_TONE_HOVER", hover)
    ctrl:SetColorTone(idle)
    ctrl:SetEventScript(ui.MOUSEON, "AK_HOVER_ON")
    ctrl:SetEventScript(ui.MOUSEOFF, "AK_HOVER_OFF")
end

-- ============================================================
-- 공통 가드 / shared guards
--   원본 세 애드온에 흩어져 있거나 아예 빠져 있던 검사를 한 곳으로 모았다.
--   클라 자신이 item.UseByGUID 앞에서 거는 것과 같은 순서다(inventory.lua:2178-2195)
--   the checks the three originals scattered or skipped, in the same order the client itself
--   uses before item.UseByGUID
-- ============================================================
local function AK_my_stat()
    local handle = session.GetMyHandle()
    if not handle then
        return nil
    end
    local ok, stat = pcall(info.GetStat, handle)
    if not ok then
        return nil
    end
    return stat
end

-- ⚠️ item.GetCoolDown 검사가 핵심이다. 원본 autostamina 와 nexus auto_repair 는 이게 없어서
-- 쿨다운이 도는 내내 매 메시지마다 사용 요청을 다시 날렸다(알약·증서 낭비의 원인)
-- ⚠️ the cooldown check is the important one: without it the originals re-sent a use request on
-- every message while the cooldown was still running, which is what wasted pills and kits
local function AK_item_usable(inv_item)
    if not inv_item then
        return false
    end
    if inv_item.isLockState == true then
        return false
    end
    if inv_item.count ~= nil and inv_item.count <= 0 then
        return false
    end
    local stat = AK_my_stat()
    if not stat or stat.HP <= 0 then
        return false
    end
    local ok, cool = pcall(item.GetCoolDown, inv_item.type)
    if not ok or (cool ~= nil and cool ~= 0) then
        return false
    end
    return true
end

-- 같은 기능이 연달아 터지는 것을 한 번 더 막는다. 쿨다운이 아직 안 올라온 찰나에도
-- 메시지가 여러 번 오기 때문에 시간 간격 가드를 겹쳐 둔다
-- a second layer over the cooldown: messages can arrive faster than the cooldown is reported
local function AK_throttled(key, gap)
    g.last_use = g.last_use or {}
    local now = imcTime.GetAppTime()
    local last = g.last_use[key]
    if last ~= nil and now - last < (gap or AK_USE_GAP) then
        return true
    end
    g.last_use[key] = now
    return false
end

-- 도시와 이벤트 맵에서는 스태미나 알약을 쓰지 않는다.
-- ⚠️ 점프 이벤트 맵(무지개 다리, Event_2105_JUMP, ID 11240)은 MapType 이 "City" 이면서
-- Keyword 가 "Event;DisableWarp" 다. 둘 중 하나만 걸어도 잡히지만 이벤트 맵이 전부
-- City 라는 보장이 없어 두 조건을 함께 본다. Keyword 읽는 방식은 relicmanager.lua:495 와 같다
-- ⚠️ the jump event map is both MapType "City" and Keyword "Event;DisableWarp"; either test
-- would catch it, but not every event map is guaranteed to be a City, so both are checked
-- 결과는 맵 이름으로 캐시한다. STA_UPDATE 마다 불리는 자리라 매번 GetClass 를 하면 낭비다
-- memoised by zone name: this runs on every STA_UPDATE, so a GetClass per call would be waste
local function AK_map_blocked()
    local pc = GetMyPCObject()
    if not pc then
        return true
    end
    local zone = GetZoneName(pc)
    if g.map_zone == zone then
        return g.map_blocked
    end
    local blocked = false
    local ok, map_cls = pcall(GetClass, "Map", zone)
    if ok and map_cls then
        if TryGetProp(map_cls, "MapType", "None") == "City" then
            blocked = true
        else
            local keyword = TryGetProp(map_cls, "Keyword", "None")
            if keyword ~= nil and keyword ~= "None" then
                local cut = SCR_STRING_CUT(keyword, ";")
                for i = 1, #cut do
                    if cut[i] == "Event" then
                        blocked = true
                        break
                    end
                end
            end
        end
    end
    g.map_zone = zone
    g.map_blocked = blocked
    return blocked
end

-- ============================================================
-- 1. 스태미나 알약 자동 섭취 / auto stamina pill
-- ============================================================
-- ⚠️ item.UseByGUID 는 성공 여부를 돌려주지 않는다(클라 전체에 반환값을 쓰는 선례가 0건).
-- 서버가 거절해도 우리는 알 수 없으므로, "실패했으면 다시 시도한다"가 아니라
-- "조건이 남아 있으면 계속 다시 판정한다"로 만들어야 한다. 그래서 이 함수는
-- 메시지 두 종류 + 안전 타이머, 세 경로에서 불린다
-- ⚠️ item.UseByGUID reports nothing back (no call site in the whole client reads its result), so
-- a rejected use is invisible to us. the design is therefore "keep re-evaluating while the
-- condition holds", driven from two messages plus a safety timer
function AK_sta_try()
    if not AK_on("stamina") or not g.ready then
        return
    end
    if AK_map_blocked() then
        return
    end
    pcall(session.UpdateMaxStamina)
    local stat = AK_my_stat()
    -- 원본은 UpdateMaxStamina 를 부르고도 MaxStamina 를 안 썼다(죽은 호출)
    -- the original called UpdateMaxStamina and then never read MaxStamina
    if not stat or not stat.MaxStamina or stat.MaxStamina <= 0 then
        return
    end
    if stat.Stamina / stat.MaxStamina > AK_STA_RATIO then
        -- 기준선 위로 올라오면 "알약 없음" 알림 상태를 푼다. 다음에 또 바닥나면 다시 알린다
        -- back above the line: clear the "no pill" notice so the next episode reports again
        g.sta_warned = false
        return
    end

    -- 쓸 수 있는 알약이 없다고 방금 확인했으면 잠시 쉰다. STA_UPDATE 는 자주 오는데
    -- 인벤에 알약이 없으면 매번 21종을 헛되이 훑게 된다
    -- if the last scan came up empty, wait a moment: STA_UPDATE is frequent and an empty
    -- inventory would mean 21 pointless lookups every time
    local now = imcTime.GetAppTime()
    if g.sta_nopill_at ~= nil and now - g.sta_nopill_at < AK_NOPILL_RETRY then
        return
    end

    for _, pill_name in ipairs(AK_STA_PILLS) do
        local pill = session.GetInvItemByName(pill_name)
        if AK_item_usable(pill) then
            g.sta_nopill_at = nil
            g.sta_warned = false
            -- 여기서 끝내지 않는다. 다음 STA_UPDATE 에서 다시 판단하므로, 한 알로 기준선을
            -- 못 넘기면 간격을 두고 계속 먹는다. 원본과 다른 건 "몇 번 먹느냐"가 아니라
            -- "얼마나 빨리 먹느냐"다 -- 원본은 쿨다운 중에도 매 메시지마다 요청을 날렸다
            -- this is not one-shot: the next STA_UPDATE re-evaluates, so it keeps eating until
            -- the ratio clears. the difference from the original is the rate, not the count
            if AK_throttled("stamina", AK_STA_GAP) then
                return
            end
            item.UseByGUID(pill:GetIESID())
            return
        end
    end

    -- 하나도 못 찾았다: 없거나, 전부 잠겼거나, 전부 쿨다운이거나, 죽어 있다.
    -- 조용히 아무것도 안 하면 사용자는 왜 안 먹는지 알 수 없으므로 한 번은 알린다
    -- nothing usable: missing, locked, on cooldown, or dead. say so once rather than silently
    -- doing nothing, so the user knows why no pill is being eaten
    g.sta_nopill_at = now
    if not g.sta_warned then
        g.sta_warned = true
        CHAT_SYSTEM(AK_t("no_pill"))
    end
end

-- 스태미나 갱신은 STA_UPDATE 와 PC_PROPERTY_UPDATE 두 곳에서 온다. 클라 자신이 두 메시지를
-- 같은 핸들러에 물려 쓴다(headsupdisplay.lua:11-12) — 우리도 둘 다 받는다
-- the client wires both of these to the same stamina handler, so we take both
function AK_STA_UPDATE()
    AK_sta_try()
end

-- 안전 타이머. 메시지에만 기대면 막다른 길이 생긴다:
-- 사용 요청이 서버에서 거절되면 스태미나 값이 안 바뀌고, 값이 안 바뀌면 메시지도 안 온다.
-- 가만히 서 있는 동안에는 다시 시도할 계기가 영영 없을 수 있다.
-- 2초마다 스스로 판정하면 그 구멍이 사라진다
-- safety tick: relying on messages alone dead-ends when a use is rejected - stamina does not
-- change, so no message arrives, so nothing retries while you stand still
function AK_sta_tick(frame)
    if not AK_on("stamina") then
        frame:StopUpdateScript("AK_sta_tick")
        return 0
    end
    AK_sta_try()
    return 1
end

function AK_sta_watch_start()
    if not g.frame then
        return
    end
    g.frame:StopUpdateScript("AK_sta_tick")
    if AK_on("stamina") then
        g.frame:RunUpdateScript("AK_sta_tick", 2.0)
    end
end

-- ============================================================
-- 2. 물약 회복 버프 자동 해제 / auto remove the potion heal buff
-- ============================================================
-- ⚠️ 원본 no_potion 은 아이콘이 없거나 clsid 가 0 인 칸에서 break 로 순회를 끊었다.
-- 빈 칸이 중간에 하나라도 있으면 그 뒤 버프를 영영 못 찾는다. 여기서는 건너뛴다
-- ⚠️ the original broke out of the loop on an empty slot, so anything after a hole was never
-- seen. this skips instead
local function AK_collect_buffs(slot_ctrl, out)
    if slot_ctrl == nil then
        return
    end
    for i = 0, slot_ctrl:GetChildCount() - 1 do
        local child = slot_ctrl:GetChildByIndex(i)
        if child ~= nil then
            local icon = child:GetIcon()
            if icon ~= nil then
                local info_obj = icon:GetInfo()
                if info_obj ~= nil and AK_POTION_BUFFS[info_obj.type] then
                    table.insert(out, info_obj.type)
                end
            end
        end
    end
end

local function AK_find_potion_buffs()
    local found = {}
    local buff_frame = ui.GetFrame("buff")
    if buff_frame == nil then
        return found
    end
    for _, name in ipairs({"buffslot", "buffcountslot", "buffcountslot_sub"}) do
        AK_collect_buffs(GET_CHILD_RECURSIVELY(buff_frame, name), found)
    end
    return found
end

-- 기준선 위에 있는가. 두 경로(버프 메시지 / 1초 타이머)가 같은 판정을 쓴다
-- one shared verdict for both paths (the buff message and the 1s timer)
local function AK_potion_hp_ok()
    local stat = AK_my_stat()
    if not stat or not stat.maxHP or stat.maxHP == 0 then
        return false
    end
    return stat.HP / stat.maxHP >= AK_HP_RATIO
end

-- 해제하고 알린다. 도트힐은 몇 초마다 갱신되므로 알림은 묶어서 드물게 낸다
-- remove and report; the HoT refreshes every few seconds, so the notice is throttled
local function AK_potion_remove(frame, buff_ids)
    if #buff_ids == 0 or not AK_potion_hp_ok() then
        return
    end
    for _, buff_id in ipairs(buff_ids) do
        REMOVE_BUF(frame, nil, "AUTO_KEEPER", buff_id)
    end
    if not AK_throttled("potion_msg", 10.0) then
        CHAT_SYSTEM(AK_t("potion_removed"))
    end
end

-- 버프가 붙는(그리고 갱신되는) 순간을 받는 주 경로 / the main path: the buff arriving or refreshing
function AK_BUFF_MSG(frame, msg, argStr, argNum)
    if not AK_on("potion") or not g.ready then
        return
    end
    if not AK_POTION_BUFFS[argNum] then
        return
    end
    AK_potion_remove(frame, {argNum})
end

-- 🔑 실제로 일을 하는 건 대개 이쪽이다. 물약은 HP 가 낮을 때 마시므로 버프가 붙는 순간에는
-- 기준선 아래라 해제되지 않고, 그 물약이 HP 를 끌어올려 기준선을 넘는 순간에 해제된다.
-- 그 "넘는 순간"에는 새 버프 메시지가 오지 않을 수 있으므로 타이머가 필요하다.
-- ⚠️ 원본은 이 역할을 STAT_UPDATE 로 했는데, 전투 중에는 초당 수십 번 와서 그때마다
-- 버프 슬롯 전체를 훑었다. 스태미나와 같은 방식으로 우리 프레임 타이머에 맡긴다
-- 🔑 this is usually the path that does the work: you drink while low, so the buff is below the
-- line when it arrives and survives; it is the potion healing you back over the line that makes
-- it removable, and no new buff message need arrive at that moment - hence the timer.
-- ⚠️ the original hung this off STAT_UPDATE, which fires dozens of times a second in combat and
-- rescanned every buff slot each time. this uses our own frame timer, like the stamina watcher
function AK_potion_tick(frame)
    if not AK_on("potion") then
        frame:StopUpdateScript("AK_potion_tick")
        return 0
    end
    if not g.ready then
        return 1
    end
    AK_potion_remove(g.frame, AK_find_potion_buffs())
    return 1
end

function AK_potion_watch_start()
    if not g.frame then
        return
    end
    g.frame:StopUpdateScript("AK_potion_tick")
    if AK_on("potion") then
        g.frame:RunUpdateScript("AK_potion_tick", 1.0)
    end
end

-- ============================================================
-- 3. 성물 마력 보완 충전 / relic power top-up
--   게임 기본 옵션("성물(마력) 자동충전")을 대체하지 않는다. 그것이 놓치는 경우,
--   즉 인던 입장 직전에 마력이 덜 찬 상태를 메꾸는 보완 장치다
--   this does not replace the built-in auto charge; it fills the gap the built-in one leaves
--   right before entering a dungeon
-- ============================================================
local function AK_relic_rp()
    local pc = GetMyPCObject()
    if not pc then
        return nil, nil
    end
    local ok, cur, max = pcall(shared_item_relic.get_rp, pc)
    if not ok then
        return nil, nil
    end
    return cur, max
end

function AK_relic_verify(frame)
    local cur, max = AK_relic_rp()
    if cur == nil then
        return 0
    end
    if cur >= max then
        CHAT_SYSTEM(AK_t("relic_done"))
    else
        CHAT_SYSTEM(AK_t("relic_fail"))
    end
    -- ⚠️ 원본(mini_addons)의 확인 함수는 반환값이 없어서 타이머가 멈춘다는 보장이 없었다.
    -- 명시적으로 0 을 돌려 끝낸다 / the original returned nothing; stop explicitly
    frame:StopUpdateScript("AK_relic_verify")
    return 0
end

function AK_relic_check(frame)
    if not AK_on("relic") or not g.ready then
        return 0
    end
    local indun = ui.GetFrame("indunenter")
    if not indun or indun:IsVisible() == 0 then
        return 1
    end
    local cur, max = AK_relic_rp()
    if cur == nil or cur >= max then
        return 1
    end

    session.ResetItemList()
    local added = 0
    for _, name in ipairs(AK_ECTONITE) do
        local inv_item = session.GetInvItemByName(name)
        if inv_item and inv_item.isLockState ~= true and inv_item.count > 0 then
            session.AddItemID(inv_item:GetIESID(), inv_item.count)
            added = added + inv_item.count
        end
    end
    if added == 0 then
        CHAT_SYSTEM(AK_t("no_ecto"))
        return 0
    end

    -- 게임의 자동 충전 경로(RELIC_AUTO_CHARGE)와 똑같이 트랜잭션 하나만 부른다.
    -- ⚠️ CloneTempObj('RELIC_RP_TEMPOBJ', ...) 는 수동 창(_RELICMANAGER_CHARGE_EXEC)에만 있다.
    -- 그건 창의 전/후 표시용이라 자동 경로에는 없다 — 여기서도 부르지 않는다.
    -- 엑토나이트를 보유 전량 넘기는 것도 게임 자동 경로와 같다(수동 창만 입력 수량을 쓴다)
    -- ⚠️ CloneTempObj belongs to the manual window only, for its before/after display; the
    -- game's own auto path does not call it, and neither do we. passing the whole Ectonite
    -- stack also matches the auto path - only the manual window uses a typed quantity
    item.DialogTransaction(AK_RELIC_TX, session.GetItemIDList())

    frame:StopUpdateScript("AK_relic_check")
    frame:RunUpdateScript("AK_relic_verify", 1.0)
    return 0
end

-- 감시 타이머는 우리 프레임에서 돌린다.
-- ⚠️ 원본은 인게임샵 버튼 프레임("openingameshopbtn")을 빌려 썼다. 그 프레임이 없거나
-- 숨겨지면 그대로 멈춘다 / the original borrowed the in-game shop button frame for its timer
function AK_relic_watch_start()
    if not g.frame then
        return
    end
    g.frame:StopUpdateScript("AK_relic_check")
    g.frame:StopUpdateScript("AK_relic_verify")
    if AK_on("relic") then
        g.frame:RunUpdateScript("AK_relic_check", 0.5)
    end
end

-- ============================================================
-- 4. 장비 자동 수리 / auto repair
--   ⚠️ nexus 판은 게임의 내구도 알림창(durnotify)을 훅해서 Resize(0,0) 으로 지워버린다.
--   여기서는 durnotify 가 받는 것과 같은 원본 메시지를 직접 구독하므로 게임 UI 를 건드리지
--   않는다(durnotify.lua:4-7 의 UPDATE_ITEM_REPAIR / ITEM_PROP_UPDATE / EQUIP_ITEM_LIST_GET)
--   the nexus version hooks durnotify and resizes it away; this subscribes to the same source
--   messages instead, leaving the game UI intact
-- ============================================================
-- 수리 도구 자동 구매. 확인창 없이 바로 산다(사용자 요청).
-- 사용자 지시로 "재고를 목표 수량까지 채워두는" 방식을 버렸다. 지금은 **닳았을 때 그때
-- 필요한 만큼만** 산다. count 는 호출자가 계산해서 넘긴다
-- ⚠️ nexus 판은 `buy_qty - 보유량` 을 가드 없이 넘겨서, 이미 목표치보다 많으면 음수 수량으로
-- 상점 트랜잭션을 날렸다. 여기서는 count 가 0 이하면 아예 안 부른다
-- the "keep N in stock" model was dropped at the user's request: it now buys only what this
-- repair actually needs, with the count computed by the caller
function AK_repair_buy(count)
    if not g.settings or g.settings.repair_autobuy ~= 1 then
        return
    end
    if count == nil or count <= 0 then
        return
    end
    -- 한 번에 살 수 있는 상한. 계산이 어긋나도 대량 구매로 번지지 않게 하는 안전장치다
    -- a per-purchase cap, so a miscalculation cannot turn into a bulk buy
    local cap = g.settings.repair_buy_qty or 50
    if count > cap then
        count = cap
    end
    if AK_throttled("repair_buy", AK_BUY_GAP) then
        return
    end
    local shop_cls = GetClass("ItemTradeShop", AK_REPAIR_SHOP_ITEM)
    if not shop_cls then
        return
    end
    session.ResetItemList()
    session.AddItemID(tostring(0), 1)
    local str_list = NewStringList()
    str_list:Add(AK_REPAIR_SHOP_TYPE)
    item.DialogTransaction(AK_REPAIR_SHOP_TX, session.GetItemIDList(),
        string.format("%s %s", tostring(shop_cls.ClassID), tostring(count)), str_list)
    CHAT_SYSTEM(string.format(AK_t("kit_bought"), count))
end

-- 착용 장비를 훑어 (가장 낮은 내구도 비율, 가장 낮은 내구도 절대값, 필요한 증서 장수) 를 낸다.
-- 🔑 증서 한 장은 착용 장비 **전체**의 내구도를 AK_KIT_HEAL 만큼 올린다(item.ies 설명 그대로).
-- 그래서 필요한 장수는 "가장 많이 닳은 장비의 부족분 / 장당 회복량" 이다 — 장비 수와 무관하다
-- 🔑 one kit raises the durability of every equipped item by AK_KIT_HEAL, so the count needed is
-- driven by the single largest deficit, not by how many items are worn
local function AK_repair_scan()
    local equip_list = session.GetEquipItemList()
    if not equip_list then
        return nil, nil, 0
    end
    local worst_ratio, worst_dur, worst_deficit = nil, nil, 0
    for i = 0, equip_list:Count() - 1 do
        local equip_item = equip_list:GetEquipItemByIndex(i)
        local temp_obj = equip_item and equip_item:GetObject()
        if temp_obj then
            local obj = GetIES(temp_obj)
            if obj and obj.MaxDur and obj.MaxDur > 0 and obj.Dur then
                local ratio = obj.Dur / obj.MaxDur
                if worst_ratio == nil or ratio < worst_ratio then
                    worst_ratio = ratio
                    worst_dur = obj.Dur
                end
                if ratio < AK_DUR_RATIO then
                    local deficit = obj.MaxDur - obj.Dur
                    if deficit > worst_deficit then
                        worst_deficit = deficit
                    end
                end
            end
        end
    end
    return worst_ratio, worst_dur, math.ceil(worst_deficit / AK_KIT_HEAL)
end

local function AK_repair_try()
    if not AK_on("repair") or not g.ready then
        return
    end
    local worst_ratio, worst_dur, need = AK_repair_scan()
    if worst_ratio == nil or need <= 0 then
        -- 기준선 위로 올라왔다: 알림·정체 판정 상태를 푼다
        -- back above the line: clear the notice and stall bookkeeping
        g.repair_warned = false
        g.repair_stall = 0
        g.repair_used_at = nil
        return
    end

    local kit = session.GetInvItemByType(AK_REPAIR_ITEM_CLSID)
    local have = (kit and kit.count) or 0
    if have < need then
        AK_repair_buy(need - have)
    end
    if not kit or not AK_item_usable(kit) then
        if have <= 0 and not g.repair_warned then
            g.repair_warned = true
            CHAT_SYSTEM(AK_t("no_kit"))
        end
        return
    end

    -- ⚠️ 증서는 Lv.550 이하 장비만 고친다(item.ies NumberArg2). 그보다 높은 장비가 닳아 있으면
    -- 아무리 써도 내구도가 안 오르는데, 타이머는 5초마다 다시 시도한다 = 증서와 돈을 계속
    -- 태운다. 써 본 뒤 값이 그대로면 세 번까지만 시도하고 멈춘다
    -- ⚠️ the kit only repairs gear up to Lv.550. above that, durability never moves, and the 5s
    -- timer would keep burning kits and money forever - so a use that changes nothing counts a
    -- strike, and three strikes stop it
    local now = imcTime.GetAppTime()
    if g.repair_used_at ~= nil and now - g.repair_used_at >= 3.0 then
        if g.repair_mark ~= nil and worst_dur <= g.repair_mark then
            g.repair_stall = (g.repair_stall or 0) + 1
        else
            g.repair_stall = 0
        end
        g.repair_used_at = nil
    end
    if (g.repair_stall or 0) >= 3 then
        if not g.repair_warned then
            g.repair_warned = true
            CHAT_SYSTEM(AK_t("no_fix"))
        end
        return
    end

    -- 한 번에 한 장만 쓴다. 한 장이 올리는 양은 적지만, 수리되면 아이템 속성 갱신 메시지가
    -- 다시 오므로 필요한 만큼 이어서 쓴다. nexus 판은 obj.Dur 를 다시 읽지 않고 4장을 몰아 썼다
    -- one kit per pass: a repair fires the property update again, so it continues as needed. the
    -- nexus version burned four in a row off one stale read of obj.Dur
    if AK_throttled("repair") then
        return
    end
    g.repair_mark = worst_dur
    g.repair_used_at = now
    item.UseByGUID(kit:GetIESID())
end

-- durnotify 가 구독하는 것과 같은 원본 메시지 / the same source messages durnotify subscribes to
function AK_DUR_CHECK()
    AK_repair_try()
end

-- 🔑 안전 타이머. 물약과 같은 이유다: 메시지만 믿으면 그 메시지가 안 오는 상황에서 기능이
-- 통째로 죽는다. 내구도는 전투 중 조금씩 닳는데 클라가 그때마다 아이템 속성 갱신을 보내는지는
-- 우리가 보장할 수 없다. 5초마다 스스로 판정하면 그 구멍이 없어진다
-- 🔑 safety tick, for the same reason as the potion one: message-only means the feature dies
-- wherever the message does not arrive. durability drains gradually in combat and we cannot
-- guarantee the client emits an item property update for every tick of it
function AK_repair_tick(frame)
    if not AK_on("repair") then
        frame:StopUpdateScript("AK_repair_tick")
        return 0
    end
    AK_repair_try()
    return 1
end

function AK_repair_watch_start()
    if not g.frame then
        return
    end
    g.frame:StopUpdateScript("AK_repair_tick")
    if AK_on("repair") then
        g.frame:RunUpdateScript("AK_repair_tick", 5.0)
    end
end

-- ============================================================
-- HUD
-- ============================================================
function AK_hud_set_visual()
    local frame = ui.GetFrame(AK_HUD_FRAME)
    if not frame or not g.settings then
        return
    end
    for _, f in ipairs(AK_FEATURES) do
        local icon = GET_CHILD(frame, "icon_" .. f.key)
        if icon then
            AUTO_CAST(icon)
            -- 상태에 맞는 (평상시, 오버) 짝을 다시 붙인다 / re-attach the pair for the new state
            if AK_on(f.key) then
                AK_hover(icon, AK_TONE_ON, AK_TONE_ON_HOVER)
            else
                AK_hover(icon, AK_TONE_OFF, AK_TONE_OFF_HOVER)
            end
        end
    end
end

function AK_hud_toggle(frame, ctrl)
    if not ctrl or not g.settings then
        return
    end
    local key = ctrl:GetUserValue("AK_KEY")
    if key == nil or key == "" or g.settings[key] == nil then
        return
    end
    g.settings[key] = (g.settings[key] == 1) and 0 or 1
    AK_save_settings()
    AK_hud_set_visual()

    for _, f in ipairs(AK_FEATURES) do
        if f.key == key then
            CHAT_SYSTEM(string.format("[Auto Keeper] %s : %s", AK_t(f.label),
                AK_on(key) and AK_t("on") or AK_t("off")))
            break
        end
    end
    if key == "relic" then
        AK_relic_watch_start()
    elseif key == "stamina" then
        AK_sta_watch_start()
    elseif key == "potion" then
        AK_potion_watch_start()
    elseif key == "repair" then
        AK_repair_watch_start()
    end
end

-- ============================================================
-- 제작자 표기 ("made by [길드 엠블럼] 요매")
--   엠블럼은 서버에서 받는 PNG 라 SetImage 가 아니라 SetFileName 이다.
--   글자 폭은 재서 오른쪽 정렬하고, 클릭은 picture 에만 건다
--   the emblem is a downloaded PNG (SetFileName, not SetImage); widths are measured, and only
--   the picture takes the click
-- ============================================================
local AK_CREDIT_H = 18
local AK_CREDIT_EMBLEM = 16
local AK_CREDIT_GAP = 3
local AK_CREDIT_MADEBY_W = 64
local AK_CREDIT_NAME_W = 44
local AK_CREDIT_GUILD_ID = "1038076415618784"    -- 고양이젤리
local AK_CREDIT_WHISPER_NAME = "요매"

function AK_credit_whisper()
    pcall(ui.WhisperTo, AK_CREDIT_WHISPER_NAME)
end

function AK_credit_emblem_loaded(code)
    if code ~= 200 then
        return
    end
    local frame = ui.GetFrame(addonNameLower .. "_repair_cfg")
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
    local ok_n, image_name = pcall(guild.GetEmblemImageName, AK_CREDIT_GUILD_ID, world_id)
    if not ok_n or not image_name then
        return
    end
    AUTO_CAST(emblem)
    emblem:SetImage("")
    emblem:SetFileName(image_name)
end

function AK_credit_render(parent, parent_w, y, pad)
    local is_kr = option.GetCurrentCountry() == "kr"

    local made_by = parent:CreateOrGetControl("richtext", "credit_madeby", pad, y, AK_CREDIT_MADEBY_W, AK_CREDIT_H)
    AUTO_CAST(made_by)
    made_by:SetText("{ol}{s12}{#AAAAAA}made by")

    local name = parent:CreateOrGetControl("richtext", "credit_name", pad, y, AK_CREDIT_NAME_W, AK_CREDIT_H)
    AUTO_CAST(name)
    name:SetText("{ol}{s12}" .. (is_kr and "요매" or "Yomae"))

    local made_w = made_by:GetTextWidth()
    if not made_w or made_w <= 0 then
        made_w = AK_CREDIT_MADEBY_W
    end
    local name_w = name:GetTextWidth()
    if not name_w or name_w <= 0 then
        name_w = AK_CREDIT_NAME_W
    end
    made_by:Resize(made_w, AK_CREDIT_H)
    name:Resize(name_w, AK_CREDIT_H)

    local total_w = made_w + AK_CREDIT_GAP + AK_CREDIT_EMBLEM + AK_CREDIT_GAP + name_w
    local cx = math.max(0, parent_w - pad - total_w)
    made_by:SetOffset(cx, y)

    local emblem = parent:CreateOrGetControl("picture", "credit_emblem", cx + made_w + AK_CREDIT_GAP,
        y + math.floor((AK_CREDIT_H - AK_CREDIT_EMBLEM) / 2), AK_CREDIT_EMBLEM, AK_CREDIT_EMBLEM)
    AUTO_CAST(emblem)
    emblem:SetOffset(cx + made_w + AK_CREDIT_GAP, y + math.floor((AK_CREDIT_H - AK_CREDIT_EMBLEM) / 2))
    emblem:SetEnableStretch(1)
    emblem:EnableHitTest(true)
    AK_hover(emblem)
    emblem:SetEventScript(ui.LBUTTONUP, "AK_credit_whisper")
    emblem:SetTextTooltip(is_kr and "{ol}요매에게 귓속말" or "{ol}Whisper to Yomae")

    name:SetOffset(cx + made_w + AK_CREDIT_GAP + AK_CREDIT_EMBLEM + AK_CREDIT_GAP, y)

    pcall(GetGuildEmblemImage, "AK_credit_emblem_loaded", AK_CREDIT_GUILD_ID)
end

-- ============================================================
-- 수리 설정창 (수리 아이콘 우클릭)
--   테마대로 bg2 + 알파, 구역 패널, 제목 구분선. 창은 파괴하지 않고 숨긴다(§5)
--   themed like the other settings windows; hidden on close, never destroyed
-- ============================================================
local AK_CFG_FRAME = addonNameLower .. "_repair_cfg"
local AK_CFG_W = 300
local AK_CFG_H = 176
local AK_CFG_PAD = 14

function AK_cfg_close()
    local frame = ui.GetFrame(AK_CFG_FRAME)
    if frame then
        frame:ShowWindow(0)
    end
end

function AK_cfg_set_visual()
    local frame = ui.GetFrame(AK_CFG_FRAME)
    if not frame or not g.settings then
        return
    end
    local icon = GET_CHILD(frame, "buy_icon")
    if icon then
        AUTO_CAST(icon)
        icon:SetImage(g.settings.repair_autobuy == 1 and "ability_on" or "ability_off")
    end
end

function AK_cfg_toggle_buy()
    if not g.settings then
        return
    end
    g.settings.repair_autobuy = (g.settings.repair_autobuy == 1) and 0 or 1
    AK_save_settings()
    AK_cfg_set_visual()
    if g.settings.repair_autobuy == 1 then
        CHAT_SYSTEM(AK_t("buy_on"))
        -- 켜는 순간 이미 닳아 있으면 바로 판정한다. 재고를 채우는 게 아니라 필요분만 사므로
        -- 여기서도 "지금 수리가 필요한가"부터 본다
        -- re-evaluate right away: this buys for a repair, not for stock, so it starts from
        -- "is a repair needed now"
        AK_repair_try()
    else
        CHAT_SYSTEM(AK_t("buy_off"))
    end
end

function AK_cfg_save_qty()
    local frame = ui.GetFrame(AK_CFG_FRAME)
    if not frame or not g.settings then
        return
    end
    local edit = GET_CHILD_RECURSIVELY(frame, "buy_qty")
    if not edit then
        return
    end
    AUTO_CAST(edit)
    local n = tonumber(edit:GetText())
    if n == nil or n < 1 then
        n = 50
    end
    if n > 999 then
        n = 999
    end
    g.settings.repair_buy_qty = math.floor(n)
    edit:SetText(tostring(g.settings.repair_buy_qty))
    AK_save_settings()
    -- 이 값은 이제 목표 재고가 아니라 1회 구매 상한이다. 저장만 하고 사지 않는다
    -- this is a per-purchase cap now, not a stock target: saving it must not trigger a buy
end

function AK_cfg_open()
    if not g.settings then
        return
    end
    local frame = ui.GetFrame(AK_CFG_FRAME)
    if frame and frame:IsVisible() == 1 then
        frame:ShowWindow(0)
        return
    end
    if not frame then
        frame = ui.CreateNewFrame("notice_on_pc", AK_CFG_FRAME, 0, 0, 0, 0)
        AUTO_CAST(frame)
        local sw = ui.GetClientInitialWidth()
        local sh = ui.GetClientInitialHeight()
        frame:SetPos((sw - AK_CFG_W) / 2, (sh - AK_CFG_H) / 2)
    end
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(AK_CFG_W, AK_CFG_H)
    frame:SetSkinName(AK_UI_SKIN)
    frame:SetAlpha(AK_UI_ALPHA)
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(92)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)

    local title = frame:CreateOrGetControl("richtext", "title", AK_CFG_PAD + 2, 10, 220, 28)
    AUTO_CAST(title)
    title:SetText("{ol}{s18}{b}" .. AK_t("f_repair"))
    title:EnableHitTest(false)

    -- SetImage 가 크기를 되돌리므로 뒤에서 Resize (테마 §11) / Resize after SetImage
    local close = frame:CreateOrGetControl("picture", "close", 28, 28, ui.RIGHT, ui.TOP, 0, 10, AK_CFG_PAD, 0)
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetEnableStretch(1)
    close:Resize(28, 28)
    close:SetMargin(0, 10, AK_CFG_PAD, 0)
    close:EnableHitTest(1)
    AK_hover(close)
    close:SetEventScript(ui.LBUTTONUP, "AK_cfg_close")

    local line = frame:CreateOrGetControl("labelline", "title_line", AK_CFG_PAD, 44, AK_CFG_W - AK_CFG_PAD * 2, 3)
    AUTO_CAST(line)
    line:SetSkinName("labelline2")

    local panel = frame:CreateOrGetControl("groupbox", "panel", AK_CFG_PAD, 56, AK_CFG_W - AK_CFG_PAD * 2, 72)
    AUTO_CAST(panel)
    panel:SetSkinName("blackbox_op_50")
    panel:EnableScrollBar(0)
    panel:EnableHittestGroupBox(false)

    local buy_label = frame:CreateOrGetControl("richtext", "buy_label", AK_CFG_PAD + 10, 64, 180, 22)
    AUTO_CAST(buy_label)
    buy_label:SetText("{ol}{s13}" .. AK_t("cfg_autobuy"))
    buy_label:EnableHitTest(false)

    local buy_icon = frame:CreateOrGetControl("picture", "buy_icon", 51, 22, ui.RIGHT, ui.TOP, 0, 64,
        AK_CFG_PAD + 10, 0)
    AUTO_CAST(buy_icon)
    buy_icon:SetEnableStretch(1)
    buy_icon:EnableHitTest(1)
    buy_icon:SetTextTooltip(AK_t("cfg_autobuy_tip"))
    AK_hover(buy_icon)
    buy_icon:SetEventScript(ui.LBUTTONUP, "AK_cfg_toggle_buy")

    local qty_label = frame:CreateOrGetControl("richtext", "qty_label", AK_CFG_PAD + 10, 98, 180, 22)
    AUTO_CAST(qty_label)
    qty_label:SetText("{ol}{s13}" .. AK_t("cfg_qty"))
    qty_label:EnableHitTest(false)

    local qty_bg = frame:CreateOrGetControl("groupbox", "qty_bg", AK_CFG_W - AK_CFG_PAD - 10 - 70, 96, 70, 26)
    AUTO_CAST(qty_bg)
    qty_bg:SetSkinName("blackbox_op_80")
    qty_bg:EnableScrollBar(0)
    qty_bg:EnableHittestGroupBox(false)

    local qty = frame:CreateOrGetControl("edit", "buy_qty", AK_CFG_W - AK_CFG_PAD - 10 - 64, 99, 58, 20)
    AUTO_CAST(qty)
    qty:SetSkinName("None")
    qty:SetFontName("white_14_ol")
    qty:SetTextAlign("left", "center")
    qty:SetText(tostring(g.settings.repair_buy_qty or 50))
    qty:SetEventScript(ui.ENTERKEY, "AK_cfg_save_qty")

    pcall(AK_credit_render, frame, AK_CFG_W, AK_CFG_H - 26, AK_CFG_PAD)

    AK_cfg_set_visual()
    frame:ShowWindow(1)
end

function AK_hud_rclick(frame, ctrl)
    if not ctrl then
        return
    end
    if ctrl:GetUserValue("AK_KEY") == "repair" then
        AK_cfg_open()
    end
end

function AK_hud_drag(frame)
    if not frame or not g.settings then
        return
    end
    g.settings.hud_x = frame:GetX()
    g.settings.hud_y = frame:GetY()
    AK_save_settings()
end

function AK_hud_create()
    if not g.settings then
        return
    end
    local sw = ui.GetClientInitialWidth()
    local sh = ui.GetClientInitialHeight()
    -- ⚠️ 상한을 `sw - 20` 으로 잡으면 안 된다. `ui.GetClientInitialWidth` 는 환경에 따라 실제 UI
    -- 폭보다 작게 나오고(울트라와이드에서 실측 — convenient_hud 의 패널 보정 주석), 그러면 HUD 를
    -- 오른쪽에 둔 사용자는 **맵을 옮길 때마다** 이 검사에 걸려 기본 위치로 되돌아갔다.
    -- 이건 설정이 깨졌을 때만 걸리면 되는 안전망이다 — 사용자가 직접 옮긴 좌표를 의심하지 말 것
    -- ⚠️ never bound this by sw - 20: ui.GetClientInitialWidth can read narrower than the real UI
    -- width, which made the guard fire on every map change and reset a right-hand HUD to default
    local max_x = math.max(sw, 1920) * 2
    local max_y = math.max(sh, 1080) * 2
    if g.settings.hud_x < 0 or g.settings.hud_y < 0 or g.settings.hud_x > max_x or g.settings.hud_y > max_y then
        AK_default_hud_pos()
        AK_save_settings()
    end

    local frame = ui.GetFrame(AK_HUD_FRAME)
    if not frame then
        frame = ui.CreateNewFrame("notice_on_pc", AK_HUD_FRAME, 0, 0, 0, 0)
    end
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(AK_HUD_W, AK_HUD_H)
    frame:SetSkinName(AK_UI_SKIN)
    frame:SetAlpha(AK_UI_ALPHA)
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(90)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)
    frame:SetPos(g.settings.hud_x, g.settings.hud_y)
    frame:SetEventScript(ui.LBUTTONUP, "AK_hud_drag")

    -- 애드온 이름. 드래그를 막지 않게 hittest 를 끈다 / hit test off so it never eats a drag
    local label = frame:CreateOrGetControl("richtext", "hud_label", AK_LABEL_W, 30, ui.LEFT,
        ui.CENTER_VERT, AK_LABEL_X, 0, 0, 0)
    AUTO_CAST(label)
    label:SetFontName("white_16_ol")
    label:SetText("{s10}Auto{nl}Keeper")
    label:EnableHitTest(false)

    for i, f in ipairs(AK_FEATURES) do
        local x = AK_ICON_X + (i - 1) * (AK_ICON + AK_ICON_GAP)
        -- 드래그를 먹지 않도록 button 이 아니라 picture 를 쓴다(테마 §1)
        -- a picture, not a button, so dragging the bar still works
        local icon = frame:CreateOrGetControl("picture", "icon_" .. f.key, AK_ICON, AK_ICON,
            ui.LEFT, ui.CENTER_VERT, x, 0, 0, 0)
        AUTO_CAST(icon)
        icon:SetImage(f.icon)
        icon:SetEnableStretch(1)
        -- SetImage 가 크기를 이미지 원본으로 되돌리므로 반드시 뒤에서 Resize 한다(테마 §11).
        -- 위치는 gravity 로 잡았으니 SetOffset 이 아니라 SetMargin 으로 다시 준다 --
        -- 두 방식을 섞으면 기준점이 어긋난다
        -- SetImage resets the size to the image's own, so Resize after it. the position comes
        -- from gravity, so re-apply it with SetMargin, not SetOffset - mixing the two misplaces it
        icon:Resize(AK_ICON, AK_ICON)
        icon:SetMargin(x, 0, 0, 0)
        icon:EnableHitTest(1)
        icon:SetUserValue("AK_KEY", f.key)
        local tip = AK_t(f.tip)
        if f.tip_arg then
            tip = string.format(tip, math.floor(f.tip_arg * 100))
        end
        if f.key == "repair" then
            tip = tip .. "{nl}" .. AK_t("tip_rclick")
        end
        icon:SetTextTooltip(string.format("%s{nl}%s", AK_t(f.label), tip))
        icon:SetEventScript(ui.LBUTTONUP, "AK_hud_toggle")
        -- 수리만 우클릭으로 설정창을 연다 / only repair opens a settings window on right click
        if f.key == "repair" then
            icon:SetEventScript(ui.RBUTTONUP, "AK_hud_rclick")
        end
    end

    AK_hud_set_visual()
    frame:ShowWindow(g.settings.hud_open == 1 and 1 or 0)
end

-- 🔑 TP 상점을 열면 클라가 `ui.CloseAllOpenedUI()` 로 우리 HUD 까지 닫는다(tpitem.lua:505).
-- 상점을 닫을 때 부르는 `ui.OpenAllClosedUI()`(tpitem.lua:953)는 **애드온이 런타임에
-- ui.CreateNewFrame 으로 만든 프레임은 되살려주지 않는다** — 그래서 HUD 가 사라진 채 남았다.
-- 게임이 되돌려줄 것을 기대하지 말고 스스로 다시 세운다.
-- nexus indun_panel 이 `ESCAPE_PRESSED` 로 자기 프레임을 다시 만드는 것과 같은 대응이다.
-- 프레임이 통째로 없어졌을 수도 있으므로 ShowWindow 가 아니라 생성 경로를 다시 탄다
-- 🔑 the TP shop closes our HUD via ui.CloseAllOpenedUI, and the matching OpenAllClosedUI on
-- close does not restore frames an addon created at runtime. so we rebuild it ourselves - the
-- frame may be gone entirely, hence the full create path rather than a ShowWindow
function AK_hud_guard()
    if not g.settings or g.settings.hud_open ~= 1 then
        return
    end
    local frame = ui.GetFrame(AK_HUD_FRAME)
    if not frame or frame:IsVisible() == 0 then
        AK_hud_create()
    end
end

-- 타이머와 ESC 양쪽에 건다. 상점을 ESC 로 닫든 X 로 닫든 늦어도 2초 안에 돌아온다
-- both a timer and ESC: whichever way the shop is closed, the HUD is back within 2s
function AK_hud_guard_tick(frame)
    AK_hud_guard()
    return 1
end

-- ============================================================
-- Slash command
-- ============================================================
-- 진단용 `/keeper buff`. 지금 붙어 있는 버프 ID 를 전부 찍는다. 물약 버프가 안 지워지면
-- 그 ID 가 AK_POTION_BUFFS 에 있는지 눈으로 바로 확인할 수 있다 (없으면 여기 추가하면 된다)
-- diagnostic: dumps every buff id currently on you, so a potion buff that survives can be
-- checked against AK_POTION_BUFFS by eye (if it is missing, add it there)
function AK_dump_buffs()
    local ids = {}
    local buff_frame = ui.GetFrame("buff")
    if buff_frame ~= nil then
        for _, name in ipairs({"buffslot", "buffcountslot", "buffcountslot_sub"}) do
            local slot = GET_CHILD_RECURSIVELY(buff_frame, name)
            if slot ~= nil then
                for i = 0, slot:GetChildCount() - 1 do
                    local child = slot:GetChildByIndex(i)
                    local icon = child ~= nil and child:GetIcon() or nil
                    local info_obj = icon ~= nil and icon:GetInfo() or nil
                    if info_obj ~= nil and info_obj.type ~= nil and info_obj.type ~= 0 then
                        table.insert(ids, tostring(info_obj.type))
                    end
                end
            end
        end
    end
    CHAT_SYSTEM(string.format("[Auto Keeper] buffs: %s",
        #ids > 0 and table.concat(ids, ", ") or "-"))
end

-- 진단용 `/keeper dur`. 수리 도구 보유량과 가장 많이 닳은 장비 몇 개의 내구도(%)를 찍는다.
-- 수리가 안 도는 이유는 대개 셋 중 하나다: 증서가 없거나, 쿨다운이거나, 기준선 위거나
-- diagnostic: kit count plus the most worn equipment as percentages. a repair that never fires
-- is almost always one of: no kit, kit on cooldown, or nothing actually below the line
function AK_dump_dur()
    local kit = session.GetInvItemByType(AK_REPAIR_ITEM_CLSID)
    local have = (kit and kit.count) or 0
    local cool = 0
    if kit then
        local ok, c = pcall(item.GetCoolDown, kit.type)
        cool = (ok and c) or 0
    end
    local rows = {}
    local equip_list = session.GetEquipItemList()
    if equip_list then
        for i = 0, equip_list:Count() - 1 do
            local equip_item = equip_list:GetEquipItemByIndex(i)
            local temp_obj = equip_item and equip_item:GetObject()
            if temp_obj then
                local obj = GetIES(temp_obj)
                if obj and obj.MaxDur and obj.MaxDur > 0 then
                    table.insert(rows, {pct = obj.Dur / obj.MaxDur * 100, name = obj.Name or "?"})
                end
            end
        end
    end
    table.sort(rows, function(a, b) return a.pct < b.pct end)
    local out = {}
    for i = 1, math.min(#rows, 5) do
        table.insert(out, string.format("%s %d%%", rows[i].name, math.floor(rows[i].pct)))
    end
    local _, _, need = AK_repair_scan()
    CHAT_SYSTEM(string.format("[Auto Keeper] kit %d (cool %s) | need %d | %d%% 미만이면 수리 | %s",
        have, tostring(cool), need, math.floor(AK_DUR_RATIO * 100),
        #out > 0 and table.concat(out, ", ") or "-"))
end

function AK_SLASH(command)
    if not g.settings then
        return
    end
    if command ~= nil and command[1] == "buff" then
        AK_dump_buffs()
        return
    end
    if command ~= nil and command[1] == "dur" then
        AK_dump_dur()
        return
    end
    g.settings.hud_open = (g.settings.hud_open == 1) and 0 or 1
    AK_save_settings()
    local frame = ui.GetFrame(AK_HUD_FRAME)
    if frame then
        frame:ShowWindow(g.settings.hud_open)
    end
    CHAT_SYSTEM(g.settings.hud_open == 1 and AK_t("hud_shown") or AK_t("hud_hidden"))
end

-- ============================================================
-- Init
-- ============================================================
function AUTO_KEEPER_ON_INIT(addon, frame)
    g.addon = addon
    g.frame = frame
    frame:ShowWindow(1)
    acutil.slashCommand("/keeper", AK_SLASH)
    addon:RegisterMsg("GAME_START_3SEC", "AK_GAME_START")
end

-- 로딩 직후에는 아무것도 하지 않는다.
-- ⚠️ 원본 autostamina 는 ON_INIT 에서 한 번만 5초 유예를 걸어서, 캐릭터를 바꾸면 유예가 다시
-- 걸리지 않았다(주석에 적힌 "로딩 중 스태미나가 1000 으로 잡히는" 오작동이 재발한다).
-- 여기서는 캐릭터가 들어올 때마다 도는 GAME_START_3SEC 에서 유예를 다시 건다
-- ⚠️ the original armed its 5s grace only in ON_INIT, so a character change lost it. this
-- re-arms on GAME_START_3SEC, which runs for every character entry
function AK_GAME_START()
    g.ready = false
    g.active_id = tostring(session.loginInfo.GetAID())
    AK_create_folder("../addons")
    AK_create_folder("../addons/" .. addonNameLower)
    AK_create_folder("../addons/" .. addonNameLower .. "/" .. g.active_id)
    AK_load_settings()

    g.last_use = {}
    g.map_zone = nil

    -- ⚠️ GAME_START_3SEC 는 캐릭터가 들어올 때마다(맵 이동 포함) 다시 온다. 여기서 매번
    -- RegisterMsg 를 부르면 같은 핸들러가 여러 번 등록돼 한 메시지에 여러 번 실행된다
    -- ⚠️ GAME_START_3SEC fires on every character entry, so registering here each time would
    -- stack duplicate handlers and run them several times per message
    if not g.msg_registered then
        g.msg_registered = true
        g.addon:RegisterMsg("STA_UPDATE", "AK_STA_UPDATE")
        g.addon:RegisterMsg("PC_PROPERTY_UPDATE", "AK_STA_UPDATE")
        g.addon:RegisterMsg("BUFF_ADD", "AK_BUFF_MSG")
        g.addon:RegisterMsg("BUFF_UPDATE", "AK_BUFF_MSG")
        -- durnotify 가 구독하는 것과 같은 원본 메시지들(durnotify.lua:4-7).
        -- 게임 알림창을 훅하지 않으므로 그 UI 는 그대로 살아 있다
        -- the same sources durnotify subscribes to; its UI stays intact because we never hook it
        g.addon:RegisterMsg("UPDATE_ITEM_REPAIR", "AK_DUR_CHECK")
        g.addon:RegisterMsg("ITEM_PROP_UPDATE", "AK_DUR_CHECK")
        g.addon:RegisterMsg("EQUIP_ITEM_LIST_GET", "AK_DUR_CHECK")
        -- HUD 가 TP 상점 때문에 닫혔을 때 되살리는 보조 경로 (ESC 로 닫는 경우)
        -- restores the HUD after the TP shop closed it, for the ESC path
        g.addon:RegisterMsg("ESCAPE_PRESSED", "AK_hud_guard")
    end

    AK_hud_create()
    AK_relic_watch_start()
    AK_sta_watch_start()
    AK_potion_watch_start()
    AK_repair_watch_start()

    g.frame:StopUpdateScript("AK_hud_guard_tick")
    g.frame:RunUpdateScript("AK_hud_guard_tick", 2.0)

    g.frame:StopUpdateScript("AK_ready_on")
    g.frame:RunUpdateScript("AK_ready_on", 5.0)
    CHAT_SYSTEM(AK_t("loaded"))
end

function AK_ready_on(frame)
    g.ready = true
    frame:StopUpdateScript("AK_ready_on")
    return 0
end
