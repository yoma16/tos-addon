# Auto Keeper v1.2.1

> 스태미나 · 물약 버프 해제 · 성물 충전 · 장비 수리 · 바카리네 장비 탈착을 하나로 묶은 자동 관리 애드온입니다.
> 설정은 화면의 HUD 아이콘에서, 진단은 `/keeper` 로 볼 수 있습니다.

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.2.1)

#### 🔴 성물 마력 충전 — 미지의 성역 안에서 안 채워지던 문제

지금까지 이 기능은 **던전 입장창이 열려 있을 때만** 채웠습니다. 입장 직전에 덜 찬 마력을
메꾸는 용도였습니다. 그런데 **미지의 성역 안에는 그 창이 없습니다.** 그래서 성역에서 전투 중
마력이 줄어도 **아무것도 하지 않았습니다.**

이제 **미지의 성역 안에서는 3초마다 확인**해서, 마력이 **200 미만**이면 가진 엑토나이트로
채웁니다(최대 1000).

- 도시는 **게임 기본 자동충전**이 실제로 처리하므로 그대로 둡니다
- 성역 판정은 **던전 ID 를 박아 두지 않고** 게임 기본 자동충전이 쓰는 것과 같은 기준
  (맵 키워드)을 읽습니다 → 성역에 층이 늘어도 함께 적용됩니다
- 던전 입장창 경로는 예전과 똑같이 동작합니다(완료/실패 안내도 그대로)

#### 진단 명령 `/keeper rp` 추가

성역에서 안 채워질 때 원인을 바로 볼 수 있습니다 — 기능 on/off, 현재 마력, 성역 판정,
엑토나이트 보유량이 한 줄에 나옵니다.

### 설치 방법
- **기존 auto_keeper ipf 파일을 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.2.1)

#### 🔴 Relic RP recharge — nothing happened inside the Unknown Sanctuary

Until now this feature only charged **while the dungeon entry window was open** — it existed to
top you up right before entering. But the **Unknown Sanctuary has no such window**, so while your
RP drained in combat there, **nothing happened at all**.

Inside the Unknown Sanctuary it now **checks every 3 seconds** and refills from your Ectonite once
RP drops **below 200** (of 1000).

- Cities are left alone: the game's built-in auto charge really does cover them
- The sanctuary test reads **the same map keyword the built-in charge uses**, not a hardcoded
  dungeon id, so further sanctuary floors are covered as they are added
- The dungeon entry window path behaves exactly as before, including its done / failed notice

#### New diagnostic command `/keeper rp`

One line with the feature's on/off state, your current RP, the sanctuary test and your Ectonite
count — so you can see immediately why a charge did or did not happen.

### How to Install
- **Remove your old auto_keeper ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.2.1)

#### 🔴 聖物の魔力補充 — 未知の聖域の中で補充されなかった問題

これまでこの機能は**ダンジョン入場画面が開いているときだけ**補充していました。入場直前に
足りない魔力を埋めるためのものです。しかし**未知の聖域にはその画面がありません。**そのため
聖域で戦闘中に魔力が減っても**何もしていませんでした。**

これからは**未知の聖域の中では3秒ごとに確認**し、魔力が**200未満**になると手持ちの
エクトナイトで補充します(最大1000)。

- 街は**ゲーム標準の自動チャージ**が実際に処理するのでそのままです
- 聖域の判定は**ダンジョンIDを決め打ちせず**、標準の自動チャージと同じ基準(マップ
  キーワード)を読みます → 聖域の階層が増えても同じように適用されます
- ダンジョン入場画面の経路は以前とまったく同じです(完了・失敗の通知もそのまま)

#### 診断コマンド `/keeper rp` を追加

聖域で補充されないときの原因がすぐ分かります — 機能のオン/オフ、現在の魔力、聖域判定、
エクトナイトの所持数が1行で表示されます。

### インストール方法
- **古い auto_keeper の ipf ファイルを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
