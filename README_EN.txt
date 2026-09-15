=====================================================
 Native Lang — DeepL setup guide
 addon v1.1.5  /  engine v0.0.7
=====================================================

Files included:
   native_lang-v1.1.5.ipf
   native_lang-v0.0.7.exe


--- STEP 0: Remove the old version first (IMPORTANT) ---

If you already have an older Native Lang installed, DELETE the old
.ipf from your <game folder>\data\ folder first. It will look like:

   _native_lang-<something>-v1.1.4.ipf

If you leave it there, the addon is loaded TWICE and will misbehave.

You can also delete any old native_lang-v0.0.x.exe / .tar files in
<game folder>\addons\native_lang\ — they are no longer used.


--- STEP 1: Get your own free DeepL API key ---

1. Go to:  https://www.deepl.com/pro-api
   Click the "Free API Key" button.

   !! IMPORTANT !!
   You must sign up for "DeepL API Free" (the DEVELOPER plan).
   A normal DeepL Pro translator subscription does NOT include
   an API key. This is the most common mistake.

2. After signing up, get your key here:
      https://www.deepl.com/your-account/keys
   (Account -> "API Keys" tab)

3. A free key looks like this — note the ":fx" at the end:
      279a2e9d-83b3-c416-7e2d-f721593e42a0:fx

   Free plan quota: 1,000,000 characters per month.
   (Verified 2026-09-16 against DeepL's /v2/usage endpoint.)
   Signup requirements can vary by region — check the signup page.


--- STEP 2: Install the two files ---

   native_lang-v1.1.5.ipf   ->   <game folder>\data\
   native_lang-v0.0.7.exe   ->   <game folder>\addons\native_lang\

   Create the "addons\native_lang" folder if it does not exist.

   Note: your antivirus may flag the .exe as a false positive.
   You may need to add an exclusion for the addons\native_lang folder.

   Then start the game.


--- STEP 3: Enter the key in game ---

1. Look at the chat window. Next to the chat tabs there is a small
   square button (30x30) showing your language code, e.g. "en".

2. LEFT CLICK it. A menu titled "Native Lang" opens.

3. Click the line:
      DeepL API Key : OFF (Google)

4. A window opens:
      "Enter your DeepL API key (free at deepl.com/pro-api)"
   Paste your key into the text box.

5. Click  [ Save & Restart ]
   You should see:  "DeepL API key saved. Restarting."

6. Open the menu again — it should now read:
      DeepL API Key : ON        (in green)

Done. Chat and player names are now translated via DeepL.


--- Alternative: edit the file directly ---

   <game folder>\addons\native_lang\<your account ID>\settings.json

   Set the "deepl_api_key" field:
      {"use":1,"lang":"en","recv_lang":"en","chatmode":false,
       "deepl_api_key":"YOUR-KEY-HERE:fx"}

   The translation engine reloads this file every second,
   so no restart is needed.


--- Notes ---

* Without a key it falls back to Google Translate. Google's free
  endpoint blocks IP addresses that send many requests ("unusual
  traffic" / HTTP 429), and this addon sends one request per chat
  line — so a DeepL key is strongly recommended.
* To go back to Google, click [ Clear (Google) ] in the same window.
* The key is stored only in your own account folder. It is never
  included in the addon file.
* Other menu items: "addon Stop" turns translation off,
  "Switch to chat mode" translates chat only (not names),
  "addon Reboot" restarts the translation engine.


--- If it does not work ---

Check, in this order:

1. Is native_lang-v0.0.7.exe running? (Task Manager)
   If not: antivirus may have removed it, or the file name is wrong.
2. Is there a leftover restart.dat in addons\native_lang\ ?
   Delete it — it makes the engine shut itself down.
3. Delete any *.processing and *.tmp files in addons\native_lang\
4. Is the button next to the chat tabs RED (on) or GRAY (off)?
   Gray means the addon is stopped — click it and choose
   "addon Activation".
