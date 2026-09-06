# New Nexus Addons v1.1.5

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.5) — 챌린지 알림 도배 수정

#### Challenge Helper — 일반 필드에서 알림이 끝없이 반복되던 문제

일반 필드에서 **필드 챌린지**가 열리면 탈출 포탈·보스 등장 알림이 미친 듯이 반복됐습니다.

원인은 **필드 챌린지도 인스턴스 챌린지와 똑같은 신호를 쓴다**는 것이었습니다. 게임은 일반
필드에서도 진행 메시지(`UI_CHALLENGE_MODE_TOTAL_KILL_COUNT`)와 미니맵 마커 갱신을 **매초**
보내는데, 알림 쪽에는 맵을 확인하는 코드가 없었습니다. 도배 경로가 둘이었습니다.

**① 탈출 포탈 알림** — 미니맵 마커 갱신이 매초 오고, 마커가 사라졌다 다시 나타날 때마다
"다시 알릴 수 있음" 상태로 풀려서 초당 한 번씩 반복됐습니다.

**② 보스 등장 알림** — `SHOW` / `GAUGERESET` 가 올 때마다 무조건 다시 열렸습니다. 필드
챌린지는 이 메시지가 파도마다 오므로, 단계가 그대로인데도 계속 다시 알렸습니다.

세 겹으로 막았습니다.

1. 알림은 **실제 챌린지 인스턴스 안에서만** 뜹니다
2. **같은 문구는 60초 안에 다시 뜨지 않습니다** — 맵 판정이 어긋나도 도배로 번지지 않게
3. 보스 알림은 **단계가 실제로 바뀔 때만** 다시 열립니다

HUD(단계·처치수·남은 시간·보스 거리)는 그대로라 필드 챌린지에서도 계속 보입니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.1.5) — challenge notice flooding

#### Challenge Helper — the notices repeated endlessly on a normal field map

When a **field challenge** opened on a normal field, the escape-portal and boss-appeared notices
fired over and over.

The cause: **a field challenge emits exactly the same signals as an instanced one.** The game sends
the progress message (`UI_CHALLENGE_MODE_TOTAL_KILL_COUNT`) and the minimap-mark updates **every
second** on a normal field too, and the notice code never checked the map. Two paths flooded.

**① The escape-portal notice** — the minimap update arrives every second, and whenever the mark went
away and came back it re-armed the notice, so it fired once a second.

**② The boss-appeared notice** — every `SHOW` / `GAUGERESET` re-armed it unconditionally. A field
challenge sends those per wave, so it kept firing even though the stage had not changed.

Three guards now:

1. Notices are limited to an **actual challenge instance**
2. **The same line cannot repeat within 60 seconds** — so a wrong map verdict cannot turn into a flood
3. The boss notice is re-armed **only when the stage really changes**

The HUD (stage, kill count, remaining time, boss distance) is unchanged and still shows during a
field challenge.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.5) — チャレンジ通知の連発を修正

#### Challenge Helper — 通常フィールドで通知が延々と繰り返される問題

通常フィールドで**フィールドチャレンジ**が開くと、脱出ポータル・ボス出現の通知が延々と
繰り返されていました。

原因は**フィールドチャレンジもインスタンスと同じ信号を使う**ことでした。ゲームは通常
フィールドでも進行メッセージ(`UI_CHALLENGE_MODE_TOTAL_KILL_COUNT`)とミニマップマーカーの
更新を**毎秒**送りますが、通知側にマップを確認するコードがありませんでした。経路は2つです。

**① 脱出ポータル通知** — ミニマップ更新が毎秒届き、マーカーが消えて再び現れるたびに
「再通知可能」に戻るため、毎秒繰り返されていました。

**② ボス出現通知** — `SHOW` / `GAUGERESET` が来るたびに無条件で再度有効になっていました。
フィールドチャレンジはこれを波ごとに送るため、段階が変わっていなくても通知し続けました。

3重に抑えました。

1. 通知は**実際のチャレンジインスタンス内でのみ**表示されます
2. **同じ文言は 60 秒以内に再表示されません** — マップ判定がずれても連発に至らないように
3. ボス通知は**段階が実際に変わったときだけ**再度有効になります

HUD(段階・討伐数・残り時間・ボスまでの距離)は変更ありません。フィールドチャレンジでも
そのまま表示されます。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
