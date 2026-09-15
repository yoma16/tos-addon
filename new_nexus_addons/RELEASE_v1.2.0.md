# New Nexus Addons v1.2.0

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.2.0)

#### Lv.540 분열: "4인 이하 입장"에 자동으로 동의합니다

인던 패널에서 **Lv.540 분열 입장 버튼**을 누르면 자동 매칭이 걸린 뒤 **"4인 이하 입장"에
자동으로 동의**합니다. 최소 인원인 2명만 모이면 매칭이 시작되므로 4인이 다 찰 때까지
기다리지 않습니다.

**Lv.540 에만 적용하고 Lv.560 은 그대로 둡니다.** 현역 등급에서 인원이 덜 찬 채로 들어가면
아까운 입장 횟수를 쓰게 되기 때문입니다.

동의는 **버튼을 누른 순간에 보낼 수 없습니다.** 자동 매칭을 시작하는 것은 서버이고,
게임 클라이언트도 매칭 중이 아니면 이 요청을 거부합니다(`자동 매칭 중에만 사용할 수 있습니다`).
그래서 패널은 **표식만 남기고**, 매칭이 실제로 시작된 것을 확인한 뒤에 동의를 보냅니다.

이 방식 덕분에:

- **패널에서 시작한 입장에만** 적용됩니다 — 게임 기본 인던 창에서 건 매칭은 건드리지 않습니다
- 표식은 **15초가 지나면 사라져서**, 시작되지 않은 매칭이 다음 회차로 새어 나가지 않습니다
- 동의하면 **시스템 메시지로 알려줍니다.** 4인 이하 입장은 매칭을 취소하기 전에는 되돌릴 수
  없기 때문에, 조용히 걸어 두면 확인할 방법이 없습니다

설정은 인던 패널 설정창의 **기타** 구역에 있고 **기본으로 켜져 있습니다.**

#### 우리엘 하드(파티) 레이드를 추가했습니다

**거짓된 광휘의 날개 · 타락한 심판의 날개**의 파티 난이도가 **클라이언트 리비전 406613**에서
열렸습니다(그 전 리비전까지는 `indun.ies` 에 행 자체가 없었습니다). 주간 1회 · 5인 · Lv.560 ·
기어스코어 38000 입니다.

- **인던 패널** — 그 두 줄에 있던 **H 버튼이 이제 실제로 동작**합니다(입장 횟수도 같이 표시)
- **캐릭터별 인던 목록** — **Hard 칸**이 생겼습니다. 설정 버전을 같이 올려 두었으므로 기존
  사용자도 새 칸이 **켜진 상태**로 나타납니다

두 곳 모두 "열리면 한 줄만 추가하면 되도록" 미리 만들어져 있었습니다(ID 가 없을 때를
가드하고 있었습니다). 그래서 이번에 추가한 것은 각각 한 줄씩입니다.

### 설치 방법
- **옛 nexus_addons 의 ipf 파일만 삭제**하고 이 애드온을 넣어 주세요.
- 또는 addon manager 에서 update 해 주세요.

---

## 🇺🇸 English

### What's new in v1.2.0

#### Lv.540 Singularity: understaffed entry is agreed to for you

Clicking the **Lv.540 Singularity entry button** in the dungeon panel now agrees to
**understaffed entry** once auto-matching starts, so the queue goes as soon as the minimum of
two players is reached instead of waiting for a full party of four.

**Only the Lv.540 tier does this; Lv.560 is untouched.** Going in short-handed on the current
tier spends an entry you would rather save for a full run.

The agreement **cannot be sent at click time.** The server is what starts auto-matching, and
the client itself refuses the request while a match is not running (`Enabled only while
auto-matching`). So the panel **leaves a mark** and sends the agreement once matching has
actually begun.

Because of that:

- it covers **only the entry you started from the panel** — a match you queue from the game's
  own dungeon window is left alone
- the mark **expires after fifteen seconds**, so a queue that never starts cannot leak into a
  later one
- a **system message reports the agreement**, since understaffed entry cannot be taken back
  without cancelling the match — agreeing silently would leave you no way to check

The checkbox lives in the panel settings under **Other** and is **on by default**.

#### Uriel hard (party) raids added

The party tier of **False Radiance** and **Fallen Judgment** opened in **client revision
406613** (before that, `indun.ies` had no row for them at all). Weekly once, five players,
Lv.560, gear score 38000.

- **Dungeon panel** — the **H button** on those two rows now works, and shows its entry count
- **Per-character dungeon list** — their **Hard columns** appeared. The settings version is
  bumped alongside, so existing saves get the new columns **checked on**

Both places had been written to expect this, guarding on the ids being absent, so a single
line each was all that was missing.

### How to install
- **Delete only the old nexus_addons ipf file** and add this addon.
- Or update from the addon manager.

---

## 🇯🇵 日本語

### 今回の更新 (v1.2.0)

#### Lv.540 分裂: 「4人以下入場」に自動で同意します

インダンパネルの **Lv.540 分裂の入場ボタン**を押すと、自動マッチングが掛かったあとに
**「4人以下入場」へ自動で同意**します。最少人数の2人が集まった時点でマッチングが始まるため、
4人が揃うまで待ちません。

**適用は Lv.540 だけで、Lv.560 はそのままです。** 現役の等級で人数が足りないまま入ると、
もったいない入場回数を使うことになるからです。

同意は**ボタンを押した瞬間には送れません。** 自動マッチングを開始するのはサーバーであり、
クライアント側もマッチング中でなければこの要求を拒否します。そこでパネルは**目印だけを残し**、
マッチングが実際に始まったことを確認してから同意を送ります。

そのため:

- **パネルから始めた入場にだけ**適用されます — ゲーム標準のインダン画面から掛けた
  マッチングには触れません
- 目印は **15秒で消える**ので、始まらなかったマッチングが後の回に漏れることはありません
- 同意すると**システムメッセージでお知らせ**します。4人以下入場はマッチングを取り消すまで
  元に戻せないため、黙って掛けると確認する手段がありません

設定はインダンパネル設定の**「その他」**にあり、**初期状態でオン**です。

#### ウリエルのハード(パーティ)レイドを追加しました

**偽りの光輝の翼・堕落した審判の翼**のパーティ難易度が**クライアントリビジョン 406613**で
開放されました(それ以前は `indun.ies` に行そのものがありませんでした)。週1回・5人・Lv.560・
ギアスコア 38000 です。

- **インダンパネル** — その2行にあった **Hボタンが実際に動作**します(入場回数も表示)
- **キャラクター別インダン一覧** — **Hard欄**が増えました。設定バージョンも合わせて上げたので、
  既存ユーザーにも新しい欄が**オンの状態**で現れます

どちらも「開放されたら1行足すだけ」で済むように作ってあった(IDが無い場合をガードしていた)
ため、今回追加したのはそれぞれ1行ずつです。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
