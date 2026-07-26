# New Nexus Addons v1.0.6

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.0.6)
- **Other Character Skill List(다른 캐릭터 스킬 목록)에서 도시 진입마다 캐릭터가 사라지던 버그 수정**
  - 기존에는 도시에 들어갈 때마다 `system_option`의 불완전한 목록(`pc_id`)을 기준으로 정리해서, 현재 접속한 캐릭터만 남고 이전에 기록된 캐릭터가 사라졌습니다.
  - 이제 **배럭 전체 캐릭터 목록**을 기준으로 정리합니다. 실제로 삭제된 캐릭터만 목록에서 제거되고, 유효한 캐릭터는 사라지지 않습니다.
  - 현재 배럭 레이어의 캐릭터를 자동으로 등록합니다. 순서대로 정렬되지 않으면 배럭 1/2/3에서 각각 한 번씩 접속해 주세요.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

### 사용법
- 메뉴를 찾아 nexus addon 아이콘을 클릭합니다.

---

## 🇺🇸 English

### What's New (v1.0.6)
- **Fixed Other Character Skill List wiping stored characters on every city entry**
  - It used to prune the list against an incomplete source (`system_option`'s `pc_id`) on every city entry, so only the current character survived and previously recorded characters disappeared.
  - It now prunes against the **full barrack roster**. Only characters that were actually deleted are removed; valid characters are never lost.
  - Characters in the current barrack layer are auto-registered. If they do not sort in order, log in once from each barrack (1/2/3).

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

### Usage
- Open the menu and click the Nexus Addons icon.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.0.6)
- **Other Character Skill List（他キャラスキルリスト）で都市に入る度にキャラが消えるバグを修正**
  - 従来は都市に入る度に `system_option` の不完全なリスト（`pc_id`）を基準に整理していたため、現在ログイン中のキャラだけが残り、以前記録したキャラが消えていました。
  - 今後は**バラックの全キャラクター一覧**を基準に整理します。実際に削除されたキャラのみ除去され、有効なキャラは消えません。
  - 現在のバラックレイヤーのキャラを自動登録します。順番に並ばない場合は、バラック1/2/3ごとに一度ログインしてください。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。

### 使い方
- メニューを開き、Nexus Addons のアイコンをクリックします。
