# New Nexus Addons v1.1.7

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.7) — 공명의 성소는 자동으로 입장하지 않습니다

#### IP — 공명의 성소(자우라) 입장 버튼이 **단계 선택 창을 엽니다**

인던 패널에서 공명의 성소 입장 버튼을 누르면 **그대로 입장**해 버렸습니다. 그런데 이 인던은
**입장 단계를 골라야 합니다**(해금한 단계까지 선택). 패널이 일반 인던과 똑같이 자동 입장을
부르고 있어서, 단계 선택이 통째로 건너뛰어졌습니다.

이제 버튼을 누르면 **게임의 단계 선택 창**이 열립니다 — 게임 안 인던 정보창의 "입장하기"
버튼이 띄우는 그 창과 같습니다. 단계를 고르고 입장은 그 창에서 직접 누르시면 됩니다.

판정은 던전 ID 를 박아 두지 않고 **던전 클래스의 `DungeonType`** 을 읽습니다. 그래서 공명의
성소에 보스가 추가되면 그 인던도 자동으로 같이 적용됩니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.1.7) — the Sanctuary of Resonance is no longer auto-entered

#### IP — the Sanctuary of Resonance (Zawra) button now **opens the step-selection window**

Pressing the entry button on the indun panel walked you **straight into** the dungeon. But this
dungeon makes you **pick an entry step** (you choose up to the one you have unlocked), and the
panel was calling the same plain auto-enter it uses for ordinary dungeons, so that choice was
skipped entirely.

The button now opens **the game's own step-selection window** — the very one the "Enter" button in
the in-game dungeon info window opens. Pick your step and press enter there.

The check reads **`DungeonType` off the dungeon class** rather than a hardcoded dungeon id, so
further Sanctuary bosses will be covered as they are added.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.7) — 共鳴の聖所は自動入場しません

#### IP — 共鳴の聖所(ザウラ)の入場ボタンが**段階選択ウィンドウを開きます**

インダンパネルの入場ボタンを押すと**そのまま入場**していました。しかしこのインダンは
**入場段階を選ぶ必要があります**(解放済みの段階まで選択)。パネルが通常のインダンと同じ
自動入場を呼んでいたため、段階選択が丸ごとスキップされていました。

これからはボタンを押すと**ゲーム側の段階選択ウィンドウ**が開きます — ゲーム内のインダン
情報ウィンドウの「入場する」ボタンが開くものと同じです。段階を選んで、入場はそのウィンドウ
から押してください。

判定はダンジョンIDを決め打ちせず**ダンジョンクラスの `DungeonType`** を読みます。そのため
共鳴の聖所にボスが追加された場合も同じように適用されます。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
