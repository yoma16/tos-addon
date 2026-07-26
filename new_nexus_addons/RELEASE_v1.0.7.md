# New Nexus Addons v1.0.7

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.0.7) — Indun Panel

- **패널 전체 크기를 80%로 축소**
  - 좌표·크기뿐 아니라 **글씨 크기와 툴팁까지** 함께 줄였습니다. 확장 패널 폭 750 → 649, 설정창 660 → 547.
  - 행 간격은 33 → 30으로 줄이면서 행 사이 여백은 오히려 확보했습니다.
- **창을 옮겨도 위치가 저장되지 않던 버그 수정**
  - 프레임 이동이 가능한 기본 상태에서 드래그 위치가 저장되지 않아, INDUNPANEL 버튼 토글 / 도시 진입 / 세트 전환 / 설정창 진입 때마다 기본 위치(화면 상단 중앙쯤)로 되돌아갔습니다.
  - 이제 드래그한 위치가 그대로 유지됩니다. 프레임 배경을 클릭했을 때 패널이 접히던 것도 함께 고쳤습니다.
- **접힌 바에도 배경과 테두리 표시** — Cupole Manager HUD와 같은 외형(`bg2` 스킨)으로 통일했습니다. SKIN SELECT로 계속 바꿀 수 있습니다.
- **정렬·간격 정리**
  - 상단 바의 버튼/아이콘 크기와 세로 위치를 통일했습니다(이전에는 아이콘마다 크기·높이가 달랐습니다).
  - 항상 펼치기 체크박스가 SET C 버튼과 겹치던 문제, 설정창 첫 줄 아이콘(레티시아 등)이 잘려 안 보이던 문제를 고쳤습니다.
  - 설정창은 화면 밖으로 밀려나지 않도록 화면 안에 맞춰 열립니다(닫기 버튼이 화면 밖에 있던 문제).
  - 설정창의 INDUNPANEL 버튼을 누르면 이제 **직전 화면(펼친 패널)** 으로 돌아갑니다.
- **SET 버튼 선택 시 세로 길이가 짧아지던 현상 수정**

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

### 사용법
- 메뉴를 찾아 nexus addon 아이콘을 클릭합니다.
- Indun Panel 크기가 취향에 맞지 않으면 SKIN SELECT로 배경을, 설정창에서 표시할 단축 아이콘/던전을 조절하면 폭이 더 줄어듭니다.

---

## 🇺🇸 English

### What's New (v1.0.7) — Indun Panel

- **Scaled the whole panel down to 80%**
  - Not just coordinates and sizes — **font sizes and tooltips** were scaled too. Expanded panel width 750 → 649, config window 660 → 547.
  - Row pitch went 33 → 30 while still gaining visible space between rows.
- **Fixed the panel position not being saved after a drag**
  - With the frame movable (the default), the dragged position was never stored, so the panel jumped back to its default spot (near the top center of the screen) on every INDUNPANEL toggle, city entry, set switch or config open.
  - The dragged position now sticks. Clicking the frame background no longer collapses the panel either.
- **The collapsed bar now has a background and border** — matched to the Cupole Manager HUD look (`bg2` skin). SKIN SELECT still overrides it.
- **Alignment and spacing cleanup**
  - Button/icon sizes and vertical positions in the top bar are unified (icons used to differ in both size and height).
  - Fixed the always-open checkbox overlapping the SET C button, and the first icon row in the config window clipping its last entry (Leticia).
  - The config window is now clamped on screen, so its close button can no longer end up off-screen.
  - The INDUNPANEL button inside the config window now returns to **the previous view (the expanded panel)**.
- **Fixed SET buttons shrinking vertically when selected**

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

### Usage
- Open the menu and click the Nexus Addons icon.
- If the Indun Panel size is not to your taste, change the background with SKIN SELECT; unchecking shortcut icons / dungeons in the config window shrinks its width further.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.0.7) — Indun Panel

- **パネル全体を80%に縮小**
  - 座標やサイズだけでなく、**文字サイズとツールチップ**も一緒に縮小しました。展開パネル幅 750 → 649、設定ウィンドウ 660 → 547。
  - 行の送りは 33 → 30 に縮めつつ、行間の余白はむしろ確保しています。
- **ドラッグしても位置が保存されないバグを修正**
  - フレーム移動が可能な既定状態でドラッグ位置が保存されず、INDUNPANELボタンの開閉 / 都市入場 / セット切替 / 設定を開く度に既定位置（画面上部中央あたり）へ戻っていました。
  - 今後はドラッグした位置がそのまま維持されます。フレーム背景をクリックすると畳まれてしまう挙動も直しました。
- **畳んだバーにも背景と枠線を表示** — Cupole Manager の HUD と同じ見た目（`bg2` スキン）に揃えました。SKIN SELECT での変更は引き続き有効です。
- **整列・余白の整理**
  - 上段バーのボタン/アイコンのサイズと縦位置を統一しました（以前はアイコンごとにサイズも高さも違いました）。
  - 常時展開チェックボックスが SET C ボタンと重なる問題、設定ウィンドウ1行目のアイコン（レティーシャ等）が切れて見えない問題を修正。
  - 設定ウィンドウは画面内に収まるように開きます（閉じるボタンが画面外に出る問題）。
  - 設定ウィンドウの INDUNPANEL ボタンで**直前の表示（展開パネル）**に戻るようになりました。
- **SETボタン選択時に縦幅が縮む現象を修正**

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。

### 使い方
- メニューを開き、Nexus Addons のアイコンをクリックします。
- Indun Panel のサイズが好みに合わない場合は SKIN SELECT で背景を変更し、設定ウィンドウで表示するショートカットアイコン/ダンジョンを減らすと横幅がさらに縮みます。
