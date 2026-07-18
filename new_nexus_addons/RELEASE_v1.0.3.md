# New Nexus Addons v1.0.3

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.0.3)
- **CCH(캐릭터 체인지 헬퍼) 장비 세트 3개 프리셋 추가**
  - 기존에는 캐릭터당 등록 장비 세트가 **1개**뿐이라 전부 예치/전부 장착만 가능했습니다.
  - 이제 **Set1 / Set2 / Set3** 최대 3개 세트를 만들어 원하는 세트만 골라 장착할 수 있습니다.
  - **빼기(창고 → 장착)**: 빼기 버튼을 **우클릭**하면 세트 선택 메뉴가 뜨고, 고른 세트만 꺼내 장착합니다.
  - **넣기(장착 → 창고)**: 지금 착용 중인(현재) 세트를 그대로 창고에 예치합니다.
  - 설정창 상단에 **[Set1][Set2][Set3]** 탭이 추가되어 각 세트별로 장비를 등록할 수 있습니다.
  - 설정창에 **[収納/Store]**, **[装着/Equip]** 버튼 추가 — 창고를 열지 않고도 현재 세트를 예치/장착.
  - 기존 사용자의 등록 장비는 자동으로 **Set1로 마이그레이션**됩니다.
- aethergem_manager 의 설정 저장 시 nil 예외 방어 (v1.0.2 반영).

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.

### 사용법
- `Ctrl + ` `(백틱) : 토글창 열기/닫기
- Zmei 하드 레이드 참가 버튼 클릭 시 물약 자동 교체

---

## 🇺🇸 English

### What's New (v1.0.3)
- **Added 3 equipment set presets to CCH (Character Change Helper)**
  - Previously CCH supported only **one** registered gear set per character (deposit-all / equip-all only).
  - Now you can create up to **3 sets (Set1 / Set2 / Set3)** and equip only the set you choose.
  - **Take out (warehouse → equip)**: **Right-click** the take-out button to open a set-selection menu, then equip only that set.
  - **Store (equip → warehouse)**: deposits your currently worn (current) set as-is.
  - New **[Set1][Set2][Set3]** tabs at the top of the settings window let you register gear per set.
  - Added **[収納/Store]** and **[装着/Equip]** buttons in the settings window — deposit/equip the current set without opening the warehouse.
  - Existing users' registered gear is automatically **migrated to Set1**.
- Guarded a nil exception when saving settings in aethergem_manager (from v1.0.2).

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.

### Usage
- `Ctrl + ` ` (backtick): open/close the toggle window
- Potions auto-swap when you click the Zmei Hard raid join button

---

## 🇯🇵 日本語

### 今回のアップデート (v1.0.3)
- **CCH（キャラクターチェンジヘルパー）に装備セットプリセットを3つ追加**
  - これまではキャラごとに登録できる装備セットが**1つ**だけで、全部預ける／全部装着しかできませんでした。
  - これからは **Set1 / Set2 / Set3** の最大3セットを作成し、選んだセットだけ装着できます。
  - **取り出す（倉庫 → 装着）**: 取り出しボタンを**右クリック**するとセット選択メニューが開き、選んだセットだけ装着します。
  - **預ける（装着 → 倉庫）**: 現在着ている（カレント）セットをそのまま倉庫に預けます。
  - 設定ウィンドウ上部に **[Set1][Set2][Set3]** タブを追加。セットごとに装備を登録できます。
  - 設定ウィンドウに **[収納/Store]**・**[装着/Equip]** ボタンを追加 — 倉庫を開かずに現在のセットを預ける／装着できます。
  - 既存ユーザーの登録装備は自動的に **Set1へ移行**されます。
- aethergem_manager の設定保存時の nil 例外を防止（v1.0.2 反映）。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。

### 使い方
- `Ctrl + ` `（バッククォート）: トグルウィンドウの開閉
- Zmei ハードレイド参加ボタンを押すとポーションが自動で切り替わります
