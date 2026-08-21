# New Nexus Addons v1.1.0

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.0)

#### Challenge Helper — 신규 애드온

챌린지 모드의 진행 상황과 보스·탈출 포탈 위치를 알려주는 HUD입니다.

- **3줄 표시**
  - `단계 N  처치/목표  M:SS` — 현재 단계, 처치 수, 남은 시간
  - `보스 : N m` — 주변에서 **살아있는** 보스 중 가장 가까운 것까지의 수평 거리 (없으면 `-`)
  - `포탈 : N m` — 탈출 포탈까지의 수평 거리 (아직 안 생겼으면 `-`)
- **보스 미니맵 마커** — 가장 가까운 보스 위치를 미니맵에 찍습니다. 보스가 죽거나 멀어지면 사라집니다.
- **알림** — 보스가 등장할 때와 탈출 포탈이 생성될 때 시스템 메시지로 각각 한 번 알려줍니다.
- **HUD 이동** — 드래그로 옮기면 위치가 저장됩니다.
- **설정** — 목록의 톱니 버튼에서 알림과 미니맵 마커를 각각 끌 수 있습니다.
- HUD는 **챌린지 맵에서만** 생성됩니다.

> ⚠️ **기본값은 꺼짐입니다.** 쓰시려면 토글창 목록에서 `Challenge Helper`를 켜주세요.
> 새로 추가된 기능이라 이상한 점이 있으면 알려주시면 고치겠습니다.

포탈 좌표는 게임이 미니맵 마커를 그릴 때 Lua로 넘겨주는 값을 그대로 읽습니다.
그 함수를 후킹하지만 **원본을 먼저 호출**하므로 기본 마커는 그대로 표시됩니다.

#### OCSL — 대표 클래스 아이콘이 반영되지 않던 문제 수정

Other Character Skill List에서 캐릭터 왼쪽에 뜨는 **대표 클래스 아이콘이 ILV(Indun List Viewer)에서
지정한 클래스를 따라가지 않던** 문제를 고쳤습니다.

- 이 포크의 제작자 이름이 원본과 달라 **데이터를 찾지 못하고** 있었습니다.
- 저장된 클래스 번호가 문자열이라 **숫자로 변환**해야 했습니다.
- 클래스를 지정하지 않은 캐릭터는 이제 빈 아이콘이 아니라 **기본 아이콘**이 표시됩니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

### 사용법
- 토글창(`Ctrl + ` `)에서 `Challenge Helper`를 켭니다.
- 챌린지 모드에 들어가면 HUD가 자동으로 뜹니다.
- 톱니 버튼으로 알림 / 미니맵 마커를 끌 수 있습니다.

---

## 🇺🇸 English

### What's New (v1.1.0)

#### Challenge Helper — new addon

A HUD that tracks your challenge-mode run and points you at the boss and the exit portal.

- **Three lines**
  - `Stage N  kills/target  M:SS` — current stage, kill count, time left
  - `Boss : N m` — horizontal distance to the nearest **live** boss nearby (`-` when there is none)
  - `Portal : N m` — horizontal distance to the exit portal (`-` until it spawns)
- **Boss minimap marker** — marks the nearest boss on the minimap; it clears when the boss dies or moves away.
- **Notifications** — a system message when the boss appears and when the exit portal spawns, once each.
- **Movable HUD** — drag it and the position is saved.
- **Settings** — the gear button in the list lets you switch the notification and the minimap marker off separately.
- The HUD is only created **on challenge maps**.

> ⚠️ **It ships disabled.** Turn `Challenge Helper` on in the toggle window to use it.
> This is a brand-new addon, so please report anything that looks wrong.

The portal coordinates come from the values the game itself passes to Lua when it draws the minimap
marker. That function is hooked, but **the original is called first**, so the built-in marker still draws.

#### OCSL — representative-class icon now follows ILV

The representative-class icon shown to the left of each character in Other Character Skill List
**did not follow the class picked in ILV** (Indun List Viewer). Fixed.

- The lookup used the upstream author name, which does not match this fork, so it never resolved.
- The stored class id is a string and needed converting to a number.
- A character with no class picked now shows a placeholder icon instead of a blank one.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

### Usage
- Enable `Challenge Helper` in the toggle window (`Ctrl + ` `).
- The HUD appears automatically when you enter challenge mode.
- Use the gear button to turn the notification / minimap marker off.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.0)

#### Challenge Helper — 新規アドオン

チャレンジモードの進行状況とボス・脱出ポータルの位置を表示するHUDです。

- **3行表示**
  - `段階 N  討伐/目標  M:SS` — 現在の段階、討伐数、残り時間
  - `ボス : N m` — 周囲の**生存中**のボスのうち最も近いものまでの水平距離 (いない場合は `-`)
  - `ポータル : N m` — 脱出ポータルまでの水平距離 (未生成の場合は `-`)
- **ボスのミニマップマーカー** — 最も近いボスの位置をミニマップに表示します。ボスが倒れる、または離れると消えます。
- **通知** — ボス出現時と脱出ポータル生成時に、システムメッセージでそれぞれ1回お知らせします。
- **HUDの移動** — ドラッグで移動でき、位置が保存されます。
- **設定** — リストの歯車ボタンから通知とミニマップマーカーをそれぞれオフにできます。
- HUDは**チャレンジマップでのみ**生成されます。

> ⚠️ **既定ではオフです。** 使用する場合はトグルウィンドウのリストから `Challenge Helper` を有効にしてください。
> 新規アドオンのため、おかしな点があればお知らせください。

ポータルの座標は、ゲームがミニマップマーカーを描画する際にLuaへ渡してくる値をそのまま読んでいます。
その関数をフックしていますが、**先に元の関数を呼ぶ**ため、標準のマーカーはそのまま表示されます。

#### OCSL — 代表クラスアイコンがILVの指定に追従しなかった問題を修正

Other Character Skill List のキャラクター左側に表示される**代表クラスアイコンが、ILV(Indun List Viewer)で
指定したクラスに追従しなかった**問題を修正しました。

- 参照していた作者名がこのフォークと異なっていたため、データを取得できていませんでした。
- 保存されているクラスIDが文字列のため、数値へ変換する必要がありました。
- クラス未指定のキャラクターは、空アイコンではなく**既定アイコン**が表示されるようになりました。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。

### 使い方
- トグルウィンドウ(`Ctrl + ` `)で `Challenge Helper` を有効にします。
- チャレンジモードに入るとHUDが自動的に表示されます。
- 歯車ボタンから通知 / ミニマップマーカーをオフにできます。
