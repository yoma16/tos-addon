# New Nexus Addons v1.1.1

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.1) — 2026-09-01 EP18.2 대응

#### Indun Panel — 신규 콘텐츠 추가

- **신규 레이드 2종** — `거짓된 광휘의 날개` / `타락한 심판의 날개` 줄이 추가됩니다.
  솔로 · 자동매칭 입장, 소탕(ACLEAR) 횟수, 입장권 보유 개수까지 기존 레이드와 똑같이 동작합니다.
  > 파티(하드)는 아직 게임에 열리지 않아 넣지 않았습니다. 열리면 바로 추가하겠습니다.
- **공명의 성소** — 1회 입장권으로 들어가는 단일 인던 줄이 추가됩니다(아샤크 아래).
- **사울레 인증서 상점** — 단축 아이콘 줄에 상점 버튼이 추가됩니다. 툴팁에 보유 인증서 수가 표시됩니다.
- **아샤크 던전 제거** — 이번 패치로 게임에서 사라져, 눌러도 아무 일도 없던 줄을 표시하지 않습니다.

#### Indun Panel — 챌린지 / 분열 특이점 등급 상승

Lv.520 칸을 빼고 **Lv.540 · Lv.560** 두 칸으로 올렸습니다. Lv.560 챌린지에는 파티(PT) 버튼이 붙습니다.
구매 버튼도 등급에 맞는 상점을 봅니다(TOS 주화 상점 / 용병단 상점 양쪽 모두).

> 예전 Lv.520 자리의 TOS 주화 상점 항목은 이번 패치로 **레이드 입장권을 파는 자리로 바뀌었습니다.**
> 그래서 Lv.520을 남길 이유가 없어졌습니다.

#### Indun Panel — 🔴 Lv.560 입장 가능 횟수가 항상 0으로 나오던 문제 수정

남은 입장 횟수를 **인던 번호를 손으로 나열한 목록**에서 찾고 있었습니다. 등급이 올라가면서 새 번호가
그 목록에 없어 **항상 0** 이 나왔고, 표시만 틀린 게 아니라 **입장권을 계속 쓰려 드는** 문제까지 있었습니다.
이제 인던 클래스가 가진 값을 직접 읽으므로 등급이 또 올라가도 따라갑니다.
Lv.540 칸이 `(0/0)` 으로만 보이던 것도 같이 고쳤습니다.

#### Indun List Viewer — 신규 레이드 2종 추가

인던 현황표의 자동매칭 레이드 칸에 신규 레이드 두 종이 추가됩니다.
기존 사용자의 저장 설정에도 체크박스가 생기도록 설정 버전을 올렸습니다.

#### Auto Repair — Lv.560 긴급 수리 키트로 변경

`[Lv.560] 긴급 수리 키트`(사울레 인증서 상점)를 사용합니다. 자동 구매도 사울레 상점에서 이루어집니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.1.1) — EP18.2 support (patched 2026-09-01)

#### Indun Panel — new content

- **Two new raids** — rows for `False Radiance's Wing` and `Fallen Judgment's Wing`.
  Solo and auto-match entry, the sweep (ACLEAR) count and your ticket count all work as on the other raids.
  > Party (hard) mode is not in the game data yet, so it is not on the panel. It will be added as soon as it opens.
- **Sanctuary of Resonance** — a single-entry dungeon row (below Ashaq) that uses a one-time ticket.
- **Saule certificate shop** — a shop button joins the shortcut icon row, with your certificate count in the tooltip.
- **Ashaq removed** — the game dropped this dungeon in the patch, so the dead row is no longer drawn.

#### Indun Panel — challenge / singularity move up one tier

Lv.520 is gone; the row now shows **Lv.540 and Lv.560**, with a PT button on Lv.560 challenge.
The buy buttons point at whichever shop sells that tier (both the TOS coin shop and the mercenary shop).

> The TOS coin shop entry that used to sell the Lv.520 ticket now sells a **raid** ticket instead,
> so there was no reason to keep Lv.520 around.

#### Indun Panel — 🔴 fixed Lv.560 always reporting zero entries left

The remaining-entry lookup searched a **hand-written list of dungeon ids**. The new tiers were not in
that list, so they always came back as 0 — and because the ticket logic reads that number, the panel
would keep spending tickets. It now reads the value off the dungeon class itself, so it keeps working
the next time the tier goes up. The Lv.540 slot showing only `(0/0)` is fixed as well.

#### Indun List Viewer — the two new raids are listed

Both new raids appear in the auto-match raid columns. The settings version was bumped so existing
saves get the new checkboxes instead of leaving them unchecked.

#### Auto Repair — now uses the Lv.560 repair kit

It uses the `[Lv.560] Emergency Repair Kit` and auto-buys it from the Saule certificate shop.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.1) — 2026-09-01 EP18.2 対応

#### Indun Panel — 新コンテンツ追加

- **新レイド2種** — `偽りの光輝の翼` / `堕落した審判の翼` の行が追加されます。
  ソロ・自動マッチング入場、掃討(ACLEAR)回数、チケット所持数まで既存レイドと同じように動作します。
  > パーティ(ハード)はまだゲームに実装されていないため入れていません。実装され次第追加します。
- **共鳴の聖所** — 1回入場チケットで入る単一インダンの行を追加しました(アシャークの下)。
- **サウレ証票ショップ** — ショートカットアイコン列にショップボタンが追加されます。ツールチップに所持証票数が表示されます。
- **アシャーク削除対応** — 今回のパッチでゲームから無くなったため、押しても何も起きなかった行を表示しません。

#### Indun Panel — チャレンジ / 分裂特異点の段階を1つ上げました

Lv.520の枠を外し、**Lv.540・Lv.560** の2枠になりました。Lv.560チャレンジにはPTボタンが付きます。
購入ボタンもその段階を売っているショップを見ます(TOSコインショップ / 傭兵団ショップの両方)。

> 以前Lv.520を売っていたTOSコインショップの項目は、今回のパッチで**レイドチケットを売る枠に変わりました。**
> そのためLv.520を残す理由がなくなりました。

#### Indun Panel — 🔴 Lv.560の残り入場回数が常に0と表示される問題を修正

残り入場回数を**インダン番号を手書きで並べたリスト**から探していました。段階が上がって新しい番号が
そのリストに無かったため**常に0**となり、表示が違うだけでなく**チケットを使い続けてしまう**問題がありました。
インダンクラスが持つ値を直接読むようにしたので、次に段階が上がっても追従します。
Lv.540の枠が `(0/0)` としか表示されなかった問題も併せて修正しました。

#### Indun List Viewer — 新レイド2種を追加

インダン一覧の自動マッチングレイド欄に新レイド2種が追加されます。
既存の保存設定でもチェックボックスが出るよう、設定バージョンを上げています。

#### Auto Repair — Lv.560 緊急修理キットに変更

`[Lv.560] 緊急修理キット`(サウレ証票ショップ)を使用します。自動購入もサウレショップで行われます。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
