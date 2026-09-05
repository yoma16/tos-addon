# New Nexus Addons v1.1.4

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.4) — 입장권 사용 순서

#### Indun Panel — 챌린지·분열 입장권이 적어 둔 순서대로 사용됩니다

**거래불가 입장권을 가지고 있어도 그것부터 쓰지 않는** 문제가 있었습니다. 원인이 둘이었습니다.

**① 무기한 입장권은 목록의 "마지막" 것이 쓰였습니다.** 목록을 훑으면서 고른 것을 계속
덮어쓰고 있었기 때문에, 앞에 적어 둔 거래불가가 뒤에 적힌 거래가능으로 밀렸습니다.
그 결과 **Lv.540과 Lv.560이 서로 반대로** 동작했습니다.

**② 기간제 입장권은 무엇이 뽑힐지 알 수 없었습니다.** 정렬 기준이 "남은 시간이 하루 미만인가"
하나뿐이라 사실상 전부 동점이었고(1일권은 남은 시간이 **정확히 86400초**라 하루 미만으로
잡히지 않습니다), Lua의 `table.sort`는 동점 순서를 보장하지 않습니다.

입장권 목록을 **기간제 / 거래불가 / 거래가능** 셋으로 나누고, 동점일 때는 목록에 적힌 순서를
따르도록 고쳤습니다.

**사용 순서**

1. **기간제** — 놔두면 사라집니다 (남은 시간이 짧은 것부터)
2. **거래불가 무기한** — 팔 수 없으니 아껴도 소용없습니다 → **구매보다 먼저**
3. Lv.540은 여기서 **거래가능 무기한**까지 씁니다 (지난 등급이라 아낄 이유가 없습니다)
4. **구매** (TOS 주화 / PvP 광산)
5. Lv.560은 **못 샀을 때만** 거래가능 무기한을 꺼냅니다

챌린지 Lv.540 · Lv.560, 분열 Lv.540 · Lv.560 네 버튼 모두에 적용됩니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.1.4) — ticket use order

#### Indun Panel — challenge and singularity tickets follow the order they are written in

A permanent **untradeable** ticket in your inventory was not spent first. Two causes.

**① For permanent tickets the LAST id in the list won.** The loop kept overwriting its pick as it
scanned, so an untradeable ticket written first was replaced by the tradeable one written after it.
That made **Lv.540 and Lv.560 behave in opposite ways**.

**② For time-limited tickets the choice was undefined.** The only sort key was "is less than a day
left", which ties for nearly every ticket — a 1-day pass has **exactly 86400 seconds** left, so it
never counts as under a day — and Lua's `table.sort` does not preserve the order of equal elements.

The lists are now split into **expiring / no_trade / tradable**, and ties break by list position.

**Order**

1. **Time-limited** — they expire if left alone (shortest remaining first)
2. **Permanent untradeable** — it cannot be sold, so there is no point saving it → **before buying**
3. Lv.540 also spends the **permanent tradeable** one here (it is the retired tier)
4. **Buy** (TOS coins / PvP mine)
5. Lv.560 only falls back to the permanent tradeable ticket **when it could not buy**

Applies to all four buttons: challenge Lv.540 / Lv.560 and singularity Lv.540 / Lv.560.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.4) — 入場券の使用順

#### Indun Panel — チャレンジ・分裂の入場券が記載した順番どおりに使われます

**取引不可の入場券を持っていてもそれから使わない**問題がありました。原因は2つです。

**① 無期限入場券はリストの「最後」のものが使われていました。** リストを走査しながら選択を
上書きしていたため、先に書いた取引不可が後に書いた取引可能に置き換えられていました。
その結果**Lv.540とLv.560が逆の動作**をしていました。

**② 期間制入場券は何が選ばれるか不定でした。** ソート基準が「残り時間が1日未満か」だけで
ほぼ全て同点になり(1日券は残り時間が**ちょうど86400秒**なので1日未満と判定されません)、
Luaの`table.sort`は同点の順序を保証しません。

入場券リストを**期間制 / 取引不可 / 取引可能**の3つに分け、同点の場合はリストの順序に従う
ように修正しました。

**使用順**

1. **期間制** — 放置すると消えます(残り時間が短いものから)
2. **無期限の取引不可** — 売れないので温存しても意味がありません → **購入より先に**
3. Lv.540はここで**無期限の取引可能**まで使います(過去の等級なので温存する理由がありません)
4. **購入** (TOS硬貨 / PvP鉱山)
5. Lv.560は**購入できなかった時だけ**無期限の取引可能を使います

チャレンジ Lv.540・Lv.560、分裂 Lv.540・Lv.560 の4ボタンすべてに適用されます。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
