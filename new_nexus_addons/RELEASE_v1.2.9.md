# New Nexus Addons v1.2.9

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.2.9) — 버그 수정

- **기능을 끈 뒤 게임 버튼이 먹통이 되던 문제**
  일부 기능(마켓 바우처 등)을 끄거나 그 기능이 시작 도중 멈추면, 게임을 다시 켤 때까지 경매장 수령·채널 이동 같은 게임 기본 버튼이 아무 반응이 없을 수 있었습니다. 이제 그럴 때는 게임 원래 동작이 실행됩니다.
- **인던 패널: 레이드 자동매칭이 가끔 안 눌리던 문제**
  - A(자동매칭)·S(1인) 버튼과 인던 목록 뷰어의 입장 버튼이 입장 창이 실제로 뜬 것을 확인한 뒤 누릅니다.
  - H 버튼: 불꽃의 기억 등 입장 방식이 바뀐 던전에서 자동매칭이 안 눌리던 문제를 고쳤습니다.
- **인던 패널: JSR 오늘의 보스 아이콘이 비어 있던 문제** — 아이콘과 툴팁(이름·종족·방어 종류)이 표시됩니다.
- **인던 패널: 560 분열 입장권 툴팁** — 실제 사용 순서(거래불가가 구매보다 먼저)로 고쳤습니다.
- **AWH: 팀 창고 넣기가 거부되던 경우 하나 더** — 같은 아이템 묶음이 잠긴 칸에 있으면 빈 칸에 넣습니다.
- **서브맵: 위치가 초기화되던 문제**
  설정을 바꾸면 창이 처음 자리로 돌아가던 문제, 화면 끝에 붙여 둔 자리가 저장되지 않던 문제, 미니맵 모드에서 끈 자리가 일반 모드 위치를 덮어쓰던 문제를 고쳤습니다.
- **보조 퀵슬롯: 귀걸이·아이커 툴팁** — 등록한 그 아이템의 옵션이 보입니다.

### 설치 방법
- **옛 nexus_addons 의 ipf 파일만 삭제**하고 이 애드온을 넣어 주세요.
- 또는 addon manager 에서 update 해 주세요.

---

## 🇺🇸 English

### What's new in v1.2.9 — bug fixes

- **Game buttons dead after turning a feature off**
  Turning off some features (Market Voucher etc.), or one stopping during startup, could leave game buttons such as market collect and channel move doing nothing until the game was restarted. The game's own action now runs in that case.
- **Indun Panel: raid auto-match sometimes not pressed**
  - The A (auto-match) and S (solo) buttons and the Indun List Viewer entry buttons press only after the entry window is really open.
  - H button: fixed auto-match not working for dungeons whose entry method changed (e.g. the earring raid).
- **Indun Panel: JSR today's boss icon was empty** — the icon and a tooltip (name, race, armor) now show.
- **Indun Panel: 560 Singularity ticket tooltips** — now list the real order (untradable before buying).
- **AWH: one more rejected team warehouse deposit** — a stack in a locked slot is skipped for a free slot.
- **Sub Map: position reset**
  Fixed the window returning to its default spot when a setting changes, a spot at the screen edge not being kept, and dragging in minimap mode overwriting the normal spot.
- **Sub Slotset: earring / icor tooltips** — show the registered item's own options.

### How to install
- **Delete only the old nexus_addons ipf file** and add this addon.
- Or update from the addon manager.

---

## 🇯🇵 日本語

### 今回の更新 (v1.2.9) — 不具合修正

- **機能をオフにした後、ゲームのボタンが効かなくなる問題**
  一部の機能(マーケットバウチャーなど)をオフにしたり、その機能が起動途中で止まったりすると、ゲームを再起動するまでマーケット受取・チャンネル移動などの基本ボタンが反応しないことがありました。その場合はゲーム本来の動作が実行されるようになりました。
- **インダンパネル: レイドの自動マッチングが押されないことがある問題**
  - A(自動マッチング)・S(ソロ)ボタンとインダンリストビューアの入場ボタンは、入場ウィンドウが実際に開いたのを確認してから押します。
  - H ボタン: 入場方式が変わった一部のダンジョン(イヤリングレイドなど)で自動マッチングが押されない問題を修正しました。
- **インダンパネル: JSR 今日のボスアイコンが空だった問題** — アイコンとツールチップ(名前・種族・防御タイプ)が表示されます。
- **インダンパネル: 560分裂チケットのツールチップ** — 実際の使用順(取引不可が購入より先)に修正しました。
- **AWH: チーム倉庫への預け入れが拒否されるケースをもう一つ修正** — 同じアイテムの束がロック枠にある場合は空き枠に入れます。
- **サブマップ: 位置がリセットされる問題**
  設定を変えるとウィンドウが初期位置に戻る問題、画面端に置いた位置が保存されない問題、ミニマップモードで動かした位置が通常モードの位置を上書きする問題を修正しました。
- **サブスロット: イヤリング・イコルのツールチップ** — 登録したそのアイテムのオプションが表示されます。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
