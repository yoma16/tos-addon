# New Nexus Addons v1.1.3

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.3)

#### Indun Panel — 챌린지 입장권 사용 순서를 등급별로 나눴습니다

Lv.540과 Lv.560이 같은 순서를 쓰고 있었습니다. 그래서 **[Lv.540] 챌린지 모드 1회 입장권(무기한)을
가지고 있어도 TOS 주화 입장권을 사서 들어가는** 일이 있었습니다.

- **Lv.540** — 지난 던전입니다. **가지고 있는 입장권을 먼저 쓰고**, 없을 때만 TOS 주화로 구매합니다.
- **Lv.560** — 현역입니다. 구매 횟수는 기간마다 초기화되므로 **살 수 있는 동안 구매를 우선**하고,
  무기한 입장권은 아껴 둡니다. (원래 전략 그대로입니다)

구매 가능 여부를 볼 때 **등급을 구분하지 않고** Lv.540 상점(`EVENT_TOS_WHOLE_SHOP_320`)과
PvP 광산을 함께 보던 것도 고쳤습니다. Lv.560 입장이 엉뚱한 상점의 횟수로 판정되지 않습니다.

#### Quickslot Operate — 신규 우리엘 레이드 2종에서 물약이 자동 교체되지 않던 문제

**거짓된 광휘**와 **타락한 심판**에 입장할 때, 다른 레이드와 달리 퀵슬롯 물약이 바뀌지
않았습니다. 레이드 목록에 두 던전의 번호가 빠져 있었습니다.

두 보스 모두 **파라뮨(Paramune)** 종족이라 파라뮨 공격·방어 물약을 사용합니다.
자동·솔로 모두 적용됩니다.

> ℹ️ 파티(Hard)는 아직 게임 데이터에 없어서 넣지 않았습니다. 오픈되면 추가하겠습니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.1.3)

#### Indun Panel — the two challenge tiers no longer share one ticket order

Lv.540 and Lv.560 were following the same order, so you could **buy a TOS coin ticket even while
holding a permanent [Lv.540] challenge entry ticket**.

- **Lv.540** — the old tier. A ticket you already hold is **spent first**, and a TOS coin ticket is
  bought only when you have none left.
- **Lv.560** — the current tier. The shop allowance resets each period, so it **keeps buying while
  the allowance lasts** and saves your permanent tickets. (unchanged from the original strategy)

The shop-allowance check was also tier-blind: it looked at the Lv.540 shop
(`EVENT_TOS_WHOLE_SHOP_320`) and the PvP mine together, so a Lv.560 entry could be judged by the
wrong counter. That is fixed too.

#### Quickslot Operate — the two new Uriel raids did not swap potions

Entering **False Radiance** or **Fallen Judgment** did not change your quickslot potions the way
every other raid does. Their dungeon ids were simply missing from the raid table.

Both bosses are **Paramune**, so the Paramune attack and defence potions are used.
Applies to both auto and solo.

> ℹ️ The party (Hard) mode is not in the game data yet, so it is not included. It will be added
> once it opens.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.3)

#### Indun Panel — チャレンジ入場券の使用順を等級ごとに分けました

Lv.540とLv.560が同じ順序を使っていたため、**[Lv.540] チャレンジモード1回入場券(無期限)を持って
いてもTOS硬貨の入場券を購入して入場する**ことがありました。

- **Lv.540** — 過去のダンジョンです。**所持している入場券を先に使い**、無くなった時だけ
  TOS硬貨で購入します。
- **Lv.560** — 現役です。購入回数は期間ごとにリセットされるため、**購入できる間は購入を優先**し、
  無期限入場券は温存します。(元の戦略のままです)

購入可否の判定が**等級を区別せず**Lv.540の商店(`EVENT_TOS_WHOLE_SHOP_320`)とPvP鉱山を一緒に
見ていた点も修正しました。Lv.560の入場が誤った商店の回数で判定されなくなりました。

#### Quickslot Operate — 新規ウリエルレイド2種でポーションが自動交換されない問題

**偽りの光輝**と**堕落した審判**に入場する際、他のレイドと違ってクイックスロットのポーションが
交換されませんでした。レイド一覧に2つのダンジョン番号が抜けていました。

どちらのボスも**パラミュン(Paramune)**族なので、パラミュンの攻撃・防御ポーションを使用します。
オート・ソロの両方に適用されます。

> ℹ️ パーティ(Hard)はまだゲームデータに存在しないため含めていません。実装され次第追加します。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
