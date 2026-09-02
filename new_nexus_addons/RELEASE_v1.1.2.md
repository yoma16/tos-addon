# New Nexus Addons v1.1.2

> Nexus Addons 프레임워크(제작: Ajinori/norisan)의 yomae 포크 버전입니다.
> `Ctrl + ` `(백틱) 으로 토글창을 열 수 있습니다. **Ajinori san 복귀 시 원본에 병합될 예정입니다.**

---

## 🇰🇷 한국어

### 이번 업데이트 (v1.1.2) — 🔴 클라이언트 크래시 수정

#### Muteki — 파티챗 알림이 켜진 버프가 끝나면 게임이 튕기던 문제

버프 알림(Muteki)에서 **파티챗 알림을 켜 둔 버프가 끝날 때 클라이언트가 종료**되는 문제가
있었습니다. 크래시 덤프로 원인을 확인했습니다.

게임이 버프 제거(`BUFF_REMOVE`)를 처리하고 있는 **도중에** 애드온이 파티 메시지를 보내고
있었고, 그 안에서 접근 위반(ACCESS_VIOLATION)이 발생했습니다.

- 메시지 문구는 예전과 똑같이 그 시점에 만듭니다(한 틱 뒤에는 버프 정보가 사라질 수 있습니다).
- **전송만 한 틱 뒤로 미뤄** 버프 처리 바깥에서 보냅니다.
- 버프 **시작·종료**의 **파티챗·니코챗** 알림 네 곳 모두에 적용했습니다.

동작은 그대로입니다 — 알림은 여전히 나가고, 0.1초 늦게 나갈 뿐입니다.

> ℹ️ 파티에 속해 있어도 발생했습니다. "파티가 없어서 생긴 문제"가 아닙니다.
> Lua 오류가 아니라 네이티브 크래시라 애드온 로그에는 아무 기록도 남지 않습니다.

### 설치 방법
- **기존 넥서스 애드온(nexus_addons ipf 파일)만 삭제**하고 이 애드온을 넣어주세요.
- 혹은 addon manager에서 update 하세요.

---

## 🇺🇸 English

### What's New (v1.1.2) — 🔴 client crash fix

#### Muteki — the game died when a buff with party-chat announce ended

If you had turned on the party-chat announcement for a buff, the client **crashed when that buff
ended**. The cause was confirmed from a crash dump.

The addon was sending the party message from **inside** the engine's buff-removal (`BUFF_REMOVE`)
dispatch, and the access violation happened in there.

- The message text is still built at that same moment (a tick later the buff data may be gone).
- **Only the send is deferred by one tick**, so it happens outside the buff dispatch.
- Applied to all four notifications: party chat and nico chat, on buff start and buff end.

Behaviour is unchanged — the announcement still goes out, just 0.1s later.

> ℹ️ It happened while in a party too, so a missing party was not the cause.
> It was a native crash rather than a Lua error, so nothing was written to the addon logs.

### How to Install
- **Remove only your old nexus_addons ipf file**, then add this addon.
- Or update it from the addon manager.

---

## 🇯🇵 日本語

### 今回のアップデート (v1.1.2) — 🔴 クライアントクラッシュ修正

#### Muteki — パーティチャット通知を有効にしたバフが終了するとゲームが落ちる問題

バフ通知(Muteki)で**パーティチャット通知をオンにしたバフが終了する際にクライアントが落ちる**
問題がありました。クラッシュダンプで原因を確認しています。

ゲームがバフ削除(`BUFF_REMOVE`)を処理している**最中に**アドオンがパーティメッセージを送信して
おり、その中でアクセス違反(ACCESS_VIOLATION)が発生していました。

- メッセージ文は従来どおりその時点で作成します(1ティック後にはバフ情報が失われる可能性があります)。
- **送信のみを1ティック遅らせ**、バフ処理の外で行うようにしました。
- バフ**開始・終了**の**パーティチャット・ニコチャット**の通知4か所すべてに適用しました。

動作は変わりません — 通知は今までどおり送信され、0.1秒遅れるだけです。

> ℹ️ パーティに所属していても発生しました。「パーティ不在が原因」ではありません。
> Luaエラーではなくネイティブクラッシュのため、アドオンのログには何も残りません。

### インストール方法
- **古い nexus_addons の ipf ファイルだけを削除**して、このアドオンを入れてください。
- または addon manager から update してください。
