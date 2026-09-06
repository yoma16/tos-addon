# New Nexus Addons v1.1.6

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.6) — 조이패드 모드에서 물약 자동 교체

#### QSO — 레이드 물약이 이제 **첫 입장**에 바로 바뀝니다

조이패드 모드에서 물약 교체가 **두세 번 시도해야 겨우 되는** 문제가 있었습니다. 원인이
셋이었는데, 셋 다 같은 습관에서 나왔습니다 — **작업을 키보드 퀵슬롯 바에 매달아 둔 것**입니다.

조이패드 모드에서 그 바는 **늘 숨겨져 있고**, 업데이트 스크립트는 **그 프레임이 보일 때만
돕니다.**

**① 바꿀 물약 목록이 그 바의 스크립트 안에서만 만들어졌습니다.** 그래서 목록이 영영 안
만들어졌고, 첫 교체가 `attempt to index a nil value (field 'qso_potion_map')` 로 죽었습니다.
두 번째부터 되던 이유는 **실패한 첫 시도가 바를 띄워 놓은 덕분**에 그제야 스크립트가
돌았기 때문입니다.

**② 맵 이동 교체도 같은 숨겨진 바의 타이머였습니다.** 아예 한 번도 돌지 않았습니다.

**③ 기록을 `ShowWindow(1)` 과 같은 프레임에 했습니다.** 표시 전환은 그 프레임 안에서
반영되지 않는데, `SET_QUICK_SLOT` 의 Item 기록은 **대상 프레임이 실제로 보일 때만** 됩니다.
그래서 조용히 아무것도 안 써졌습니다.

고친 내용:

- 물약 목록은 **필요한 곳에서** 만듭니다. 어떤 프레임이 보이든 상관없습니다
- 지연 호출은 프레임에 매이지 않는 `ReserveScript` 로 바꿨습니다
- 기록은 바가 **실제로 보인 다음 틱**에 합니다
- 덤으로, 훅과 메시지 핸들러가 같은 프레임에 각각 부르면서 **같은 교체가 두 번 돌던 것**도
  한 번으로 정리됐습니다

#### 바가 번쩍이던 것도 함께 고쳤습니다

숨기자마자 투명도를 되돌리고 있었는데, 숨김이 한 프레임 늦게 반영되므로 그 사이 바가
불투명하게 한두 프레임 그려졌습니다. 숨김이 실제로 적용된 뒤에 되돌립니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.1.6) — the raid potion swap in joypad mode

#### QSO — potions now swap on the **first** entry

In joypad mode the swap only worked after two or three tries. Three separate defects, all from
the same habit: **hanging work off the keyboard quickslot bar.**

In joypad mode that bar is **always hidden**, and an update script **only ticks while its frame is
shown.**

**① The table of swappable potion ids was built only inside that bar's update script.** So it was
never built, and the first swap died with `attempt to index a nil value (field 'qso_potion_map')`.
It appeared to work from the second attempt only because **the failed first attempt had left the
bar shown**, which finally let the script run.

**② The map-change swap was scheduled on that same hidden bar.** It never fired at all.

**③ The writes ran in the same frame as `ShowWindow(1)`.** Visibility does not take effect within
that frame, and the Item branch of `SET_QUICK_SLOT` **only writes while the target frame is really
shown** — so it silently wrote nothing.

Fixed:

- The potion table is built where it is needed, independent of any frame's visibility
- Both delayed calls use `ReserveScript`, which is not tied to a frame
- The writes happen **one tick after** the bar is actually shown
- As a bonus, the hook and the message handler used to run the same swap twice in one frame; it
  now runs once

#### The bar no longer flashes

Its opacity was restored in the same frame as the hide, and since the hide lands a frame later the
bar was painted opaque for a frame or two. The opacity is now restored after the hide applied.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.6) — ジョイパッドモードの薬自動入れ替え

#### QSO — レイド薬が**初回入場**から入れ替わります

ジョイパッドモードでは2〜3回試さないと入れ替わらない問題がありました。原因は3つで、すべて
同じ癖から来ています — **処理をキーボードクイックスロットバーにぶら下げていたこと**です。

ジョイパッドモードでそのバーは**常に隠れて**おり、更新スクリプトは**フレームが表示されて
いる間しか回りません。**

**① 入れ替え対象の薬リストがそのバーのスクリプト内でしか作られませんでした。** そのため
リストが作られず、初回の入れ替えが `attempt to index a nil value (field 'qso_potion_map')`
で落ちていました。2回目から効いたのは、**失敗した初回がバーを表示したままにした**おかげで
ようやくスクリプトが回ったからです。

**② マップ移動時の入れ替えも同じ隠れたバーのタイマーでした。** 一度も動きませんでした。

**③ 書き込みを `ShowWindow(1)` と同じフレームで行っていました。** 表示切り替えはその
フレーム内では反映されず、`SET_QUICK_SLOT` の Item 分岐は**対象フレームが実際に表示されて
いる時だけ**書き込みます。そのため何も書かれていませんでした。

修正内容:

- 薬リストは**必要な場所で**作ります。どのフレームが見えているかに依存しません
- 遅延呼び出しはフレームに縛られない `ReserveScript` に変更しました
- 書き込みはバーが**実際に表示された次のティック**で行います
- おまけに、フックとメッセージハンドラが同じフレームで同じ入れ替えを2回走らせていたのも
  1回に整理されました

#### バーのちらつきも修正しました

隠した直後に不透明度を戻していましたが、隠す処理は1フレーム遅れて反映されるため、その間
バーが不透明で1〜2フレーム描かれていました。隠す処理が実際に適用された後に戻します。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
