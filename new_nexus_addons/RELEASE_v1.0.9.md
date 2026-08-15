# New Nexus Addons v1.0.9

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.0.9)

#### 로그인 후 애드온 초기화 속도 개선 — 9.2초 → 2.2초

실측 후 두 가지 원인을 고쳤습니다.

- **Market Voucher의 중복 저장 제거 (5.2초 단축)** — 거래 기록을 로그 txt와 json **두 곳에 같은 내용으로** 저장하고 있었고,
  로그인마다 그 json 전량(1,360건 / 124KB)을 읽어서 **곧바로 다시 쓰고** 있었습니다.
  **애드온을 꺼놔도 발생**했습니다(초기화 코드에 사용 여부 체크가 없었음).
  이제 로그 txt만 정본으로 쓰고, **전표 창을 열 때만** 읽습니다. 기존 거래 기록은 그대로 유지되며 합계·기간도 전량 기준입니다.
- **초기화 처리량 상향 (약 2.2초 단축)** — 애드온 48개를 `0.1초당 2개`씩 처리하던 것을 `0.05초당 6개`로 올렸습니다.
  이전에는 실제 작업량과 무관하게 대기만 2.4초 이상 쌓였습니다.

#### Another Warehouse — 즐겨찾기 기능 추가

자주 꺼내는 아이템을 창고 목록 맨 위에 고정할 수 있습니다.

- **별 버튼 추가** — `TAKE SET` 버튼 왼쪽에 별 버튼이 생겼습니다. 누르면 즐겨찾기 설정창이 열립니다.
- **즐겨찾기 등록** — 설정창을 열어둔 상태에서
  - **창고 아이템 우클릭** → 즐겨찾기 등록
  - **인벤토리 아이템 우클릭** → 즐겨찾기 등록
  - **설정 슬롯 우클릭** → 등록 해제
  - **설정 슬롯 드래그** → 표시 순서 변경
  - `TAKE SET` 설정과 달리 **개수는 설정하지 않습니다.** 표시 전용이라 창고 자동 입출고 설정과는 무관합니다.
- **최상단 고정** — 즐겨찾기한 아이템은 `All` 탭 목록의 **맨 위**에 `즐겨찾기 (개수)` 그룹으로 뜹니다.
  원래 카테고리 그룹에도 그대로 남아 있으므로 기존 목록이 사라지지는 않습니다.
- **스크롤 위치 유지** — 즐겨찾기를 등록하거나 해제해도 창고 목록 스크롤이 맨 위로 돌아가지 않고 보던 위치를 지킵니다.
- **한국어 표시** — 즐겨찾기 관련 문구(그룹 이름, 버튼, 도움말, 안내 메시지)가 한국어로 나옵니다.
- **즐겨찾기 전용 탭 신설** — 왼쪽 탭 메뉴 **`All`보다 위**에 별 표시 탭이 생겼습니다.
  이 탭에서는 즐겨찾기한 아이템만 보입니다.
- **표시 순서** = 설정창에서 드래그로 정한 슬롯 순서입니다(이름순이 아닙니다).
- 즐겨찾기 목록은 **계정(팀) 공통**으로 저장됩니다. 캐릭터를 바꿔도 그대로 유지됩니다.
- 검색은 즐겨찾기 그룹에도 함께 적용됩니다.

#### 탭 열 크기 조정

탭이 10개에서 **11개**로 늘어났습니다. 창고 창의 세로 공간이 고정이라 늘릴 수 없어서,
탭 간격과 아이콘 크기를 약 10% 줄여 11개가 다 들어가게 했습니다.
(기존 탭들의 위치가 조금씩 위로 올라옵니다.)

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

### 사용법
- 창고 NPC를 열고 `TAKE SET` 왼쪽의 **별 버튼**을 누릅니다.
- 창고나 인벤토리의 아이템을 **우클릭**해 즐겨찾기에 넣습니다.
- 설정창의 `?` 버튼에 조작법이 정리돼 있습니다.

---

## 🇺🇸 English

### What's New (v1.0.9)

#### Startup addon initialization — 9.2s down to 2.2s

Two causes, both found by measuring:

- **Market Voucher's duplicate storage removed (−5.2s)** — the trade log was stored **twice with identical content**,
  once in the log txt and once in a json. Every login decoded that whole json (1,360 entries / 124KB) and
  **immediately wrote it all back out**. This happened **even with the addon switched off** (the init code had no
  use check). The log txt is now the only copy and is read **only when the voucher window opens**. Existing trade
  records are kept, and the totals/period still cover every entry.
- **Init throughput raised (−2.2s)** — the 48 addons were processed `2 per 0.1s`; now it is `6 per 0.05s`.
  Previously 2.4s or more was spent purely waiting, regardless of how much work there actually was.

#### Another Warehouse — favorite items

Pin the items you take out most often to the top of the warehouse list.

- **New star button** — added to the left of the `TAKE SET` button. It opens the favorites picker.
- **Registering favorites** — while the picker is open:
  - **right-click a warehouse item** → add to favorites
  - **right-click an inventory item** → add to favorites
  - **right-click a picker slot** → remove
  - **drag a picker slot** → change the display order
  - Unlike the `TAKE SET` sets, **there is no count to configure.** Favorites are display-only and do not
    affect the automatic deposit/withdrawal settings.
- **Pinned to the top** — favorites appear as a `Favorites (n)` group at the **very top** of the `All` tab.
  They also remain in their normal category group, so nothing disappears from the existing list.
- **A dedicated favorites tab** — a new star tab sits **above `All`** in the left tab column and shows
  favorites only.
- **Scroll position kept** — adding or removing a favorite no longer snaps the warehouse list back to the top.
- **Display order** follows the slot order you set by dragging in the picker (not alphabetical).
- The favorites list is stored **per account (team)**, so it is shared across characters.
- Searching also filters the favorites group.

#### Tab column rescaled

The tab column went from 10 to **11 tabs**. The warehouse window's height is fixed and cannot grow,
so the tab spacing and icon size were reduced by about 10% to fit all 11.
(Existing tabs shift up slightly.)

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

### Usage
- Open a warehouse NPC and click the **star button** to the left of `TAKE SET`.
- **Right-click** items in the warehouse or your inventory to add them to favorites.
- The `?` button in the picker lists all the controls.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.0.9)

#### ログイン後のアドオン初期化を高速化 — 9.2秒 → 2.2秒

実測して2つの原因を修正しました。

- **Market Voucherの二重保存を解消 (5.2秒短縮)** — 取引記録をログtxtとjsonの**2箇所に同じ内容で**保存しており、
  ログインごとにそのjson全件(1,360件 / 124KB)を読み込んで**そのまま書き戻していました**。
  **アドオンをオフにしていても発生**していました(初期化処理に使用有無のチェックがなかったため)。
  現在はログtxtのみを正本とし、**伝票ウィンドウを開いた時だけ**読み込みます。
  既存の取引記録はそのまま維持され、合計・期間も全件が対象です。
- **初期化の処理量を引き上げ (約2.2秒短縮)** — アドオン48個を `0.1秒あたり2個` から `0.05秒あたり6個` に変更しました。
  以前は実際の処理量に関係なく、待ち時間だけで2.4秒以上かかっていました。

#### Another Warehouse — お気に入り機能を追加

よく取り出すアイテムを倉庫リストの最上段に固定できます。

- **星ボタンを追加** — `TAKE SET` ボタンの左に星ボタンが追加されました。押すとお気に入り設定ウィンドウが開きます。
- **お気に入りの登録** — 設定ウィンドウを開いている間に
  - **倉庫アイテムを右クリック** → お気に入りに登録
  - **インベントリアイテムを右クリック** → お気に入りに登録
  - **設定スロットを右クリック** → 登録解除
  - **設定スロットをドラッグ** → 並び順の変更
  - `TAKE SET` のセットとは違い、**個数の設定はありません。** 表示専用なので自動搬出入の設定には影響しません。
- **最上段に固定** — お気に入りのアイテムは `All` タブの**一番上**に `Favorites (個数)` グループとして表示されます。
  元のカテゴリグループにもそのまま残るので、既存のリストが消えることはありません。
- **お気に入り専用タブを新設** — 左のタブ列の **`All` より上**に星タブが追加され、お気に入りだけが表示されます。
- **スクロール位置を維持** — お気に入りを登録・解除しても倉庫リストのスクロールが先頭に戻らなくなりました。
- **表示順**は設定ウィンドウでドラッグして決めたスロット順です(名前順ではありません)。
- お気に入りリストは**アカウント(チーム)共通**で保存され、キャラクターを変えても維持されます。
- 検索はお気に入りグループにも適用されます。

#### タブ列のサイズ調整

タブが10個から**11個**に増えました。倉庫ウィンドウの縦幅は固定で広げられないため、
タブの間隔とアイコンサイズを約10%縮小して11個すべてが収まるようにしました。
(既存のタブの位置が少し上にずれます。)

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。

### 使い方
- 倉庫NPCを開き、`TAKE SET` の左の**星ボタン**を押します。
- 倉庫やインベントリのアイテムを**右クリック**してお気に入りに追加します。
- 設定ウィンドウの `?` ボタンに操作方法がまとまっています。
