# New Nexus Addons v1.0.8

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.0.8)

#### Vakarine Equip (v1.1.0) — 도시 밖 모든 맵에서 장비를 탈착하던 버그 수정

- **핵심 수정**: `JSR에서 작동` 체크박스가 켜져 있으면 **맵 검사를 통째로 건너뛰어**, 필드와 구던전을 포함한 **도시 아닌 모든 맵**에서 장비 탈착이 돌았습니다.
  - 이제 이 체크박스는 **주간 보스 레이드(보스 협동전) 8개 맵에서만** 작동 여부를 결정합니다.
  - 일반 인스턴스 던전(레이드/미션)은 이 설정과 무관하게 기존처럼 작동합니다.
  - 맵 판별은 ID 하드코딩이 아니라 맵 `Keyword`(`WeeklyBossMap`)로 하므로, 운영측에서 맵이 추가돼도 누락되지 않습니다.
  - 기본값은 **켜짐**입니다. 구 사양에서 이 8개 맵은 체크와 무관하게 항상 작동했으므로 체감 동작을 유지합니다.
    (이미 설정 파일이 있고 거기에 꺼둔 상태로 저장돼 있으면 그 설정이 유지됩니다.)

| 상황 | 이전 | 이후 |
|---|---|---|
| 인스턴스 던전(레이드/미션) | 작동 | 작동 (동일) |
| 주간 보스 레이드 8맵 | 항상 작동 | 체크 시에만 작동 |
| 필드 / 구던전 | 체크 시 작동 (버그) | 작동 안 함 |
| 도시 밖 수동 실행(아이콘 좌클릭) | 작동 | 작동 (동일) |

- **인벤토리 창이 안 닫히던 버그 수정** — 체크한 부위가 하나도 없으면 인벤토리가 열린 채 남았습니다. 이제 체크가 없으면 아예 열지 않고, 체크는 있지만 해당 부위를 장비하지 않은 경우에도 창을 닫습니다.
- **설정창 정리**
  - 배경을 **반투명**으로 바꿨습니다.
  - 장비 목록 13개를 세로 한 줄에서 **좌/우 2단**으로 나눠 창 길이를 줄였습니다.
  - **전체 선택/해제 토글**을 추가했습니다.
  - 설정창을 **드래그로 옮길 수 있게** 했고, 옮긴 위치가 저장됩니다(이전에는 아예 움직이지 않았습니다).
  - `프레임 고정` 체크박스는 실제로 **작은 아이콘 프레임** 전용이라 라벨을 `아이콘을 고정`으로 정정하고 툴팁을 추가했습니다.
  - 창 밖으로 넘쳐 보이던 닫기 버튼 크기를 고쳤습니다.
  - 타이틀에 `Vakarine Equip v1.1.0`을 표시합니다.

#### Quickslot Operate — 조이스틱 퀵슬롯 바가 사라지던 버그 수정

- **증상**: 조이스틱 퀵슬롯을 쓰는 환경에서 인던 패널로 던전에 들어가거나 물약이 자동 교체되면, **조이스틱 퀵슬롯 바가 다시 나타나지 않고** 키보드용 바가 그대로 남았습니다. 어긋나면 맵을 옮기기 전까지 그대로였습니다.
- **원인**: 물약 교체 코드가 작업 전후로 조이스틱 바를 숨기고 되돌렸는데, 물약을 못 찾는 조기 종료나 중간 오류 시 되돌리기를 건너뛰었습니다.
- **수정**: **조이스틱 바를 아예 건드리지 않습니다.** 숨기지 않으므로 사라질 수 없고, 교체 후 갱신만 합니다.
- 물약 교체에는 키보드용 바가 잠깐 표시돼야 하는 클라이언트 제약이 있어, 그동안 **투명 상태로 두어 화면에 깜빡이지 않게** 했습니다.
- RSHIFT 물약 순환에 있던 중복된 표시 전환도 함께 정리했습니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

### 사용법
- 메뉴를 찾아 nexus addon 아이콘을 클릭합니다.
- Vakarine Equip 아이콘 우클릭으로 설정창을 열어 `JSR에서 작동` 여부와 부위를 조절하세요.

---

## 🇺🇸 English

### What's New (v1.0.8)

#### Vakarine Equip (v1.1.0) — fixed gear swapping on every non-city map

- **Main fix**: when the `Activate in JSR` checkbox was on, it **bypassed the map check entirely**, so gear was unequipped and re-equipped on **every non-city map**, fields and old dungeons included.
  - The checkbox now only decides whether the addon runs on the **8 weekly boss raid maps** (boss co-op).
  - Regular instanced content (raids/missions) keeps working regardless of this setting.
  - Map detection uses the map `Keyword` (`WeeklyBossMap`) instead of hardcoded IDs, so newly added maps are not missed.
  - It defaults to **on**, matching the old effective behaviour (those 8 maps always ran before). If you already have a settings file with it turned off, your choice is kept.

| Situation | Before | After |
|---|---|---|
| Instanced dungeons (raids/missions) | runs | runs (unchanged) |
| 8 weekly boss raid maps | always ran | runs only when checked |
| Fields / old dungeons | ran when checked (bug) | does not run |
| Manual run outside a city (left-click the icon) | runs | runs (unchanged) |

- **Fixed the inventory window staying open** when no slots were checked. It is no longer opened at all in that case, and it is closed when the queue ends up empty (checked slots that you are not wearing).
- **Config window cleanup**
  - The background is now **translucent**.
  - The 13 equipment slots are split into **two columns** instead of one tall list.
  - Added a **select-all / clear-all toggle**.
  - The config window can now be **dragged**, and its position is saved (it did not move at all before).
  - The `Lock frame` checkbox only ever applied to the **small icon frame**, so it is relabelled `Lock the icon` with a tooltip.
  - Fixed the close button rendering larger than its slot.
  - The title now shows `Vakarine Equip v1.1.0`.

#### Quickslot Operate — fixed the joystick quickslot bar disappearing

- **Symptom**: with a joystick quickslot in use, entering a dungeon from the Indun Panel (or any automatic potion swap) left the **joystick bar gone** and the keyboard bar in its place. Once out of sync it stayed that way until the next map change.
- **Cause**: the potion swap hid the joystick bar and restored it afterwards, but the restore was skipped on early returns (no potion found) and on mid-loop errors.
- **Fix**: the joystick bar is **never touched at all** now. It cannot disappear, and it is simply refreshed after the swap.
- The client requires the keyboard bar to be visible for the swap itself, so it is shown **fully transparent** for that moment and does not flash on screen.
- Also removed a redundant duplicate of the same show/hide handling in the RSHIFT potion cycle.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

### Usage
- Open the menu and click the Nexus Addons icon.
- Right-click the Vakarine Equip icon to open its config and set `Activate in JSR` and which slots to swap.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.0.8)

#### Vakarine Equip (v1.1.0) — 都市以外の全マップで装備を着脱していたバグを修正

- **主な修正**: `JSRで作動` チェックボックスがONだと**マップ判定を丸ごと飛ばして**しまい、フィールドや旧ダンジョンを含む**都市以外の全マップ**で着脱が走っていました。
  - このチェックボックスは今後、**週間ボスレイド(ボス協同戦)の8マップ**で作動するかどうかだけを決めます。
  - 通常のインスタンスダンジョン(レイド/ミッション)は、この設定に関係なく従来どおり作動します。
  - マップ判定はID直書きではなくマップの `Keyword`(`WeeklyBossMap`)で行うため、マップが追加されても漏れません。
  - 既定値は**ON**です。旧仕様ではこの8マップはチェックに関係なく常に作動していたため、体感の挙動を維持します。(既に設定ファイルがありOFFで保存されている場合はその設定が維持されます。)

| 状況 | 以前 | 以後 |
|---|---|---|
| インスタンスダンジョン(レイド/ミッション) | 作動 | 作動 (同一) |
| 週間ボスレイド8マップ | 常に作動 | チェック時のみ作動 |
| フィールド / 旧ダンジョン | チェック時に作動 (バグ) | 作動しない |
| 都市外での手動実行(アイコン左クリック) | 作動 | 作動 (同一) |

- **インベントリが閉じないバグを修正** — チェックした部位が一つも無い場合、インベントリが開いたまま残っていました。今後はその場合そもそも開かず、チェックはあるが該当部位を装備していない場合も閉じます。
- **設定ウィンドウの整理**
  - 背景を**半透明**にしました。
  - 装備リスト13個を縦一列から**左右2列**に分割し、ウィンドウの縦幅を縮めました。
  - **全選択/全解除トグル**を追加しました。
  - 設定ウィンドウを**ドラッグで移動**できるようにし、位置が保存されます(以前は全く動きませんでした)。
  - `フレーム固定` チェックボックスは実際には**小さいアイコンフレーム**専用だったため、`アイコンを固定` に修正しツールチップを追加しました。
  - ウィンドウからはみ出して見えていた閉じるボタンのサイズを修正しました。
  - タイトルに `Vakarine Equip v1.1.0` を表示します。

#### Quickslot Operate — ジョイスティッククイックスロットバーが消えるバグを修正

- **症状**: ジョイスティッククイックスロット使用時、Indun Panel からダンジョンに入る(またはポーションが自動変更される)と、**ジョイスティックバーが戻らず**キーボード用バーが残っていました。ズレると次のマップ移動までそのままでした。
- **原因**: ポーション変更処理が前後でジョイスティックバーを隠して戻していましたが、ポーションが見つからない早期リターンや途中のエラーで復元を飛ばしていました。
- **修正**: **ジョイスティックバーには一切触れません。** 隠さないので消えることがなく、変更後に更新するだけです。
- 変更自体にはキーボード用バーの表示がクライアント上必要なため、その間は**完全に透明**にして画面上でちらつかないようにしました。
- RSHIFTのポーション循環にあった重複した表示切替も併せて整理しました。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。

### 使い方
- メニューを開き、Nexus Addons のアイコンをクリックします。
- Vakarine Equip アイコンを右クリックして設定を開き、`JSRで作動` と対象部位を調整してください。
