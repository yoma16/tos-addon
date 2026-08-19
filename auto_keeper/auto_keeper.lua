-- v1.0.0 first release
--   네 가지 자동 관리 기능을 HUD 아이콘 하나씩으로 켜고 끈다.
--   기존에 쓰던 autostamina / no_potion / nexus auto_repair / mini_addons rp_charge 를
--   다시 구현하면서 각각의 결함을 고쳤다. 근거는 아래 주석과
--   `.claude/docs/changelog-2026-08-17-auto-keeper.md` 참고
--   four upkeep automations, each toggled by its own HUD icon. these are reimplementations of
--   autostamina / no_potion / nexus auto_repair / mini_addons rp_charge with their defects fixed
-- v1.1.0 바카리네 장비 탈착(다섯 번째 아이콘) 추가.
--   nexus 의 vakarine_equip 을 옮겨오면서 무한 재시도·비결정 순서·중복 등록·피격마다 전 장비
--   스캔을 전부 고쳤다. 근거는 §5 주석과 `.claude/docs/changelog-2026-08-18-vakarine-equip.md`
--   ported from nexus vakarine_equip, with its unbounded retries, nondeterministic ordering,
--   duplicate message registration and per-hit equipment scan all fixed
local addonName = "auto_keeper"
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
        f_vakarine = "바카리네 장비 탈착",
        tip_vakarine = "{ol}선택한 장비를 벗었다가 다시 낍니다{nl}{#FFDD55}좌클릭 : 지금 실행{nl}우클릭 : 자동 실행 / 설정",
        vk_title = "바카리네 장비 탈착",
        vk_sec_run = "동작",
        vk_sec_slots = "탈착할 장비",
        vk_auto = "맵 진입 시 자동 실행",
        vk_auto_tip = "{ol}인스턴스 던전에 들어가면 자동으로 탈착합니다{nl}바카리네 축복 5세트를 착용했을 때만 작동합니다{nl}이 설정은 캐릭터별로 저장됩니다",
        vk_jsr = "주간 보스 레이드에서도",
        vk_jsr_tip = "{ol}JSR(보스 협동전) = 주간 보스 레이드 맵 8종{nl}일반 인스턴스 던전은 이 설정과 무관하게 작동합니다",
        vk_hp = "체력바에 상태 표시",
        -- ⚠️ 이 문자열은 SetTextTooltip 으로 **그대로** 넘어간다(string.format 을 타지 않는다).
        -- %% 로 이스케이프하면 화면에 %% 가 그대로 찍힌다. tip_stamina 류만 format 을 탄다
        -- ⚠️ passed straight to SetTextTooltip, so %% would render literally as %%
        vk_hp_tip = "{ol}체력바 위에 HP % 와 완벽/복수 표시를 띄웁니다{nl}복수 : 바카리네 5세트면 45% 이하, 5세트 미만이면 복수 수치가 있을 때 35% 이하{nl}완벽 : 완벽함 수치가 있을 때 100%",
        hp_perfect = "완벽",
        hp_revenge = "복수",
        vk_all = "전체 선택 / 해제",
        vk_menu_cfg = "설정",
        vk_slot_tip = "{ol}눌러서 켜고 끕니다. 켜진 부위만 탈착합니다",
        vk_run = "[Auto Keeper] 장비를 다시 착용합니다.",
        vk_done = "[Auto Keeper] 장비 탈착 완료.",
        vk_stuck = "[Auto Keeper] 장비 탈착이 진행되지 않아 중단했습니다.",
        vk_none = "[Auto Keeper] 탈착할 장비가 없습니다. 아이콘 우클릭 → 설정에서 부위를 고르세요.",
        vk_busy = "[Auto Keeper] 이미 탈착이 진행 중입니다.",
        vk_nexus = "[Auto Keeper] nexus 의 vakarine_equip 이 켜져 있습니다. 탈착이 두 번 걸리니 nexus 설정에서 꺼주세요.",
        vk_import = "[Auto Keeper] nexus 의 vakarine_equip 에서 탈착 부위 설정을 가져왔습니다.",
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
        f_vakarine = "バカリネ装備の付け外し",
        tip_vakarine = "{ol}選んだ装備を外して付け直します{nl}{#FFDD55}左クリック : 今すぐ実行{nl}右クリック : 自動実行 / 設定",
        vk_title = "バカリネ装備の付け外し",
        vk_sec_run = "動作",
        vk_sec_slots = "付け外しする装備",
        vk_auto = "マップ入場時に自動実行",
        vk_auto_tip = "{ol}インスタンスダンジョンに入ると自動で付け外しします{nl}バカリネの祝福5セット装備時のみ作動します{nl}この設定はキャラクターごとに保存されます",
        vk_jsr = "週間ボスレイドでも",
        vk_jsr_tip = "{ol}JSR(ボス協同戦) = 週間ボスレイドのマップ8種{nl}通常のインスタンスダンジョンはこの設定に関係なく作動します",
        vk_hp = "HPバーに状態を表示",
        vk_hp_tip = "{ol}HPバーの上に HP % と Perfect / Revenge を表示します{nl}Revenge : 5セットなら45%以下、5セット未満はrevenge値がある場合35%以下{nl}Perfect : perfection値がある場合100%",
        hp_perfect = "Perfect",
        hp_revenge = "Revenge",
        vk_all = "全選択 / 全解除",
        vk_menu_cfg = "設定",
        vk_slot_tip = "{ol}押してオン/オフします。オンの部位だけ付け外しします",
        vk_run = "[Auto Keeper] 装備を付け直します。",
        vk_done = "[Auto Keeper] 付け外し完了。",
        vk_stuck = "[Auto Keeper] 付け外しが進まないため中断しました。",
        vk_none = "[Auto Keeper] 付け外しする装備がありません。アイコン右クリック → 設定で部位を選んでください。",
        vk_busy = "[Auto Keeper] すでに付け外しが進行中です。",
        vk_nexus = "[Auto Keeper] nexus の vakarine_equip がオンです。二重に作動するので nexus 側をオフにしてください。",
        vk_import = "[Auto Keeper] nexus の vakarine_equip から部位設定を取り込みました。",
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
        f_vakarine = "Vakarine gear re-equip",
        tip_vakarine = "{ol}Takes the selected gear off and puts it back on{nl}{#FFDD55}Left click: run now{nl}Right click: auto run / settings",
        vk_title = "Vakarine gear re-equip",
        vk_sec_run = "Behaviour",
        vk_sec_slots = "Gear to swap",
        vk_auto = "Run on map entry",
        vk_auto_tip = "{ol}Runs automatically when you enter an instance dungeon{nl}Only while the 5-piece Vakarine blessing set is worn{nl}This setting is saved per character",
        vk_jsr = "Weekly boss raids too",
        vk_jsr_tip = "{ol}JSR (boss co-op) = the 8 weekly boss raid maps{nl}Regular instance dungeons run regardless of this",
        vk_hp = "Show status on the HP bar",
        vk_hp_tip = "{ol}Draws HP % and Perfect / Revenge above the HP bar{nl}Revenge: at or below 45% with the 5-piece set, or below 35% with a revenge value{nl}Perfect: at 100% with a perfection value",
        hp_perfect = "Perfect",
        hp_revenge = "Revenge",
        vk_all = "Select / clear all",
        vk_menu_cfg = "Settings",
        vk_slot_tip = "{ol}Click to toggle. Only lit slots are swapped",
        vk_run = "[Auto Keeper] Re-equipping gear.",
        vk_done = "[Auto Keeper] Gear swap done.",
        vk_stuck = "[Auto Keeper] The gear swap stopped making progress and was aborted.",
        vk_none = "[Auto Keeper] Nothing to swap. Right click the icon and pick some slots in the settings.",
        vk_busy = "[Auto Keeper] A gear swap is already running.",
        vk_nexus = "[Auto Keeper] nexus vakarine_equip is enabled. It will swap twice - please turn it off in nexus.",
        vk_import = "[Auto Keeper] Imported the slot selection from nexus vakarine_equip.",
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
-- 기준선을 넘는 순간을 얼마나 빨리 잡는가. 버프 메시지는 그 순간에 오지 않으므로
-- 실질적인 주 경로는 이 타이머다. 사용자 요청으로 1.0 → 0.5 (2026-08-18)
-- how fast the crossing is caught: no buff message arrives at that moment, so this timer is the
-- real primary path. 1.0 -> 0.5 at the user's request
local AK_POTION_GAP = 0.5
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

-- 바카리네 장비 탈착 / Vakarine gear re-equip
-- 슬롯 정의. **이 순서가 곧 처리 순서다.**
-- ⚠️ 원본은 `pairs(equip_map)` 로 큐를 만들어 실행할 때마다 탈착 순서가 달라졌다.
-- 무기를 먼저 끼워야 서브무기 판정이 꼬이지 않으므로 무기 → 방어구 → 장신구 → 목걸이 순으로
-- 고정한다. 목걸이가 마지막인 이유는 애니무스로 바꿔 끼는 특수 처리가 걸려 있어서다
-- ⚠️ the original built its queue from pairs(), so the order differed run to run. this is fixed:
-- weapons first, neck last (the neck carries the Animus substitution)
-- clmsg 는 게임의 부위 이름을 그대로 쓰기 위한 ClMsg 키다. 일부만 대소문자가 다르다
-- weapon = true 인 부위는 **입을 때 순서 의존이 있다**(양손무기가 왼손을 비우고, 방패는 오른손이
-- 한손무기여야 하는 식). 그래서 이 넷만 하나씩 순서대로 입고 나머지는 한 번에 몰아 보낸다
-- the weapon slots constrain each other when equipping, so only those four go one at a time
local AK_VK_SLOTS = {
    {key = "RH", idx = 8, clmsg = "RH", weapon = true},
    {key = "LH", idx = 9, clmsg = "LH", weapon = true},
    {key = "RH_SUB", idx = 30, clmsg = "RH_SUB", weapon = true},
    {key = "LH_SUB", idx = 31, clmsg = "LH_SUB", weapon = true},
    {key = "SHIRT", idx = 3, clmsg = "Shirt"},
    {key = "PANTS", idx = 14, clmsg = "Pants"},
    {key = "GLOVES", idx = 4, clmsg = "GLOVES"},
    {key = "BOOTS", idx = 5, clmsg = "BOOTS"},
    {key = "RING1", idx = 17, clmsg = "Ring1"},
    {key = "RING2", idx = 18, clmsg = "Ring2"},
    {key = "SHOULDER", idx = 34, clmsg = "SHOULDER"},
    {key = "BELT", idx = 33, clmsg = "BELT"},
    -- last = true : **무조건 제일 마지막에** 입는다. 애니무스로 바꿔 끼우는 부위라
    -- 나머지가 전부 자리를 잡은 뒤에 처리해야 한다(사용자 확인 사항)
    -- equipped dead last: this is the slot the Animus substitution lands in
    {key = "NECK", idx = 19, clmsg = "NECK", last = true}
}
local AK_VK_DELAY = 0.1              -- 큐 한 걸음 간격 / one queue step
-- 🔑 원본에는 재시도 상한이 아예 없었다. 인벤이 꽉 찼거나 서버가 거절하면 0.1초마다 같은
-- 요청을 영원히 다시 날리고, 인벤토리 창은 열린 채로 남았다. 두 겹으로 막는다:
-- 슬롯 하나당 요청 횟수 상한 + 전체 시간 상한
-- 🔑 the original had no retry cap at all: a full inventory or a server refusal meant the same
-- request every 0.1s forever, with the inventory window stuck open. two caps now bound it
local AK_VK_TRY_MAX = 10             -- 슬롯 하나에 대한 요청 상한 / per-slot request cap
-- 맵에 들어온 뒤 자동 실행을 언제 시도하는가. 원본은 GAME_START_3SEC 에서 곧바로 돌았고
-- 사용자 체감도 "맵에 오자마자"였다. 장비 목록이 아직 안 왔을 때만 짧게 재시도한다
-- the original ran right at GAME_START_3SEC; this retries quickly only while the equip list is
-- still missing, instead of waiting out a flat grace period
local AK_VK_AUTO_GAP = 0.2           -- 재시도 간격 / retry interval
local AK_VK_AUTO_TRIES = 25          -- 최대 25회 = 5초까지만 기다린다 / give up after 5s
local AK_VK_TIMEOUT = 20.0           -- 전체 강제 종료(초) / hard stop
local AK_VK_ANIMUS = "NECK04_103"    -- 애니무스 목걸이 / the Animus necklace
-- 자동 실행에서 제외/추가하는 맵. 11227 분열, 8022 베르니케, 11244 성역 3F
local AK_VK_MAP_SKIP = 11227
local AK_VK_MAP_EXTRA = {[8022] = true, [11244] = true}
-- Revenge 표시 기준. 바카리네 축복 5세트면 45%, 아니면 35%
local AK_VK_HP_SET = 0.45
local AK_VK_HP_PLAIN = 0.35
local AK_VK_SET_COUNT = 5            -- 이만큼 붙어 있어야 "5세트" / pieces needed
-- 🔑 완벽함 / 복수는 버프가 아니라 **착용 장비 랜덤옵션 수치의 합**이다 — 스탯창의 "특수 옵션".
-- 그래서 HP 만 보고 띄우면 옵션이 없는 캐릭터에게도 뜨는 거짓 표시가 된다(사용자 지적).
-- 값은 클라가 스탯창에서 쓰는 함수를 그대로 불러 얻는다:
--   GET_SPECIAL_OPTION_VALUE(pc, name)  (status.lua:1571)
--   RandomOption_j 가 이름과 **정확히 같을 때** RandomOptionValue_j 를 더한다(부분 일치 아님).
--   perfection / revenge 는 status.lua 의 special_option_list 에 등록된 이름 그대로다
-- 🔑 these are not buffs: they are the summed random-option values on the equipped gear, which is
-- what the status window calls a special option. The client's own summing function is reused
local AK_VK_OPT_PERFECTION = "perfection"
local AK_VK_OPT_REVENGE = "revenge"
-- 수치가 이 값 이상이면 "그 옵션을 갖고 있다"로 본다. 정수 합이므로 1 = 0보다 크다와 같다
-- treated as present at this value or above; the total is an integer, so 1 means "greater than 0"
local AK_VK_OPT_MIN = 1
-- 특수 옵션·세트 판정 캐시의 유효 시간(초).
-- 🔑 캐시는 "장비가 바뀌었다"는 메시지로 무효화하는데, **아이커 교체는 장비 자체가 안 바뀌어서
-- 그 메시지가 오지 않는다**(실제로 완벽함이 갱신되지 않았다). 아래에 아이커 메시지를 따로 구독했지만
-- 카드·초월 등 다른 경로를 전부 잡았다고 보장할 수 없으므로, **시간이 지나면 스스로 다시 잰다.**
-- 어떤 경로를 놓쳐도 최대 이 시간 안에 맞춰진다
-- 🔑 the cache is invalidated by equipment-change messages, but swapping an icor does not change
-- the item itself and sends none of them. the icor messages are subscribed below, but this TTL is
-- what makes any missed path self-heal
local AK_VK_CACHE_TTL = 5.0
-- 체력바 위 글자 크기. 숫자(%)와 상태(완벽/복수)를 따로 둔다 — 상태 쪽만 작게 해달라는 요청
-- separate sizes: only the status word was asked to be smaller
local AK_VK_HP_SIZE = "{s15}"        -- 체력 % 숫자 / the percentage
local AK_VK_STATUS_SIZE = "{s12}"    -- 완벽 / 복수 / the status word
-- 체력바 위로 얼마나 띄우는가(px). 값이 작을수록 아래로 내려온다.
-- 상태 글자를 작게 줄인 뒤 너무 높아 보인다는 피드백으로 25 → 21
-- how far above the gauge each line sits; smaller = lower. 25 -> 21 after the font shrank
local AK_VK_STATUS_DY = 21
local AK_VK_HP_DY = 10

-- ============================================================
-- HUD 레이아웃 / HUD layout
-- ============================================================
local AK_HUD_FRAME = addonNameLower .. "_hud"
local AK_UI_SKIN = "bg2"
local AK_UI_ALPHA = 110
-- 반투명 창 위에서는 글자가 배경에 묻힌다. **읽어야 하는 것**(값·입력칸·목록 행)에는
-- 한 단계 진한 상자를 깔고, 제목·설명 라벨은 그대로 둔다(테마 §14)
-- text sinks into a translucent window: anything you must read gets a darker box behind it
local AK_SKIN_PANEL = "blackbox_op_50"    -- 구역 배경 / section background
local AK_SKIN_FIELD = "blackbox_op_80"    -- 값·입력칸·켜진 목록 행 / values, inputs, lit rows
-- 마우스를 올린 행. **더 투명하게** 해서 "지금 이걸 고르고 있다"를 보여준다(사용자 요청).
-- 클라 선례: itemrullet.xml / transferseal.xml 의 FAR_FUTURE_OPTION_SKIN — 흐릿한 행 배경이다
-- the hovered row goes more transparent; this skin is the client's own faded-row background
local AK_SKIN_HOVER_ROW = "listbox_op_20"
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
-- AK_FEATURES 의 개수와 반드시 같아야 한다. 여기서만 쓰이므로 상수로 둔다
-- must match #AK_FEATURES; kept as a constant because the width is needed before that table
local AK_ICON_COUNT = 5
local AK_HUD_W = AK_ICON_X + AK_ICON * AK_ICON_COUNT + AK_ICON_GAP * (AK_ICON_COUNT - 1) + AK_HUD_PAD
local AK_HUD_POS_VER = 3       -- 레이아웃이 바뀌면 올려서 기본 위치를 다시 잡는다

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
     tip_arg = AK_DUR_RATIO},
    -- 🔑 다른 넷과 조작이 다르다. 좌클릭 = 지금 실행, 우클릭 = 자동 실행/설정 팝업.
    -- 아이콘 색은 "맵 진입 시 자동 실행" 상태를 나타낸다(캐릭터별 설정이라 AK_on 이 아니다)
    -- 🔑 this one behaves differently: left click runs it now, right click opens a small menu.
    -- the icon tone reflects the per-character auto-run flag, not an account-wide AK_on key
    -- 아이콘 = 채팅 이모티콘 "바카리네힘내"(chat_emoticons.ies 61)의 정지 이미지
    {key = "vakarine", icon = "bakarine_emotion61", label = "f_vakarine", tip = "tip_vakarine",
     manual = true}
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
        -- manual 기능(바카리네)은 계정 공통 on/off 가 없다. 상태는 vk.chars 에 캐릭터별로 있다
        if not f.manual and s[f.key] ~= 1 then
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
    -- 바카리네: jsr·표시 취향은 계정 공통, 자동 실행과 부위 선택은 캐릭터별
    -- ⚠️ 원본은 기본값을 "설정 파일이 아예 없을 때"만 채워서, 나중에 항목을 추가하면 구 파일에
    -- 그 키가 없는 채로 남아 창이 안 열렸다. 여기서는 매번 빠진 키만 메운다
    -- ⚠️ the original filled defaults only when the file was missing entirely, so a key added
    -- later stayed nil in existing files. this backfills whatever is missing, every load
    if type(s.vk) ~= "table" then
        s.vk = {}
    end
    if s.vk.jsr ~= 0 then
        s.vk.jsr = 1
    end
    if s.vk.hp_overlay ~= 0 then
        s.vk.hp_overlay = 1
    end
    if type(s.vk.chars) ~= "table" then
        s.vk.chars = {}
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

-- groupbox 용 오버 처리. **groupbox 에는 SetColorTone 선례가 없어서**(테마) 색이 아니라
-- 스킨을 갈아 끼운다. 값이 없는 GetUserValue 는 "None" 을 돌려주므로 "None" 은 스킨 이름으로
-- 쓰지 않는다(구분이 안 된다)
-- groupbox has no SetColorTone precedent, so the skin is swapped instead. "None" is never used
-- as a hover skin here because an unset user value reads back as exactly that
function AK_SKIN_ON(frame, ctrl)
    if ctrl == nil then
        return
    end
    local skin = ctrl:GetUserValue("AK_SKIN_HOVER")
    if skin ~= nil and skin ~= "" and skin ~= "None" then
        AUTO_CAST(ctrl)
        ctrl:SetSkinName(skin)
    end
end

function AK_SKIN_OFF(frame, ctrl)
    if ctrl == nil then
        return
    end
    local skin = ctrl:GetUserValue("AK_SKIN_IDLE")
    if skin ~= nil and skin ~= "" and skin ~= "None" then
        AUTO_CAST(ctrl)
        ctrl:SetSkinName(skin)
    end
end

local function AK_skin_hover(ctrl, idle, hover)
    if ctrl == nil then
        return
    end
    ctrl:SetUserValue("AK_SKIN_IDLE", idle)
    ctrl:SetUserValue("AK_SKIN_HOVER", hover)
    ctrl:SetSkinName(idle)
    ctrl:SetEventScript(ui.MOUSEON, "AK_SKIN_ON")
    ctrl:SetEventScript(ui.MOUSEOFF, "AK_SKIN_OFF")
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
        g.frame:RunUpdateScript("AK_potion_tick", AK_POTION_GAP)
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
-- 장비가 바뀌는 자리이기도 하므로 바카리네 5세트 판정 캐시를 여기서 무효화한다(§5)
-- this is also where equipment changes land, so it invalidates the Vakarine set cache
function AK_DUR_CHECK()
    g.vk_dirty = true
    AK_repair_try()
end

-- 아이커 교체·장착·해제. 장비 자체는 그대로라 EQUIP_ITEM_LIST_GET 이 오지 않으므로
-- 특수 옵션(완벽함·복수) 캐시를 여기서 따로 무효화한다
-- swapping an icor changes the random options without changing the item, so the equipment
-- messages never fire; this is the path that catches it
function AK_VK_OPT_DIRTY()
    g.vk_dirty = true
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
-- 5. 바카리네 장비 탈착 / Vakarine gear re-equip
--   nexus `vakarine_equip` 을 옮겨왔다. 고친 것:
--   ⓐ 재시도 상한이 없어 인벤이 꽉 차거나 서버가 거절하면 0.1초마다 영원히 반복하던 것
--   ⓑ `pairs()` 순회라 실행마다 탈착 순서가 달랐던 것
--   ⓒ 피격(TAKE_DAMAGE)마다 전 장비의 랜덤옵션을 훑던 5세트 판정 → 장비가 바뀔 때만 재계산
--   ⓓ 애니무스 재시도 카운터를 `GetUserIValue` 로 "쓰려고" 해서 늘 0이던 것(setter 는
--      `SetUserValue` 다 — 여기서는 아예 우리 상태로 들고 있는다) + 인벤에 없을 때의 nil 인덱싱
--   ⓔ 무기 슬롯 표시를 1번으로 바꿔놓고 되돌리지 않던 것
--   ported from nexus vakarine_equip with its unbounded retries, nondeterministic order,
--   per-hit equipment scan, broken retry counter and unrestored weapon-slot display all fixed
-- ============================================================
local AK_NEXUS_DIR = "_nexus_addons"

-- nexus 쪽 설정에서 부위 선택을 가져온다. **읽기만 한다** — 남의 애드온 설정은 쓰지 않는다
-- read-only import of the slot selection from nexus; we never write to another addon's settings
local function AK_vk_import_nexus(c)
    local src = AK_load_json(string.format("../addons/%s/%s/vakarine_equip.json",
        AK_NEXUS_DIR, g.active_id))
    if not src or type(src.chars) ~= "table" or not g.cid then
        return false
    end
    local mine = src.chars[g.cid]
    if type(mine) ~= "table" then
        return false
    end
    local found = 0
    for _, slot in ipairs(AK_VK_SLOTS) do
        if mine[slot.key] == 1 then
            c.slots[slot.key] = 1
            found = found + 1
        end
    end
    if src.jsr == 0 then
        g.settings.vk.jsr = 0
    end
    return found > 0
end

-- 캐릭터별 설정. 없으면 만들고, 처음 만드는 경우에만 nexus 설정을 가져온다.
-- ⚠️ 자동 실행은 가져오지 않고 항상 꺼진 채로 시작한다 — nexus 쪽을 아직 안 껐다면 둘 다 돌아
-- 탈착이 두 번 걸리기 때문이다. auto_keeper 의 다른 기능과도 같은 규칙이다(전부 opt-in)
-- ⚠️ the auto-run flag is deliberately not imported: nexus may still be enabled, and two swaps
-- would fight. it starts off, like every other auto_keeper feature
local function AK_vk_char()
    if not g.settings or not g.cid then
        return nil
    end
    local c = g.settings.vk.chars[g.cid]
    local fresh = false
    if type(c) ~= "table" then
        c = {auto = 0, slots = {}}
        g.settings.vk.chars[g.cid] = c
        fresh = true
    end
    if type(c.slots) ~= "table" then
        c.slots = {}
    end
    if fresh and AK_vk_import_nexus(c) then
        CHAT_SYSTEM(AK_t("vk_import"))
    end
    if c.auto ~= 1 then
        c.auto = 0
    end
    for _, slot in ipairs(AK_VK_SLOTS) do
        if c.slots[slot.key] ~= 1 then
            c.slots[slot.key] = 0
        end
    end
    if fresh then
        AK_save_settings()
    end
    return c
end

function AK_vk_auto_on()
    local c = AK_vk_char()
    return c ~= nil and c.auto == 1
end

local function AK_vk_has_slot(c)
    for _, slot in ipairs(AK_VK_SLOTS) do
        if c.slots[slot.key] == 1 then
            return true
        end
    end
    return false
end

-- 장비 목록이 서버에서 도착했는가. 맵 진입 직후에는 아직 비어 있을 수 있는데, 그때 판정하면
-- "5세트가 아니다 / 벗을 게 없다"로 잘못 결론내고 조용히 끝난다.
-- ⚠️ 이걸 시간(유예 5초)으로 때우면 원본보다 5초 느려진다 — 상태를 직접 보고 준비되면 바로 간다
-- ⚠️ waiting out a fixed grace period costs 5s over the original; this checks the actual state
local function AK_vk_equip_ready()
    local list = session.GetEquipItemList()
    if not list then
        return false
    end
    local guids = list:GetGuidList()
    if not guids then
        return false
    end
    for i = 0, guids:Count() - 1 do
        if guids:Get(i) ~= "0" then
            return true
        end
    end
    return false
end

-- 착용 장비 중 "바카리네 축복" 랜덤옵션이 붙은 개수를 센다.
-- 🔑 비싼 판정이다(장비 수 x 랜덤옵션 수 만큼 ScpArgMsg). 원본은 이걸 STAT_UPDATE/TAKE_DAMAGE
-- 에 물려 전투 중 초당 수십 번 돌렸다. 여기서는 장비가 바뀌었다는 신호(AK_DUR_CHECK)가 왔을
-- 때만 다시 계산하고 나머지는 캐시를 읽는다
-- 🔑 an expensive scan the original ran on every hit taken; now it is recomputed only when an
-- equipment change is signalled, and read from cache otherwise
-- 특수 옵션 수치를 클라 함수로 얻는다. 0 이면 그 옵션이 아예 없다는 뜻이다
-- reads a special option's total through the client's own function; 0 means absent
function AK_vk_special(name)
    local pc = GetMyPCObject()
    if not pc then
        return 0
    end
    local ok, value = pcall(GET_SPECIAL_OPTION_VALUE, pc, name)
    return (ok and tonumber(value)) or 0
end

-- 한 번에 세 가지를 낸다: 5세트인가 / 완벽함 수치 / 복수 수치.
-- 셋 다 장비에만 달려 있으므로 같은 캐시에 얹는다
-- three verdicts in one go; all of them depend on equipment only, so they share the cache
local function AK_vk_scan()
    local list = session.GetEquipItemList()
    if not list then
        return false, 0, 0
    end
    local guids = list:GetGuidList()
    local worn = 0
    for i = 0, guids:Count() - 1 do
        local guid = guids:Get(i)
        if guid ~= "0" then
            local equip = list:GetItemByGuid(guid)
            local obj = equip and GetIES(equip:GetObject())
            if obj then
                for j = 1, MAX_OPTION_EXTRACT_COUNT do
                    local msg = ScpArgMsg(obj["RandomOption_" .. j])
                    if msg ~= nil and string.find(msg, "vakarine_bless") ~= nil then
                        worn = worn + 1
                        break
                    end
                end
            end
        end
    end
    return worn >= AK_VK_SET_COUNT,
        AK_vk_special(AK_VK_OPT_PERFECTION),
        AK_vk_special(AK_VK_OPT_REVENGE)
end

-- 캐시 갱신. 반환: 5세트인가, 완벽함 수치, 복수 수치
-- ⚠️ 장비 목록이 아직 안 왔으면 **캐시하지 않는다.** 여기서 false 를 굳혀 버리면 그 뒤
-- 자동 실행이 계속 "5세트 아님"으로 판정된다. 접속 직후에는 체력바 오버레이 타이머가
-- 이 함수를 먼저 부르므로 실제로 일어날 수 있는 순서다
-- ⚠️ never cache a verdict taken from an empty equip list: the HP overlay timer calls this
-- first after login, and a cached false would suppress the auto run for good
local function AK_vk_refresh()
    local now = imcTime.GetAppTime()
    local stale = g.vk_at == nil or (now - g.vk_at) > AK_VK_CACHE_TTL
    if g.vk_set == nil or g.vk_dirty or stale then
        if not AK_vk_equip_ready() then
            return false, 0, 0
        end
        local ok, is_set, perfection, revenge = pcall(AK_vk_scan)
        g.vk_set = (ok and is_set) or false
        g.vk_perfection = (ok and perfection) or 0
        g.vk_revenge = (ok and revenge) or 0
        g.vk_dirty = false
        g.vk_at = now
    end
    return g.vk_set, g.vk_perfection, g.vk_revenge
end

function AK_vk_is_set()
    local is_set = AK_vk_refresh()
    return is_set
end

function AK_vk_perfection()
    local _, perfection = AK_vk_refresh()
    return perfection or 0
end

function AK_vk_revenge()
    local _, _, revenge = AK_vk_refresh()
    return revenge or 0
end

local function AK_vk_map_type()
    local ok, cls = pcall(GetClass, "Map", session.GetMapName())
    if not ok or not cls then
        return "None", "None"
    end
    return TryGetProp(cls, "MapType", "None"), TryGetProp(cls, "Keyword", "None")
end

-- 자동 실행 대상 맵인가. 주간 보스 레이드(JSR)는 맵 ID 를 박지 않고 Keyword 로 본다 —
-- IMC 가 맵을 추가해도 누락되지 않는다(클라도 같은 방식: indunenter.lua:327)
-- weekly boss maps are matched by Keyword rather than hardcoded ids, like the client itself
local function AK_vk_map_ok()
    local map_id = session.GetMapID()
    if AK_VK_MAP_EXTRA[map_id] then
        return true
    end
    local map_type, keyword = AK_vk_map_type()
    if keyword ~= nil and string.find(keyword, "WeeklyBossMap") ~= nil then
        return g.settings.vk.jsr == 1
    end
    return map_type == "Instance" and map_id ~= AK_VK_MAP_SKIP
end

-- quiet 는 "열자마자 할 일이 없었다"는 경우다. 정리는 똑같이 하되 완료 메시지는 내지 않는다
-- quiet covers "nothing to do after all": same cleanup, no completion notice
local function AK_vk_finish(done, quiet)
    g.vk_step = nil
    g.vk_queue = nil
    g.vk_dirty = true
    local inv = ui.GetFrame("inventory")
    if inv then
        -- 표시하던 무기 슬롯 세트를 되돌린다. DO_WEAPON_SLOT_CHANGE 는 이미지 두 장과
        -- CURRENT_WEAPON_INDEX 만 바꾸는 **표시 전용** 함수라(inventory.lua:4499-4530) 서버와는
        -- 무관하지만, 원본은 1번으로 바꿔놓고 되돌리지 않아 사용자 화면이 멋대로 바뀌어 있었다
        -- display-only in the client, but the original never put it back
        if g.vk_prev_slot == 2 then
            DO_WEAPON_SLOT_CHANGE(inv, 2)
        end
        inv:ShowWindow(0)
    end
    ui.SetHoldUI(false)
    if not quiet then
        CHAT_SYSTEM(done and AK_t("vk_done") or AK_t("vk_stuck"))
    end
end

-- 큐 항목 하나를 착용 요청한다. 반환 true = 요청을 보냈다 / false = 보낼 필요·방법이 없어
-- done 으로 처리했다. 몰아 보내기와 한 개씩 보내기가 이 함수를 공유한다
-- shared by both the burst and the one-at-a-time path
local function AK_vk_equip_one(e, list)
    -- 목걸이만 예외: 애니무스를 갖고 있으면 원래 목걸이 대신 그것을 낀다(원본과 동일)
    local want = e.iesid
    if e.slot.key == "NECK" and g.vk_animus then
        want = g.vk_animus
    end
    local cur = list and list:GetEquipItemByIndex(e.slot.idx) or nil
    if cur ~= nil and cur:GetIESID() == want then
        e.done = true
        return false
    end
    if e.try >= AK_VK_TRY_MAX then
        e.done = true
        g.vk_gave_up = true
        return false
    end
    local inv_item = session.GetInvItemByGuid(want)
    if inv_item == nil then
        -- 인벤에서 사라졌다(팔았거나 창고에 넣었거나) / gone from the inventory
        e.done = true
        g.vk_gave_up = true
        return false
    end
    e.try = e.try + 1
    ITEM_EQUIP(inv_item.invIndex, e.slot.key)
    return true
end

-- 한 걸음에 요청 하나. 요청이 먹혔는지는 다음 걸음에서 장비 목록을 다시 읽어 판단한다.
-- 슬롯당 요청 상한과 전체 시간 상한 두 겹으로 무한 반복을 막는다
-- one request per step, verified by re-reading the equip list on the next step. two caps bound it
function AK_vk_tick(frame)
    if g.vk_step == nil or not g.vk_queue then
        frame:StopUpdateScript("AK_vk_tick")
        return 0
    end
    if imcTime.GetAppTime() - (g.vk_started or 0) > AK_VK_TIMEOUT then
        AK_vk_finish(false)
        return 0
    end
    local list = session.GetEquipItemList()
    if not list then
        return 1
    end

    -- 탈거 단계는 이제 **확인과 재시도**만 한다(첫 요청은 AK_vk_start 에서 한꺼번에 보냈다)
    -- the unequip phase now only verifies and retries; the first round went out as a burst
    if g.vk_step == "unequip" then
        for _, e in ipairs(g.vk_queue) do
            if not e.done then
                local cur = list:GetEquipItemByIndex(e.slot.idx)
                if cur == nil or cur:GetIESID() == "0" then
                    e.done = true
                elseif e.try >= AK_VK_TRY_MAX then
                    -- 안 벗겨진다(인벤이 꽉 찼을 때 등): 포기하고 다음 부위로.
                    -- 조용히 넘기면 "완료"라고 알리게 되므로 포기했다는 사실을 남긴다
                    -- give up on this slot, but remember it so the notice is not a false "done"
                    e.done = true
                    g.vk_gave_up = true
                else
                    e.try = e.try + 1
                    item.UnEquip(e.slot.idx)
                    return 1
                end
            end
        end
        for _, e in ipairs(g.vk_queue) do
            e.done = false
            e.try = 0
        end
        g.vk_step = "equip"
        -- 🔑 방어구·장신구는 서로 순서 의존이 없으므로 **여기서 한 번에** 보낸다.
        -- 순서대로 가야 하는 것만 남긴다: 무기 4부위(서로를 제약한다) + 목걸이(last, 애니무스라
        -- 무조건 맨 끝). AK_VK_SLOTS 에서 NECK 이 배열 마지막이므로 순차 루프가 자연히 끝에 둔다
        -- 🔑 armour and accessories go out together. what stays sequenced: the four weapon slots
        -- (they constrain each other) and the neck (Animus, always dead last - it is the final
        -- element of AK_VK_SLOTS so the sequential loop naturally leaves it for the end)
        for _, e in ipairs(g.vk_queue) do
            if not e.slot.weapon and not e.slot.last then
                AK_vk_equip_one(e, list)
            end
        end
        return 1
    end

    -- 무기는 하나씩, 나머지는 위에서 몰아 보낸 것의 확인·재시도만 한다
    -- weapons one at a time; the rest is verification and retries for the burst
    for _, e in ipairs(g.vk_queue) do
        if not e.done and AK_vk_equip_one(e, list) then
            return 1
        end
    end

    AK_vk_finish(not g.vk_gave_up)
    return 0
end

-- 반환값 = **판정이 끝났는가**(시작했든, 할 일이 없다고 결론냈든). false 는 "장비 목록이 아직
-- 안 와서 판단 자체를 못 했다"는 뜻이고, 그때만 호출자가 다시 부른다
-- returns whether a verdict was reached; false means "could not decide yet, call me again"
function AK_vk_start(is_manual)
    if not g.settings then
        return true
    end
    local c = AK_vk_char()
    if not c then
        return true
    end
    if g.vk_step ~= nil then
        if is_manual then
            CHAT_SYSTEM(AK_t("vk_busy"))
        end
        return true
    end
    if not is_manual then
        -- 장비 목록이 아직이면 판정을 미룬다. 여기서 5세트를 물으면 "아니다"가 나와 버린다
        if not AK_vk_equip_ready() then
            return false
        end
        if c.auto ~= 1 or not AK_vk_is_set() or not AK_vk_map_ok() then
            return true
        end
    end
    -- ⚠️ 인벤토리를 열기 **전에** 판정한다. 원본은 먼저 열고 나서 큐가 비면 그냥 return 해서
    -- 아무것도 안 하고 인벤토리 창만 열어둔 채로 끝났다
    -- ⚠️ decided before the inventory is opened: the original opened it first and could then
    -- return without doing anything, leaving the window open
    if not AK_vk_has_slot(c) then
        if is_manual then
            CHAT_SYSTEM(AK_t("vk_none"))
        end
        return true
    end

    local inv = ui.GetFrame("inventory")
    if not inv then
        return false
    end
    g.vk_prev_slot = inv:GetUserIValue("CURRENT_WEAPON_INDEX")
    inv:ShowWindow(1)
    DO_WEAPON_SLOT_CHANGE(inv, 1)
    ui.SetHoldUI(true)

    local list = session.GetEquipItemList()
    local queue = {}
    local wants_neck = false
    if list then
        for _, slot in ipairs(AK_VK_SLOTS) do
            if c.slots[slot.key] == 1 then
                local cur = list:GetEquipItemByIndex(slot.idx)
                local iesid = (cur ~= nil) and cur:GetIESID() or "0"
                if iesid ~= "0" then
                    table.insert(queue, {slot = slot, iesid = iesid, try = 0, done = false})
                    if slot.key == "NECK" then
                        wants_neck = true
                    end
                end
            end
        end
    end
    -- 고른 부위를 지금 하나도 착용하고 있지 않다. 열어둔 인벤토리는 반드시 닫는다
    if #queue == 0 then
        AK_vk_finish(true, true)
        if is_manual then
            CHAT_SYSTEM(AK_t("vk_none"))
        end
        return true
    end

    -- ⚠️ 원본은 목걸이를 고르지 않았어도 애니무스를 기억해 두고, 나중에 도시에서 그것을 강제로
    -- 끼웠다(고르지도 않은 부위를 건드린다). 목걸이가 큐에 있을 때만 잡는다
    -- ⚠️ the original latched the Animus even when NECK was not selected, and later force-equipped
    -- it in town - a slot the user never asked for. only latched when NECK is actually queued
    g.vk_animus = nil
    g.vk_animus_try = 0
    if wants_neck then
        local animus = session.GetInvItemByName(AK_VK_ANIMUS)
        g.vk_animus = animus and animus:GetIESID() or nil
    end

    g.vk_queue = queue
    g.vk_step = "unequip"
    g.vk_gave_up = false
    g.vk_started = imcTime.GetAppTime()
    CHAT_SYSTEM(AK_t("vk_run"))

    -- 🔑 벗는 것은 **한 번에 몰아 보낸다.** 부위마다 한 틱(0.1초)씩 기다리면 13부위에 1.3초가
    -- 걸리는데, 탈거는 부위끼리 순서 의존이 없다(각각 독립 요청이다). 입는 쪽은 무기 → 방어구
    -- → 목걸이 순서가 있어야 하므로 지금처럼 하나씩 간다.
    -- 몰아 보낸 뒤에도 남는 부위가 있으면 다음 틱부터 기존 로직이 하나씩 재시도한다
    -- 🔑 the unequips go out together: they have no ordering dependency on each other, while the
    -- equips do (weapons first, neck last). anything that survives the burst is retried one per
    -- tick by the existing loop
    -- ⚠️ 일괄 탈착 API(session.job.ReqUnEquipItemAll)는 쓰지 않는다 — 인자가 없어서 부위를
    -- 고를 수 없고(클라 전직 UI 전용: changejob.lua:461), 인장·코어·면류관·모자까지 다 벗긴다
    -- ⚠️ session.job.ReqUnEquipItemAll takes no arguments, so it cannot spare the slots the user
    -- wants kept - it is the job-change strip-everything path
    for _, e in ipairs(queue) do
        e.try = 1
        item.UnEquip(e.slot.idx)
    end

    g.frame:StopUpdateScript("AK_vk_tick")
    g.frame:RunUpdateScript("AK_vk_tick", AK_VK_DELAY)
    return true
end

-- 맵에 들어오자마자(GAME_START_3SEC) 도는 재시도 루프. 장비 목록이 오는 즉시 실행하고 멈춘다
-- fires the moment the equip list arrives, then stops
function AK_vk_auto_tick(frame)
    g.vk_auto_try = (g.vk_auto_try or 0) + 1
    if AK_vk_start(false) or g.vk_auto_try >= AK_VK_AUTO_TRIES then
        frame:StopUpdateScript("AK_vk_auto_tick")
        return 0
    end
    return 1
end

function AK_vk_manual()
    AK_vk_start(true)
end

-- 애니무스 확인. 탈착 때 애니무스로 바꿔 끼우는 데 실패했으면 도시에서 다시 시도한다.
-- ⚠️ 원본은 `GetUserIValue("TRY", try + 1)` 로 카운터를 "쓰려고" 했다 — 그건 getter 라
-- 값이 안 써지고 TRY 는 영원히 0이었다(setter 는 SetUserValue). 상한이 무력화돼 1초마다
-- 무한 재시도했고, 인벤에 애니무스가 없으면 nil 인덱싱으로 에러까지 났다
-- ⚠️ the original used the getter to try to write its retry counter, so the cap never applied
function AK_vk_animus_tick(frame)
    if not g.vk_animus then
        frame:StopUpdateScript("AK_vk_animus_tick")
        return 0
    end
    -- 탈착이 도는 중이면 그쪽이 목걸이를 만지고 있다. 끝날 때까지 기다린다
    if g.vk_step ~= nil then
        return 1
    end
    local list = session.GetEquipItemList()
    local cur = list and list:GetEquipItemByIndex(19) or nil
    if cur ~= nil and cur:GetIESID() == g.vk_animus then
        g.vk_animus = nil
        return 0
    end
    g.vk_animus_try = (g.vk_animus_try or 0) + 1
    local inv_item = session.GetInvItemByGuid(g.vk_animus)
    if inv_item == nil or g.vk_animus_try > 3 then
        g.vk_animus = nil
        return 0
    end
    ITEM_EQUIP(inv_item.invIndex, "NECK")
    return 1
end

-- ============================================================
-- 체력바 상태 표시 (바카리네 옵션)
--   표시 자체는 현재/최대 체력 비교뿐이다. 장비를 훑는 것은 Revenge 기준선(45% / 35%)을
--   고르기 위해서인데, 그 값은 캐시라 매 틱 비용이 사실상 없다
--   the overlay itself is just current/max HP; the set check only picks the threshold and is cached
-- ============================================================
local function AK_vk_hp_text(base, name, gauge, dy, text)
    local ctrl = base:CreateOrGetControl("richtext", name, 0, 0, gauge:GetWidth(), gauge:GetHeight())
    AUTO_CAST(ctrl)
    ctrl:SetGravity(ui.RIGHT, ui.TOP)
    ctrl:SetOffset(gauge:GetX(), gauge:GetY() - dy)
    ctrl:EnableHitTest(false)
    ctrl:SetText(text)
    ctrl:ShowWindow(1)
    return ctrl
end

function AK_vk_hp_clear()
    local base = ui.GetFrame("charbaseinfo1_my")
    if not base then
        return
    end
    for _, name in ipairs({"ak_vk_status", "ak_vk_hp"}) do
        local ctrl = GET_CHILD(base, name)
        if ctrl then
            AUTO_CAST(ctrl)
            ctrl:ShowWindow(0)
        end
    end
end

-- 🔑 HP 와 maxHP 는 부를 때마다 **새로 읽는다**(info.GetStat). 캐시되는 것은 바카리네 5세트
-- 개수뿐이고 그건 장비에만 달려 있으므로, 스킬로 최대 체력이 바뀌어 현재 비율이 달라지는
-- 상황도 그대로 반영된다. 남은 문제는 정확성이 아니라 **얼마나 빨리 반영되는가**였다
-- 🔑 both HP and maxHP are re-read on every call; only the set count is cached and that depends
-- on equipment alone, so a skill that moves max HP is reflected correctly. the open question was
-- latency, not correctness
local function AK_vk_hp_refresh()
    if not g.settings or g.settings.vk.hp_overlay ~= 1 then
        return
    end
    local base = ui.GetFrame("charbaseinfo1_my")
    local gauge = base and GET_CHILD_RECURSIVELY(base, "pcHpGauge") or nil
    local stat = AK_my_stat()
    if not gauge or not stat or not stat.maxHP or stat.maxHP <= 0 then
        return
    end
    AUTO_CAST(gauge)
    local pct = stat.HP * 100 / stat.maxHP
    local color, status = "#FFFFFF", ""
    local is_set = AK_vk_is_set()
    -- 🔑 조건은 세 갈래다(사용자 정정, 2026-08-20):
    --   완벽 : 완벽함 수치 >= 1  그리고 HP 100%
    --   복수 : 바카리네 **5세트**  그리고 HP <= 45%  ← 세트 자체가 조건이라 수치를 보지 않는다
    --   복수 : 5세트 **미만** + 복수 수치 >= 1  그리고 HP <= 35%
    -- ⚠️ 5세트일 때도 복수 수치를 요구하던 것이 틀렸다. 두 경우는 임계선도 다르다
    -- 🔑 three cases; the 5-piece set does not need a revenge value of its own, and the two
    -- revenge cases use different HP thresholds
    if pct >= 100 and AK_vk_perfection() >= AK_VK_OPT_MIN then
        color, status = "#00EC00", AK_t("hp_perfect")
    elseif is_set and pct <= AK_VK_HP_SET * 100 then
        color, status = "#EA0000", AK_t("hp_revenge")
    elseif not is_set and AK_vk_revenge() >= AK_VK_OPT_MIN and pct <= AK_VK_HP_PLAIN * 100 then
        color, status = "#EA0000", AK_t("hp_revenge")
    end
    AK_vk_hp_text(base, "ak_vk_status", gauge, AK_VK_STATUS_DY,
        string.format("{ol}%s{%s}%s", AK_VK_STATUS_SIZE, color, status))
    AK_vk_hp_text(base, "ak_vk_hp", gauge, AK_VK_HP_DY,
        string.format("{ol}%s{%s}%d%%", AK_VK_HP_SIZE, color, pct))
end

-- 체력이 움직이는 순간을 받는 주 경로. 원본도 이 세 메시지를 썼고, 원본이 무거웠던 이유는
-- 메시지가 아니라 **그 안에서 착용 장비의 랜덤옵션을 전부 훑었기** 때문이다. 그 스캔이
-- 캐시로 빠진 지금은 info.GetStat 한 번 + 글자 두 줄이라 비용이 거의 없다.
-- 그래도 도트힐·다중 피격으로 초당 수십 번 올 수 있으므로 0.05초(초당 20회) 상한을 둔다
-- the same three messages the original used: what made it heavy was the equipment scan inside,
-- not the messages themselves. still capped at 20/s
function AK_VK_HP_MSG()
    if not g.settings or g.settings.vk.hp_overlay ~= 1 then
        return
    end
    if AK_throttled("vk_hp", 0.05) then
        return
    end
    AK_vk_hp_refresh()
end

-- 안전 타이머. 메시지가 메꾸지 못하는 경우를 받는다: 상한에 걸려 연타의 마지막 갱신을
-- 건너뛴 직후, 그리고 피격 없이 최대 체력만 조용히 바뀐 경우.
-- 다른 네 기능과 같은 "메시지 + 안전 타이머" 구조다
-- safety tick for what the messages miss: a burst's last update lost to the cap, and a max HP
-- change with no damage event. same message+timer shape as the other four features
function AK_vk_hp_tick(frame)
    if not g.settings or g.settings.vk.hp_overlay ~= 1 then
        frame:StopUpdateScript("AK_vk_hp_tick")
        AK_vk_hp_clear()
        return 0
    end
    AK_vk_hp_refresh()
    return 1
end

function AK_vk_hp_watch_start()
    if not g.frame or not g.settings then
        return
    end
    g.frame:StopUpdateScript("AK_vk_hp_tick")
    if g.settings.vk.hp_overlay == 1 then
        g.frame:RunUpdateScript("AK_vk_hp_tick", 0.5)
    else
        AK_vk_hp_clear()
    end
end

-- nexus 쪽이 켜져 있으면 알린다. 남의 설정 파일은 읽기만 하고 건드리지 않는다
-- warn when the nexus copy is still enabled; its settings file is only read, never written
function AK_vk_nexus_warn()
    if g.vk_warned then
        return
    end
    g.vk_warned = true
    local s = AK_load_json(string.format("../addons/%s/%s/settings.json", AK_NEXUS_DIR, g.active_id))
    if s and type(s.vakarine_equip) == "table" and s.vakarine_equip.use == 1 then
        CHAT_SYSTEM(AK_t("vk_nexus"))
    end
end

-- ============================================================
-- HUD
-- ============================================================
-- 바카리네만 계정 공통 키가 아니라 캐릭터별 자동 실행 상태를 쓴다
-- the Vakarine icon reflects a per-character flag rather than an account-wide key
local function AK_feature_on(key)
    if key == "vakarine" then
        return AK_vk_auto_on()
    end
    return AK_on(key)
end

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
            if AK_feature_on(f.key) then
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

-- 설정창이 둘(수리 / 바카리네)이므로 둘 다 훑는다. 콜백은 어느 창이 요청했는지 모른다
-- there are two settings windows now and the callback does not say which one asked
function AK_credit_emblem_loaded(code)
    if code ~= 200 then
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
    for _, name in ipairs({addonNameLower .. "_repair_cfg", addonNameLower .. "_vk_cfg"}) do
        local frame = ui.GetFrame(name)
        local emblem = frame and GET_CHILD(frame, "credit_emblem") or nil
        if emblem then
            AUTO_CAST(emblem)
            emblem:SetImage("")
            emblem:SetFileName(image_name)
        end
    end
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

-- ============================================================
-- 바카리네 설정창 + 우클릭 미니 팝업
--   테마 §14: 읽어야 하는 것(부위 목록 행)에는 한 단계 진한 상자를 깐다.
--   켜진 행 = blackbox_op_80 + 흰 글씨 / 꺼진 행 = blackbox_op_50 + 회색 글씨 —
--   탭의 활성/비활성 규칙(§4)과 같은 대비이면서, 꺼진 행도 진한 바탕 위라 계속 읽힌다
--   lit rows use the darker box, unlit rows the lighter one: both stay legible over the
--   translucent window, which plain text on the window itself does not
-- ============================================================
local AK_VK_CFG = addonNameLower .. "_vk_cfg"
local AK_VK_MENU = addonNameLower .. "_vk_menu"
local AK_VK_W = 340
local AK_VK_H = 430
local AK_VK_PAD = 14
local AK_VK_SROW = 26                       -- 부위 목록 행 높이 / slot row height
local AK_VK_LIST_Y = 208
local AK_VK_COL_W = 153
local AK_VK_LEFT_ROWS = 7                   -- 왼쪽 열에 7개, 나머지 6개는 오른쪽 열
local AK_VK_MENU_W = 170
local AK_VK_MENU_ROW = 28

local function AK_vk_slot_name(slot)
    local ok, name = pcall(ClMsg, slot.clmsg)
    if not ok or name == nil or name == "" or name == "None" then
        return slot.key
    end
    return name
end

function AK_vk_cfg_visual()
    local frame = ui.GetFrame(AK_VK_CFG)
    local c = AK_vk_char()
    if not frame or not c then
        return
    end
    local all_on = true
    for _, slot in ipairs(AK_VK_SLOTS) do
        local on = c.slots[slot.key] == 1
        if not on then
            all_on = false
        end
        local row = GET_CHILD(frame, "vk_row_" .. slot.key)
        if row then
            AUTO_CAST(row)
            row:SetSkinName(on and AK_SKIN_FIELD or AK_SKIN_PANEL)
        end
        local txt = GET_CHILD(frame, "vk_txt_" .. slot.key)
        if txt then
            AUTO_CAST(txt)
            txt:SetText(string.format("{ol}{s13}%s%s", on and "" or "{#999999}",
                AK_vk_slot_name(slot)))
        end
    end
    local states = {auto = c.auto == 1, jsr = g.settings.vk.jsr == 1,
                    hp = g.settings.vk.hp_overlay == 1, all = all_on}
    for key, on in pairs(states) do
        local icon = GET_CHILD(frame, "vk_t_" .. key)
        if icon then
            AUTO_CAST(icon)
            icon:SetImage(on and "ability_on" or "ability_off")
            icon:Resize(51, 22)          -- SetImage 가 크기를 되돌린다(테마 §11)
        end
    end
end

function AK_vk_cfg_close()
    local frame = ui.GetFrame(AK_VK_CFG)
    if frame then
        frame:ShowWindow(0)
    end
end

function AK_vk_cfg_toggle(frame, ctrl)
    local c = AK_vk_char()
    if not ctrl or not c then
        return
    end
    local key = ctrl:GetUserValue("AK_VK_T")
    if key == "auto" then
        c.auto = (c.auto == 1) and 0 or 1
        AK_hud_set_visual()
    elseif key == "jsr" then
        g.settings.vk.jsr = (g.settings.vk.jsr == 1) and 0 or 1
    elseif key == "hp" then
        g.settings.vk.hp_overlay = (g.settings.vk.hp_overlay == 1) and 0 or 1
        AK_vk_hp_watch_start()
    elseif key == "all" then
        local target = 0
        for _, slot in ipairs(AK_VK_SLOTS) do
            if c.slots[slot.key] ~= 1 then
                target = 1
                break
            end
        end
        for _, slot in ipairs(AK_VK_SLOTS) do
            c.slots[slot.key] = target
        end
    else
        return
    end
    AK_save_settings()
    AK_vk_cfg_visual()
end

-- ⚠️ 원본은 체크 하나를 누를 때마다 설정창을 통째로 다시 그렸다(그래서 창 위치가 튀었고
-- 위치를 따로 저장해야 했다). 여기서는 상태만 다시 칠한다
-- ⚠️ the original rebuilt the whole window on every tick, which is why it kept jumping back
-- 어느 부위인지는 컨트롤에 붙여 둔 UserValue 로 받는다. groupbox 에 ArgString 을 거는 선례는
-- 클라에 없고(ArgNumber 뿐이다), cupole 의 클릭 셀도 UserValue 방식이라 그쪽을 따른다
-- the client only has SetEventScriptArgNumber on a groupbox, so the slot key rides a UserValue
function AK_vk_cfg_slot(frame, ctrl)
    local c = AK_vk_char()
    local slot_key = ctrl and ctrl:GetUserValue("AK_VK_SLOT") or nil
    if not c or slot_key == nil or c.slots[slot_key] == nil then
        return
    end
    c.slots[slot_key] = (c.slots[slot_key] == 1) and 0 or 1
    -- 보조무기 두 칸은 함께 움직인다(원본과 동일) / the two sub-weapon slots move together
    if slot_key == "RH_SUB" then
        c.slots.LH_SUB = c.slots.RH_SUB
    elseif slot_key == "LH_SUB" then
        c.slots.RH_SUB = c.slots.LH_SUB
    end
    AK_save_settings()
    AK_vk_cfg_visual()
end

local function AK_vk_cfg_toggle_icon(frame, key, y, tip)
    local icon = frame:CreateOrGetControl("picture", "vk_t_" .. key, 51, 22, ui.RIGHT, ui.TOP, 0, y,
        AK_VK_PAD + 10, 0)
    AUTO_CAST(icon)
    icon:SetEnableStretch(1)
    icon:EnableHitTest(1)
    icon:SetUserValue("AK_VK_T", key)
    if tip then
        icon:SetTextTooltip(tip)
    end
    AK_hover(icon)
    icon:SetEventScript(ui.LBUTTONUP, "AK_vk_cfg_toggle")
    return icon
end

local function AK_vk_cfg_label(frame, name, x, y, w, text, tip)
    local ctrl = frame:CreateOrGetControl("richtext", name, x, y, w, 22)
    AUTO_CAST(ctrl)
    ctrl:SetText(text)
    ctrl:EnableHitTest(false)
    if tip then
        ctrl:SetTextTooltip(tip)
    end
    return ctrl
end

function AK_vk_cfg_open()
    if not g.settings or not AK_vk_char() then
        return
    end
    local frame = ui.GetFrame(AK_VK_CFG)
    if frame and frame:IsVisible() == 1 then
        frame:ShowWindow(0)
        return
    end
    if not frame then
        frame = ui.CreateNewFrame("notice_on_pc", AK_VK_CFG, 0, 0, 0, 0)
        AUTO_CAST(frame)
        frame:SetPos((ui.GetClientInitialWidth() - AK_VK_W) / 2,
            (ui.GetClientInitialHeight() - AK_VK_H) / 2)
    end
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    frame:Resize(AK_VK_W, AK_VK_H)
    frame:SetSkinName(AK_UI_SKIN)
    frame:SetAlpha(AK_UI_ALPHA)
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(92)
    frame:EnableHittestFrame(1)
    frame:EnableMove(1)

    AK_vk_cfg_label(frame, "title", AK_VK_PAD + 2, 10, 260, "{ol}{s18}{b}" .. AK_t("vk_title"))
    local close = frame:CreateOrGetControl("picture", "close", 28, 28, ui.RIGHT, ui.TOP, 0, 10,
        AK_VK_PAD, 0)
    AUTO_CAST(close)
    close:SetImage("testclose_button")
    close:SetEnableStretch(1)
    close:Resize(28, 28)
    close:SetMargin(0, 10, AK_VK_PAD, 0)
    close:EnableHitTest(1)
    AK_hover(close)
    close:SetEventScript(ui.LBUTTONUP, "AK_vk_cfg_close")

    local line = frame:CreateOrGetControl("labelline", "title_line", AK_VK_PAD, 44,
        AK_VK_W - AK_VK_PAD * 2, 3)
    AUTO_CAST(line)
    line:SetSkinName("labelline2")

    -- 동작 / behaviour
    local sec1 = AK_vk_cfg_label(frame, "sec1", AK_VK_PAD, 54, 200, "{ol}{s14}" .. AK_t("vk_sec_run"))
    sec1:SetFontName("white_16_ol")
    local panel = frame:CreateOrGetControl("groupbox", "panel", AK_VK_PAD, 78,
        AK_VK_W - AK_VK_PAD * 2, 98)
    AUTO_CAST(panel)
    panel:SetSkinName(AK_SKIN_PANEL)
    panel:EnableScrollBar(0)
    panel:EnableHittestGroupBox(false)

    local rows = {{key = "auto", label = "vk_auto", tip = "vk_auto_tip"},
                  {key = "jsr", label = "vk_jsr", tip = "vk_jsr_tip"},
                  {key = "hp", label = "vk_hp", tip = "vk_hp_tip"}}
    for i, row in ipairs(rows) do
        local y = 84 + (i - 1) * 30
        AK_vk_cfg_label(frame, "lbl_" .. row.key, AK_VK_PAD + 10, y, 210,
            "{ol}{s13}" .. AK_t(row.label), AK_t(row.tip))
        AK_vk_cfg_toggle_icon(frame, row.key, y, AK_t(row.tip))
    end

    -- 탈착할 장비 / gear list
    local sec2 = AK_vk_cfg_label(frame, "sec2", AK_VK_PAD, 184, 200,
        "{ol}{s14}" .. AK_t("vk_sec_slots"))
    sec2:SetFontName("white_16_ol")
    AK_vk_cfg_toggle_icon(frame, "all", 182, "{ol}" .. AK_t("vk_all"))

    for i, slot in ipairs(AK_VK_SLOTS) do
        local col, idx = 0, i - 1
        if i > AK_VK_LEFT_ROWS then
            col, idx = 1, i - AK_VK_LEFT_ROWS - 1
        end
        local x = AK_VK_PAD + col * (AK_VK_COL_W + 6)
        local y = AK_VK_LIST_Y + idx * AK_VK_SROW
        local row = frame:CreateOrGetControl("groupbox", "vk_row_" .. slot.key, x, y,
            AK_VK_COL_W, AK_VK_SROW - 3)
        AUTO_CAST(row)
        row:EnableScrollBar(0)
        row:EnableHittestGroupBox(true)
        row:SetTextTooltip(AK_t("vk_slot_tip"))
        row:SetUserValue("AK_VK_SLOT", slot.key)
        row:SetEventScript(ui.LBUTTONUP, "AK_vk_cfg_slot")
        -- 글자는 형제로 두고 히트테스트를 끈다 → 클릭은 아래의 groupbox 가 받는다
        -- the label is a sibling with hit test off, so clicks fall through to the row box
        AK_vk_cfg_label(frame, "vk_txt_" .. slot.key, x + 10, y + 2, AK_VK_COL_W - 14, "")
    end

    pcall(AK_credit_render, frame, AK_VK_W, AK_VK_H - 30, AK_VK_PAD)
    AK_vk_cfg_visual()
    frame:ShowWindow(1)
end

-- 우클릭 미니 팝업. 게임 컨텍스트 메뉴는 스킨을 바꿀 수 없어 테마와 안 맞아 직접 그린다.
-- 방치되면 알아서 사라지도록 SetDuration 을 쓴다(클라 선례: chat_emoticon.lua:54)
-- a hand-drawn menu (the game context menu cannot be reskinned); SetDuration retires it if ignored
function AK_vk_menu_close()
    local frame = ui.GetFrame(AK_VK_MENU)
    if frame then
        frame:ShowWindow(0)
    end
end

function AK_vk_menu_auto()
    local c = AK_vk_char()
    AK_vk_menu_close()
    if not c then
        return
    end
    c.auto = (c.auto == 1) and 0 or 1
    AK_save_settings()
    AK_hud_set_visual()
    AK_vk_cfg_visual()
    CHAT_SYSTEM(string.format("[Auto Keeper] %s : %s", AK_t("vk_auto"),
        c.auto == 1 and AK_t("on") or AK_t("off")))
end

function AK_vk_menu_cfg()
    AK_vk_menu_close()
    AK_vk_cfg_open()
end

local function AK_vk_menu_row(frame, name, y, text, handler)
    local box = frame:CreateOrGetControl("groupbox", name .. "_bg", 6, y, AK_VK_MENU_W - 12,
        AK_VK_MENU_ROW - 3)
    AUTO_CAST(box)
    box:EnableScrollBar(0)
    box:EnableHittestGroupBox(true)
    -- 마우스를 올리면 더 투명해진다 = 지금 고르고 있는 행
    AK_skin_hover(box, AK_SKIN_PANEL, AK_SKIN_HOVER_ROW)
    box:SetEventScript(ui.LBUTTONUP, handler)
    local txt = frame:CreateOrGetControl("richtext", name, 16, y + 3, AK_VK_MENU_W - 26, 20)
    AUTO_CAST(txt)
    txt:SetText(text)
    txt:EnableHitTest(false)
end

function AK_vk_menu_open(icon)
    local c = AK_vk_char()
    if not c or not icon then
        return
    end
    local frame = ui.GetFrame(AK_VK_MENU)
    if frame and frame:IsVisible() == 1 then
        frame:ShowWindow(0)
        return
    end
    if not frame then
        frame = ui.CreateNewFrame("notice_on_pc", AK_VK_MENU, 0, 0, 0, 0)
    end
    AUTO_CAST(frame)
    frame:RemoveAllChild()
    local h = AK_VK_MENU_ROW * 2 + 12
    frame:Resize(AK_VK_MENU_W, h)
    frame:SetSkinName(AK_UI_SKIN)
    frame:SetAlpha(AK_UI_ALPHA)
    frame:SetTitleBarSkin("None")
    frame:SetLayerLevel(95)
    frame:EnableHittestFrame(1)
    frame:EnableMove(0)
    -- 아이콘 바로 아래에 붙인다. GetGlobalX/Y 를 못 읽는 환경이면 HUD 바 좌표로 대신한다
    -- anchored under the icon, falling back to the HUD bar position
    local ok, gx, gy = pcall(function() return icon:GetGlobalX(), icon:GetGlobalY() end)
    if ok and gx ~= nil and gy ~= nil then
        frame:SetPos(math.max(0, gx - (AK_VK_MENU_W - AK_ICON) / 2), gy + AK_ICON + 4)
    else
        frame:SetPos(g.settings.hud_x, g.settings.hud_y + AK_HUD_H + 4)
    end

    AK_vk_menu_row(frame, "menu_auto", 6, string.format("{ol}{s13}%s : %s", AK_t("vk_auto"),
        c.auto == 1 and AK_t("on") or AK_t("off")), "AK_vk_menu_auto")
    AK_vk_menu_row(frame, "menu_cfg", 6 + AK_VK_MENU_ROW, "{ol}{s13}" .. AK_t("vk_menu_cfg"),
        "AK_vk_menu_cfg")

    frame:ShowWindow(1)
    frame:SetDuration(6)
end

function AK_hud_rclick(frame, ctrl)
    if not ctrl then
        return
    end
    local key = ctrl:GetUserValue("AK_KEY")
    if key == "repair" then
        AK_cfg_open()
    elseif key == "vakarine" then
        AK_vk_menu_open(ctrl)
    end
end

function AK_hud_drag(frame)
    if not frame or not g.settings then
        return
    end
    -- 바가 움직이면 아이콘에 붙어 있던 팝업은 자리를 잃는다 / the popup is anchored to the icon
    AK_vk_menu_close()
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
        -- 🔑 바카리네만 좌클릭이 on/off 토글이 아니라 "지금 실행"이다. 켜고 끄는 것(자동 실행)은
        -- 우클릭 팝업으로 간다 / the Vakarine icon runs the swap instead of toggling
        icon:SetEventScript(ui.LBUTTONUP, f.manual and "AK_vk_manual" or "AK_hud_toggle")
        -- 수리와 바카리네가 우클릭을 쓴다 / repair and Vakarine both use right click
        if f.key == "repair" or f.manual then
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

-- 진단용 `/keeper vk`. 자동 실행이 안 도는 이유는 셋 중 하나다: 캐릭터 설정이 꺼졌거나,
-- 바카리네 5세트가 아니거나, 맵이 대상이 아니거나. 세 판정을 그대로 찍는다
-- diagnostic: the three gates the auto run has to pass, printed as-is
function AK_dump_vk()
    g.vk_dirty = true          -- 진단은 캐시를 믿지 않고 지금 다시 잰다 / always re-measure
    local c = AK_vk_char()
    local picked = 0
    if c then
        for _, slot in ipairs(AK_VK_SLOTS) do
            if c.slots[slot.key] == 1 then
                picked = picked + 1
            end
        end
    end
    local map_type, keyword = AK_vk_map_type()
    CHAT_SYSTEM(string.format(
        "[Auto Keeper] auto %s | set %s | map %s(%s) ok %s | slots %d | jsr %s | 완벽함 %s / 복수 %s",
        tostring(c ~= nil and c.auto == 1), tostring(AK_vk_is_set()), tostring(map_type),
        tostring(keyword), tostring(AK_vk_map_ok()), picked, tostring(g.settings.vk.jsr == 1),
        tostring(AK_vk_perfection()), tostring(AK_vk_revenge())))
end

-- 진단용 /keeper opt. 스탯창이 보여주는 특수 옵션 수치(완벽함·복수)를 찍고,
-- 이어서 착용 장비에 붙은 바카리네 랜덤옵션 문자열을 그대로 찍는다.
-- 체력바 표시가 안 뜨는 이유는 대개 "그 옵션 수치가 0" 이다
-- prints the special option totals the status window shows, then the raw option strings
function AK_dump_opt()
    g.vk_dirty = true          -- 진단은 캐시를 믿지 않고 지금 다시 잰다 / always re-measure
    CHAT_SYSTEM(string.format("[AK opt] %s=%s  %s=%s  (0 이면 그 표시는 뜨지 않습니다)",
        AK_VK_OPT_PERFECTION, tostring(AK_vk_perfection()),
        AK_VK_OPT_REVENGE, tostring(AK_vk_revenge())))
    local list = session.GetEquipItemList()
    if not list then
        CHAT_SYSTEM("[Auto Keeper] 장비 목록을 읽을 수 없습니다.")
        return
    end
    local guids = list:GetGuidList()
    local shown = 0
    for i = 0, guids:Count() - 1 do
        local guid = guids:Get(i)
        if guid ~= "0" then
            local equip = list:GetItemByGuid(guid)
            local obj = equip and GetIES(equip:GetObject())
            if obj then
                local found = {}
                for j = 1, MAX_OPTION_EXTRACT_COUNT do
                    local raw = obj["RandomOption_" .. j]
                    if raw ~= nil and raw ~= "" and raw ~= "None" then
                        local ok, msg = pcall(ScpArgMsg, raw)
                        local out = (ok and msg) or "?"
                        -- Vakarine / vakarine / bakarine 을 한 번에 잡는다
                        if string.find(tostring(raw), "akarine") ~= nil or
                            string.find(tostring(out), "akarine") ~= nil then
                            table.insert(found, string.format("%s -> %s", tostring(raw), tostring(out)))
                        end
                    end
                end
                if #found > 0 then
                    shown = shown + 1
                    CHAT_SYSTEM(string.format("[AK opt] %s : %s", tostring(obj.Name or "?"),
                        table.concat(found, " | ")))
                end
            end
        end
    end
    if shown == 0 then
        CHAT_SYSTEM("[Auto Keeper] 바카리네 옵션이 붙은 착용 장비를 찾지 못했습니다.")
    end
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
    if command ~= nil and command[1] == "vk" then
        AK_dump_vk()
        return
    end
    if command ~= nil and command[1] == "opt" then
        AK_dump_opt()
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
    -- 바카리네 설정은 캐릭터별이다. json 키는 문자열이므로 여기서 문자열로 맞춰 둔다
    -- per-character settings key; json object keys are strings, so normalise it here
    local ok_cid, cid = pcall(function() return session.GetMySession():GetCID() end)
    g.cid = (ok_cid and cid ~= nil) and tostring(cid) or nil
    g.vk_dirty = true
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
        -- 체력바 오버레이는 체력이 움직이는 순간에 바로 갱신한다(§5). 원본과 같은 세 메시지지만
        -- 안에서 장비를 훑지 않으므로 비용이 다르다
        -- the HP overlay refreshes the moment HP moves; unlike the original, no scan inside
        g.addon:RegisterMsg("STAT_UPDATE", "AK_VK_HP_MSG")
        g.addon:RegisterMsg("TAKE_DAMAGE", "AK_VK_HP_MSG")
        g.addon:RegisterMsg("TAKE_HEAL", "AK_VK_HP_MSG")
        -- durnotify 가 구독하는 것과 같은 원본 메시지들(durnotify.lua:4-7).
        -- 게임 알림창을 훅하지 않으므로 그 UI 는 그대로 살아 있다
        -- the same sources durnotify subscribes to; its UI stays intact because we never hook it
        g.addon:RegisterMsg("UPDATE_ITEM_REPAIR", "AK_DUR_CHECK")
        g.addon:RegisterMsg("ITEM_PROP_UPDATE", "AK_DUR_CHECK")
        g.addon:RegisterMsg("EQUIP_ITEM_LIST_GET", "AK_DUR_CHECK")
        -- 아이커 교체 계열. 이름은 goddess_equip_manager / icoradd_multiple /
        -- icorrelease_multiple 이 실제로 구독하는 것과 같다
        -- the same names the client's own icor windows subscribe to
        g.addon:RegisterMsg("MSG_SUCCESS_ICOR_PRESET_ENGRAVE_APPLY", "AK_VK_OPT_DIRTY")
        g.addon:RegisterMsg("MSG_SUCCESS_ICOR_ADD_MULTIPLE", "AK_VK_OPT_DIRTY")
        g.addon:RegisterMsg("MSG_SUCCESS_ICOR_RELEASE_MULTIPLE", "AK_VK_OPT_DIRTY")
        g.addon:RegisterMsg("MSG_SUCCESS_ICOR_RELEASE_RANDOM_MULTIPLE", "AK_VK_OPT_DIRTY")
        g.addon:RegisterMsg("MSG_GODDESS_SOCKET_UPDATE", "AK_VK_OPT_DIRTY")
        -- HUD 가 TP 상점 때문에 닫혔을 때 되살리는 보조 경로 (ESC 로 닫는 경우) +
        -- ESC 로 바카리네 팝업 닫기. 한 메시지에 핸들러 하나만 걸어 중복 등록을 피한다
        -- restores the HUD after the TP shop closed it, and closes the Vakarine popup
        g.addon:RegisterMsg("ESCAPE_PRESSED", "AK_ESCAPE")
    end

    AK_hud_create()
    AK_relic_watch_start()
    AK_sta_watch_start()
    AK_potion_watch_start()
    AK_repair_watch_start()
    AK_vk_hp_watch_start()
    AK_vk_nexus_warn()

    -- 바카리네 자동 실행: 지금(GAME_START_3SEC)부터 시도하고, 장비 목록이 오는 즉시 실행한다
    -- start trying right now, and go the moment the equip list is there
    g.vk_auto_try = 0
    g.frame:StopUpdateScript("AK_vk_auto_tick")
    g.frame:RunUpdateScript("AK_vk_auto_tick", AK_VK_AUTO_GAP)

    g.frame:StopUpdateScript("AK_hud_guard_tick")
    g.frame:RunUpdateScript("AK_hud_guard_tick", 2.0)

    g.frame:StopUpdateScript("AK_ready_on")
    g.frame:RunUpdateScript("AK_ready_on", 5.0)
    CHAT_SYSTEM(AK_t("loaded"))
end

function AK_ESCAPE()
    AK_vk_menu_close()
    AK_hud_guard()
end

-- ⚠️ 여기서 바카리네 자동 실행을 부르던 것을 뺐다. 이 유예(5초)는 **스태미나**가 로딩 중
-- 잘못 읽히는 것을 막으려는 것이지 장비와는 무관한데, 그대로 얹는 바람에
-- GAME_START_3SEC(3초) + 5초 = 약 8초가 되어 원본보다 눈에 띄게 느려졌다.
-- 지금은 AK_vk_auto_tick 이 3초 시점부터 장비 목록을 보고 준비되는 즉시 실행한다
-- ⚠️ the auto run used to hang off this 5s grace, which exists for stamina, not equipment -
-- that made it ~8s after map entry. it now starts as soon as the equip list is actually there
function AK_ready_on(frame)
    g.ready = true
    frame:StopUpdateScript("AK_ready_on")
    -- 탈착 때 애니무스로 바꿔 끼우지 못했으면 도시에서 다시 시도한다(원본과 같은 자리)
    if g.vk_animus and AK_vk_map_type() == "City" then
        g.frame:StopUpdateScript("AK_vk_animus_tick")
        g.frame:RunUpdateScript("AK_vk_animus_tick", 1.0)
    end
    return 0
end
