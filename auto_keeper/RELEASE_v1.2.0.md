# Auto Keeper v1.2.0

> 스태미나 · 물약 버프 해제 · 성물 충전 · 장비 수리 · 바카리네 장비 탈착을 하나로 묶은 자동 관리 애드온입니다.
> 설정은 화면의 HUD 아이콘에서, 진단은 `/keeper` 로 볼 수 있습니다.

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.2.0)

#### 🔴 장비 자동 수리 — Lv.560 장비가 안 고쳐지던 문제

EP18.2의 **Lv.560 긴급 수리 키트(사울레 인증서)** 를 지원합니다.

수리 키트는 **자기 상한 이하의 장비만** 고칠 수 있습니다. 그런데 예전에는 그 상한을 보지 않고
가진 키트를 그냥 집었습니다. 그래서 이런 일이 생겼습니다:

- Lv.550 키트를 39개 가지고 있음 → "부족하지 않다" 고 판단 → **Lv.560 키트를 사지 않음**
- 그 550 키트로 Lv.560 장비를 고치려 시도 → 내구도가 안 오름 → 세 번 만에 자동 수리 정지
- 결과: **장비가 완전히 부서졌는데도 마을에서조차 수리하지 않음**

이제 **수리할 장비의 레벨(UseLv)** 을 보고 상한이 맞는 키트만 고르며, 모자라면 **항상 최신
키트를 구매**합니다. 가방에 옛 550 키트가 남아 있어도 Lv.550 이하 장비에는 그대로 씁니다.

#### 안내가 없어 원인을 알 수 없던 문제

- **자동 구매가 꺼져 있어** 사지 않은 경우, 예전에는 아무 말 없이 끝났습니다 → 이제 이유를 알려줍니다.
- **"수리 도구가 없습니다"** 안내가 세션 중 **한 번만** 나오고 그 뒤로 영영 조용했습니다
  (모든 장비가 기준선 위로 올라가야 다시 풀렸습니다) → **1분마다** 다시 알립니다.
- 진단 명령 **`/keeper dur`** 이 어느 키트를 쓰는지(상한 포함)와 필요한 장비 레벨까지 보여줍니다.

#### 구매 수량 설정의 의미

**"한 번에 사는 개수"** 로 동작합니다. 50으로 두면 50장을 삽니다.
예전에는 상한으로만 써서 그때 필요한 3~4장만 샀습니다.

#### 물약 회복 버프 자동 해제 — 바카리네 5세트 조건 추가

**바카리네 축복 5세트를 착용했을 때만** 동작합니다. 이 기능이 필요한 이유가 5세트의 회복 관련
옵션이라, 세트가 아닐 때 해제하면 그냥 회복 버프를 버리는 셈이기 때문입니다.

### 설치 방법
- 기존 auto_keeper ipf 파일을 삭제하고 이 파일을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.2.0)

#### 🔴 Auto repair — Lv.560 gear was never repaired

Adds support for the **Lv.560 emergency repair kit (Saule certificate)** from EP18.2.

A repair kit can only fix gear **up to its own level cap**, but the addon used to grab whatever kit
you were holding without checking that cap:

- Holding 39 Lv.550 kits looked like "enough" → **no Lv.560 kit was ever bought**
- Those kits cannot repair Lv.560 gear → durability never moved → auto repair stopped after three tries
- Result: **gear at 0% stayed broken, even in town**

It now picks a kit by the **level of the gear being repaired (UseLv)** and always buys the newest
kit when short. Old Lv.550 kits already in your bag are still used for Lv.550-and-below gear.

#### Silence that hid the cause

- When **auto-buy is off**, nothing was bought and nothing was said → it now tells you why.
- The **"no repair kit"** notice fired **once per session** and then stayed silent (it only reset
  once every item was back above the line) → it now repeats **once a minute**.
- **`/keeper dur`** now also shows which kit is in use (with its cap) and the gear level required.

#### What the buy quantity means

It is **how many to buy at once**, not a ceiling. Set it to 50 and it buys 50.
Previously it was treated only as a cap, so it bought just the 3-4 needed at that moment.

#### Potion heal-buff removal now requires the Vakarine 5-set

It only runs while the **Vakarine blessing 5-set** is worn. That set is the reason the feature
exists - without it you would just be throwing heals away.

### How to Install
- Remove your old auto_keeper ipf file, then add this one.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.2.0)

#### 🔴 装備の自動修理 — Lv.560装備が直らない問題

EP18.2の**Lv.560緊急修理キット(サウレ認証書)**に対応しました。

修理キットは**自分の上限以下の装備しか**直せませんが、以前はその上限を見ずに手持ちのキットを
そのまま使っていました:

- Lv.550キットを39個所持 → 「足りている」と判断 → **Lv.560キットを購入しない**
- そのキットではLv.560装備が直らない → 耐久度が動かない → 3回で自動修理が停止
- 結果: **装備が完全に壊れても、町でさえ修理しない**

今は**修理する装備のレベル(UseLv)**を見て上限の合うキットを選び、足りない場合は**常に最新の
キットを購入**します。鞄に残った古いLv.550キットもLv.550以下の装備にはそのまま使います。

#### 原因が分からなかった「無言」の問題

- **自動購入がオフ**で購入しなかった場合、以前は何も言わずに終わっていました → 理由をお知らせします。
- **「修理道具がありません」**の通知がセッション中**一度だけ**出てその後は無言でした
  (全装備が基準線を超えないと解除されませんでした) → **1分ごと**に再通知します。
- 診断コマンド **`/keeper dur`** が使用中のキット(上限付き)と必要な装備レベルも表示します。

#### 購入数量設定の意味

**「一度に購入する個数」**として動作します。50に設定すれば50個購入します。
以前は上限としてのみ扱われ、その時必要な3~4個しか購入しませんでした。

#### ポーション回復バフの自動解除にバカリネ5セット条件を追加

**バカリネの祝福5セット**を着用しているときのみ動作します。この機能が必要な理由が5セットの
回復関連オプションであり、セットでないときに解除すると回復バフを捨てるだけになるためです。

### インストール方法
- 古い auto_keeper の ipf ファイルを削除して、このファイルを入れてください。
- または addon manager から update してください。
