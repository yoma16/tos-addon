# New Nexus Addons v1.1.9

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.9) — 입장 횟수가 남았으면 그냥 입장합니다

#### 🔴 IP — 입장권 버튼이 아무 반응도 없던 문제

챌린지·분열의 입장권 버튼은 **입장 횟수가 남아 있으면 아무것도 하지 않고** 돌아갔습니다.
"횟수가 있는데 입장권을 쓸 이유가 없다"는 판단 자체는 맞습니다. 그런데 **그 버튼의 설명은
이미 이렇게 안내하고 있었습니다**:

> 좌클릭: 파티 입장 / 우클릭: 솔로 입장

약속해 놓고 눌러도 반응이 없으니, 사용자 입장에서는 **고장난 버튼**이었습니다. 버튼이 죽은
것인지, 조건이 안 맞은 것인지, 클릭이 안 먹은 것인지 구별할 방법도 없었습니다.

이제 **횟수가 남아 있으면 그대로 입장합니다.** 파티와 솔로는 새로 만들 것이 없었습니다 —
버튼이 클릭에 따라 이미 다른 인던 종류를 넘기고 있었기 때문입니다.

| 버튼 | 좌클릭 | 우클릭 |
|---|---|---|
| Lv.560 챌린지 (TOS 주화 · 용병단 증표) | 파티(자동매칭) | 솔로 |
| Lv.540 챌린지 | 솔로 | (없음) |
| 분열 Lv.540 / Lv.560 | 입장 | (없음) |

#### 🔴 분열 입장권에 등급 구분이 빠져 있었습니다

챌린지에는 있는 **Lv.540 / Lv.560 구분이 분열 쪽에는 없었습니다.** 그래서 Lv.560 분열이
**거래 가능한 무기한 입장권을 구매보다 먼저** 쓰고 있었습니다.

이제 챌린지와 같은 규칙입니다:

- **Lv.540** — 지난 등급이니 **가진 것을 먼저** 씁니다 (기간제 → 거래불가 → 거래가능 → 구매)
- **Lv.560** — 현역이니 **살 수 있을 때 사고** 거래 가능한 것은 아낍니다
  (기간제 → 거래불가 → 구매 → 거래가능)

#### Lv.560 챌린지의 용병단 증표 버튼은 구매가 1순위입니다

증표는 **주기마다 초기화되는 재화**라, 살 수 있을 때 사 두는 편이 이득입니다.
그래서 이 버튼만 `증표 구매 → 기간제 → 거래불가 → 거래가능` 순서로 바꿨습니다.
못 사면(구매 횟수 소진) 그대로 가진 입장권으로 내려갑니다.

**TOS 주화 버튼과 Lv.540 은 그대로입니다.** 주화는 값이 나가는 재화라 가지고 있는 기간제보다
먼저 태우면 손해이기 때문입니다.

#### "입장권 사용" 안내는 뺐습니다

v1.1.8 에서 넣었던 `입장권 사용: <이름> (기간제)` 안내를 제거했습니다. 순서가 제대로
고쳐졌는지 확인할 방법이 없어서(버튼의 보유 수량이 세 등급의 합이라) 넣은 것인데,
확인이 끝난 뒤로는 소탕을 돌릴 때마다 뜨는 방해물이 됐습니다.

### 설치 방법
- **옛 nexus_addons 의 ipf 파일만 삭제**하고 이 애드온을 넣어 주세요.
- 또는 addon manager 에서 update 해 주세요.

---

## 🇺🇸 English

### What's new in v1.1.9 — the panel enters when you still have entries

#### 🔴 IP — the ticket button did nothing at all

The challenge and singularity ticket buttons bailed out early whenever an entry was still
available. Not spending a ticket you don't need is the right call — but **the button's own
tooltip already promised this**:

> Left Click: PT Entry / Right Click: Solo Entry

A click that does nothing reads as a broken button, and there was no way to tell whether the
button was dead, the condition had not matched, or the click had not registered.

The buttons now **enter directly** when entries remain. Party or solo needed nothing new —
the button already passed a different dungeon id per click:

| Button | Left click | Right click |
|---|---|---|
| Lv.560 challenge (TOS coin · mercenary badge) | Party (auto-match) | Solo |
| Lv.540 challenge | Solo | (none) |
| Singularity Lv.540 / Lv.560 | Enter | (none) |

#### 🔴 The singularity flow was missing the tier split

The **Lv.540 / Lv.560 split that the challenge flow has was absent from singularity**, so
Lv.560 spent a tradable permanent ticket *before* buying one.

It now follows the same rule as the challenge:

- **Lv.540** — a past tier, so it **spends what it holds first**
  (expiring → untradeable → tradable → buy)
- **Lv.560** — the current tier, so it **buys while it can** and keeps the tradable one
  (expiring → untradeable → buy → tradable)

#### The Lv.560 challenge mercenary-badge button buys first

That currency **resets each period**, so buying while the allowance lasts is the better trade.
Only this button changed, to `buy with badges → expiring → untradeable → tradable`. If it
cannot buy (allowance used up) it falls straight through to the tickets you own.

**The TOS-coin button and every Lv.540 path are unchanged** — coins are expensive, and burning
them ahead of an expiring ticket you already hold is a loss.

#### The "Ticket used" notice is gone

The `Ticket used: <name> (expiring)` line added in v1.1.8 has been removed. It existed only
because the button's count is the sum of all three grades, leaving no way to verify the
ordering. Once confirmed, it was just noise on every sweep.

### How to install
- **Delete only the old nexus_addons ipf file** and add this addon.
- Or update from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.9) — 入場回数が残っていればそのまま入場します

#### 🔴 IP — 入場券ボタンが何も反応しなかった問題

チャレンジ・分裂の入場券ボタンは、**入場回数が残っていると何もせずに**戻っていました。
「回数があるのに入場券を使う理由がない」という判断自体は正しいのですが、**そのボタンの説明には
既にこう書かれていました**:

> 左クリック: PT入場 / 右クリック: ソロ入場

約束しておいて押しても反応がないので、利用者から見れば**壊れたボタン**でした。ボタンが死んで
いるのか、条件が合わないのか、クリックが効いていないのか区別する方法もありませんでした。

これからは**回数が残っていればそのまま入場します。** PTとソロは新しく作るものがありません
でした — ボタンがクリックごとに既に別のダンジョン種別を渡していたからです。

| ボタン | 左クリック | 右クリック |
|---|---|---|
| Lv.560 チャレンジ (TOSコイン・傭兵団証票) | PT(自動マッチング) | ソロ |
| Lv.540 チャレンジ | ソロ | (なし) |
| 分裂 Lv.540 / Lv.560 | 入場 | (なし) |

#### 🔴 分裂の入場券に等級の区別が抜けていました

チャレンジにある **Lv.540 / Lv.560 の区別が分裂側にありませんでした。** そのため Lv.560 分裂が
**取引可能な無期限入場券を購入より先に**使っていました。

これからはチャレンジと同じ規則です:

- **Lv.540** — 過ぎた等級なので**所持分を先に**使います(期間制 → 取引不可 → 取引可能 → 購入)
- **Lv.560** — 現役なので**買えるときに買い**、取引可能なものは温存します
  (期間制 → 取引不可 → 購入 → 取引可能)

#### Lv.560 チャレンジの傭兵団証票ボタンは購入が最優先です

証票は**周期ごとにリセットされる通貨**なので、買えるときに買っておく方が得です。
このボタンだけ `証票で購入 → 期間制 → 取引不可 → 取引可能` の順に変えました。
買えない場合(購入回数を使い切った場合)は、そのまま所持している入場券に降ります。

**TOSコインボタンと Lv.540 はそのままです。** コインは高価な通貨で、持っている期間制より先に
消費すると損だからです。

#### 「入場券使用」のお知らせは削除しました

v1.1.8 で追加した `入場券使用: <名前> (期間制)` のお知らせを削除しました。ボタンの所持数が
3等級の合計で順番を確認する方法がなかったため入れたものですが、確認が終わった後は掃討の
たびに出る邪魔物になっていました。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
