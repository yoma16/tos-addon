# New Nexus Addons v1.1.8

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.8) — 레이드 입장권을 기간제부터 씁니다

#### 🔴 IP — 자동매칭 · 소탕 입장권 버튼이 거래가능 티켓부터 쓰던 문제

입장권 버튼(아이콘 + 보유 수량이 붙은 그 버튼)은 지금까지 **내부 표에 먼저 적힌 것**을
썼습니다. 그런데 최근 레이드 3종은 아이템 ID **오름차순**으로 적혀 있고, 그 순서가 하필
**거래가능 → 거래불가 → 7일** 이었습니다.

| 레이드 | 표에 적힌 순서 |
|---|---|
| 즈메이 | 거래가능 → 거래불가 → 7일 🔴 |
| 거짓된 광휘 | 거래가능 → 거래불가 → 7일 🔴 |
| 타락한 심판 | 거래가능 → 거래불가 → 7일 🔴 |
| 그 밖의 레이드 | 7일 → 거래불가 → 거래가능 ✅ |

그래서 **기간제가 가방에서 그냥 만료되는 동안 거래가능 티켓을 먼저 태웠습니다.** 옛 레이드는
기간제를 앞에 적어둔 덕에 우연히 맞게 동작하고 있었습니다.

이제 **표 순서를 보지 않습니다.** 아이템 정보를 직접 읽어 고릅니다:

1. **기간제** (사용 기한이 있는 것 — 놔두면 사라지므로 가장 먼저)
2. **거래불가** (팔 수 없으니 그다음)
3. **거래가능** (팔 수 있으니 마지막)

TOS 코인 상점에서 파는 14일짜리 입장권도 기간제로 잡히고, 앞으로 레이드가 추가돼도 표에 어떤
순서로 적든 규칙이 유지됩니다.

#### 어떤 입장권을 썼는지 알려줍니다

버튼의 **보유 수량은 세 종류의 합**이라(기간제 2 + 무기한 2 = 4개) 무엇이 줄었는지 볼 수
없었습니다. 이제 사용할 때 `입장권 사용: <이름> (기간제)` 처럼 알려줍니다.

#### 보스 방향 설정창의 일본어 표시

레이어 항목의 언어 조건이 뒤집혀 있어(`~=`) **일본어가 아닌 클라이언트에서 일본어로**
표시됐습니다. 고쳤습니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.1.8) — raid tickets: expiring ones go first

#### 🔴 IP — the auto-match / sweep ticket button spent tradable tickets first

That button (the one with the ticket icon and your count on it) used to take **whichever ticket
came first in an internal table**. The three rows added for the newer raids list their item ids in
**ascending order**, which happens to be **tradable → untradeable → 7-day**.

| Raid | Table order |
|---|---|
| Zmei | tradable → untradeable → 7-day 🔴 |
| False Radiance | tradable → untradeable → 7-day 🔴 |
| Fallen Judgment | tradable → untradeable → 7-day 🔴 |
| every older raid | 7-day → untradeable → tradable ✅ |

So a tradable ticket was burned while a timed one sat in your bag expiring. The older raids listed
the timed id first and were fine by accident.

The table order is no longer consulted. The pick now reads the item itself:

1. **expiring** (has a lifetime — it disappears if left alone, so it goes first)
2. **untradeable** (cannot be sold, so it goes next)
3. **tradable** (last)

The 14-day ticket from the TOS coin shop counts as expiring too, and raids added later are covered
regardless of how their row is written.

#### It tells you which ticket it used

The button's count is the **sum of all three grades** (2 timed + 2 permanent shows as 4), so you
could not see what actually went down. It now reports `Ticket used: <name> (expiring)`.

#### Boss Direction showed Japanese to everyone

The frame layer label had its language test inverted (`~=`), so **every non-Japanese client saw
Japanese**. Fixed.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.8) — レイド入場券は期間制から使います

#### 🔴 IP — 自動マッチング・掃討の入場券ボタンが取引可能な券から使っていた問題

入場券ボタン(アイコンと所持数が付いたボタン)は、これまで**内部テーブルに先に書かれたもの**を
使っていました。しかし最近のレイド3種はアイテムIDの**昇順**で書かれており、その順序が
よりによって**取引可能 → 取引不可 → 7日**でした。

| レイド | テーブルの順序 |
|---|---|
| ズメイ | 取引可能 → 取引不可 → 7日 🔴 |
| 偽りの光輝 | 取引可能 → 取引不可 → 7日 🔴 |
| 堕落した審判 | 取引可能 → 取引不可 → 7日 🔴 |
| その他のレイド | 7日 → 取引不可 → 取引可能 ✅ |

そのため**期間制がそのまま期限切れになる間に取引可能な券を先に消費**していました。古いレイドは
期間制を先に書いていたため偶然正しく動いていました。

今はテーブルの順序を見ません。アイテム情報を直接読んで選びます:

1. **期間制**(使用期限があるもの — 放置すると消えるので最優先)
2. **取引不可**(売れないので次)
3. **取引可能**(最後)

TOSコインショップの14日券も期間制として扱われ、今後レイドが追加されても、テーブルにどの順序で
書いても規則が保たれます。

#### どの入場券を使ったかお知らせします

ボタンの**所持数は3種類の合計**(期間制2 + 無期限2 で4個)なので、何が減ったのか分かりません
でした。これからは `入場券使用: <名前> (期間制)` のようにお知らせします。

#### ボス方向設定ウィンドウの日本語表示

レイヤー項目の言語条件が反転していて(`~=`)、**日本語以外のクライアントで日本語表示**に
なっていました。修正しました。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
