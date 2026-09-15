=====================================================
 Native Lang — DeepL 설정 안내
 애드온 v1.1.5  /  번역 엔진 v0.0.7
=====================================================

채팅과 플레이어 이름을 자동 번역하는 애드온입니다.
게임 안(Lua)과 게임 밖(번역 프로그램) 두 개가 파일로 주고받는 구조라,
.ipf 와 .exe 를 둘 다 넣어야 동작합니다.

동봉 파일:
   native_lang-v1.1.5.ipf
   native_lang-v0.0.7.exe

※ 한국어 클라이언트에서는 애드온 메뉴가 "영어"로 표시됩니다.
  (일본어 클라이언트만 일본어로 나옵니다)
  아래 설명의 영어 문구는 게임에 실제로 뜨는 그대로입니다.


--- STEP 0: 기존 버전을 먼저 지우세요 (중요) ---

예전 Native Lang 을 쓰고 있었다면, <게임폴더>\data\ 에 있는
옛날 .ipf 를 먼저 삭제하세요. 이런 이름입니다:

   _native_lang-<무언가>-v1.1.4.ipf

지우지 않으면 애드온이 두 번 로드되어 제대로 동작하지 않습니다.

<게임폴더>\addons\native_lang\ 안의 옛날
native_lang-v0.0.x.exe / .tar 파일도 지워도 됩니다 (이제 안 씁니다).


--- STEP 1: 본인 DeepL 무료 API 키 발급 ---

1. 접속:  https://www.deepl.com/pro-api
   "Free API Key" 버튼을 누릅니다.

   !! 중요 !!
   반드시 "DeepL API Free" (개발자용 플랜) 로 가입해야 합니다.
   일반 DeepL Pro 번역기 구독을 결제해도 API 키는 나오지 않습니다.
   여기서 잘못 가입하는 경우가 가장 많습니다.

2. 가입 후 키 확인:
      https://www.deepl.com/your-account/keys
   (계정 → "API Keys" 탭 → 복사 버튼으로 복사)

3. 무료 키는 끝이 ":fx" 로 끝납니다. 이런 형태입니다:
      279a2e9d-83b3-c416-7e2d-f721593e42a0:fx

   무료 플랜 한도: 월 1,000,000자
   (2026-09-16 에 DeepL /v2/usage 로 직접 확인한 값입니다)
   가입 시 필요한 정보는 지역에 따라 다를 수 있으니 가입 페이지에서 확인하세요.


--- STEP 2: 파일 두 개 배치 ---

   native_lang-v1.1.5.ipf   ->   <게임폴더>\data\
   native_lang-v0.0.7.exe   ->   <게임폴더>\addons\native_lang\

   "addons\native_lang" 폴더가 없으면 직접 만드세요.

   ※ 백신이 .exe 를 위협으로 오탐지할 수 있습니다.
     그럴 경우 addons\native_lang 폴더를 예외(제외) 설정에 추가하세요.

   배치 후 게임을 실행합니다.


--- STEP 3: 게임 안에서 키 입력 ---

1. 채팅창을 보세요. 채팅 탭 옆에 언어 코드(예: "ko")가 적힌
   작은 정사각형 버튼(30x30)이 있습니다.

2. 좌클릭하면 "Native Lang" 메뉴가 열립니다.

3. 다음 줄을 클릭:
      DeepL API Key : OFF (Google)

4. 창이 열립니다:
      "Enter your DeepL API key (free at deepl.com/pro-api)"
   입력칸에 키를 붙여넣으세요.

5. [ Save & Restart ] 클릭
   "DeepL API key saved. Restarting." 메시지가 뜹니다.

6. 메뉴를 다시 열면 이렇게 바뀌어 있습니다:
      DeepL API Key : ON        (초록색)

완료입니다. 이제 채팅과 플레이어 이름이 DeepL 로 번역됩니다.


--- 다른 방법: 파일을 직접 수정 ---

   <게임폴더>\addons\native_lang\<계정ID>\settings.json

   "deepl_api_key" 값을 채웁니다:
      {"use":1,"lang":"ko","recv_lang":"en","chatmode":false,
       "deepl_api_key":"여기에키:fx"}

   번역 엔진이 이 파일을 1초마다 다시 읽으므로
   게임을 재시작할 필요가 없습니다.


--- 메뉴 항목 설명 (전부 영어로 표시됩니다) ---

   DeepL API Key : ON / OFF (Google)
       → DeepL 키 입력 창을 엽니다

   Switch to chat mode / Switch to full translation mode
       → 채팅만 번역 / 채팅 + 이름까지 전부 번역 전환
         (채팅 모드로 두면 길드창·파티창·이름은 번역하지 않습니다)

   Translation of my speech to ...
       → 내가 치는 말을 어떤 언어로 번역해서 보낼지

   addon Stop / addon Activation
       → 번역 기능 정지 / 시작

   addon Reboot
       → 번역 엔진(.exe) 재시작


--- 참고 ---

* 키가 없으면 Google 번역으로 대체됩니다. 그런데 Google 무료 번역은
  요청이 많은 IP 를 차단합니다 ("unusual traffic" / HTTP 429).
  이 애드온은 채팅 한 줄마다 요청을 1번 보내기 때문에 차단되기 쉽습니다.
  실제로 제작 과정에서 테스트하던 PC 가 차단당했습니다.
  → DeepL 키 사용을 강력히 권장합니다.
* Google 로 되돌리려면 같은 창의 [ Clear (Google) ] 를 누르세요.
* 키는 본인 계정 폴더에만 저장되며, 애드온 파일(.ipf)에는 들어가지 않습니다.
* 게임 용어는 가끔 어색하게 번역될 수 있습니다.
  (예: "Where is the boss?" → "사장님은 어디 계세요?")
  기계 번역의 한계이며 애드온 문제가 아닙니다.


--- 안 될 때 확인 순서 ---

1. native_lang-v0.0.7.exe 가 실행 중인가요? (작업관리자에서 확인)
   없다면: 백신이 지웠거나, 파일 이름이 다를 수 있습니다.
   파일명은 반드시 "native_lang-v0.0.7.exe" 여야 합니다.

2. addons\native_lang\ 에 restart.dat 가 남아 있지 않나요?
   남아 있으면 번역 엔진이 스스로 종료해 버립니다. 삭제하세요.

3. addons\native_lang\ 의 *.processing / *.tmp 파일을 삭제하세요.
   (번역 엔진이 비정상 종료했을 때 남는 찌꺼기입니다)

4. 채팅 탭 옆 버튼이 빨간색(동작 중)인가요, 회색(정지)인가요?
   회색이면 정지 상태입니다. 클릭해서 "addon Activation" 을 고르세요.

5. 채팅창을 접어두지 마세요.
   번역 결과를 가져오는 동작이 채팅창에 붙어 있어서,
   채팅창이 숨겨져 있으면 번역이 화면에 반영되지 않습니다.
