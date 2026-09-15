# MIT License
# Copyright (c) 2024 norisan
# Version 0.0.7 (DeepL REST direct + true batching, Google fallback)
#
# v0.0.6 からの変更点 / Changes from v0.0.6:
#   1. DeepL 対応。deep_translator の DeeplTranslator は韓国語 (ko) 非対応のため、
#      REST API を直接呼ぶ。/ DeepL support via direct REST API — deep_translator's
#      DeeplTranslator has no Korean in its language table (even in 1.11.4).
#   2. 本当のバッチ翻訳。DeepL は 1 リクエストで最大 50 行。
#      Google は API 側がバッチ不可なので並列リクエストで待ち時間だけ短縮。
#      / Real batching for DeepL (50 lines per request); Google cannot batch,
#        so requests are parallelised instead.
#   3. translated_chat_ids が無限に増えないよう上限を設定。
#      / Cap translated_chat_ids so it no longer grows without bound.

import json
import os
import threading
import sys
import psutil
import time
import traceback
import tkinter as tk
from tkinter import messagebox
from collections import deque
from concurrent.futures import ThreadPoolExecutor

import requests
from deep_translator import GoogleTranslator


# --- コンソール出力のエンコーディング / console output encoding ---
# 韓国語版 Windows ではコンソールが cp949 になり、このファイル中の日本語の print が
# UnicodeEncodeError を投げてプログラムごと落ちる（v0.0.6 までの致命的な不具合）。
# On Korean Windows the console code page is cp949, so the Japanese print() calls
# raise UnicodeEncodeError and kill the whole program — a fatal bug up to v0.0.6.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass    # stdout が無い (--noconsole) 場合など


# --- 定数定義 ---

ACTIVE_ID = str(sys.argv[1]) if len(sys.argv) > 1 else None


def get_base_dir():
    if hasattr(sys, 'frozen'):
        # .exe化された場合はexe自身の場所が基準
        return os.path.dirname(sys.executable)
    else:
        # スクリプト実行時はこのファイルの場所が基準
        return os.path.dirname(os.path.abspath(__file__))


BASE_DIR = get_base_dir()
TOS_PROCESS_NAME = "Client_tos_x64.exe"

# DeepL が受け付ける target_lang。ここに無い言語は最初から Google に回す
# DeepL target codes. A language missing here goes straight to Google.
DEEPL_TARGET = {
    "ko": "KO",
    "ja": "JA",
    "en": "EN-US",
}
DEEPL_BATCH_MAX = 50        # DeepL の 1 リクエストあたりの上限
# Google の無料エンドポイントは「毎秒 5 リクエスト」が上限。並列数を上限まで上げると
# 429 を自分で誘発するので 3 に抑える。/ Google's free endpoint allows 5 req/sec;
# going that wide triggers the 429 ourselves, so stay at 3.
GOOGLE_WORKERS = 3
GOOGLE_BACKOFF_SEC = 120    # 429 を食らったらこの秒数は Google を呼ばない
CHAT_ID_MEMORY = 5000       # 翻訳済み chat_id を覚えておく上限


# --- ユーティリティ関数 ---
def terminate_self():
    try:
        psutil.Process(os.getpid()).terminate()
    except Exception as e:
        print(f"プロセスの終了中にエラー: {e}")


def show_error_and_exit(title, message):
    detailed_message = f"{message}\n\nTraceback:\n{traceback.format_exc()}"
    print(f"重大なエラー: {title} - {detailed_message}")

    def display_messagebox():
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror(title, detailed_message)
        root.destroy()

    threading.Thread(target=display_messagebox).start()


# --- コアクラス ---
class process_monitor:
    def __init__(self, process_name, restart_path, stop_callback, interval=5):
        self.process_name = process_name
        self.restart_path = restart_path
        self.stop_callback = stop_callback
        self.interval = interval
        self.thread = threading.Thread(target=self._monitor_loop, daemon=True)

    def _is_process_running(self):
        return any(proc.info['name'] == self.process_name for proc in psutil.process_iter(['name']))

    def _monitor_loop(self):
        while True:
            try:
                if not self._is_process_running() or os.path.exists(self.restart_path):
                    reason = "プロセスが終了しました" if not self._is_process_running() else "restart.datが検出されました"
                    print(f"{reason}。翻訳ツールを終了します。")
                    if os.path.exists(self.restart_path):
                        os.remove(self.restart_path)
                    self.stop_callback()
                    break
            except Exception as e:
                print(f"監視スレッドでエラー: {e}")
            time.sleep(self.interval)

    def start(self):
        self.thread.start()
        print(f"{self.process_name} の監視を開始しました。")


class translation_engine:
    """DeepL (REST 直接) を優先し、失敗したら Google にフォールバックする。
    DeepL first (direct REST), falling back to Google on any failure."""

    def __init__(self, deepl_api_key=None):
        self.deepl_api_key = None
        self.deepl_endpoint = None
        self._google_blocked_until = 0.0
        self.set_deepl_api_key(deepl_api_key)

    def _google_is_blocked(self):
        return time.time() < self._google_blocked_until

    def _block_google(self):
        if not self._google_is_blocked():
            print(f"Google翻訳がレート制限(429)を返しました。{GOOGLE_BACKOFF_SEC}秒間 Google の呼び出しを停止します。"
                  f"（DeepL APIキーを設定すると回避できます）")
        self._google_blocked_until = time.time() + GOOGLE_BACKOFF_SEC

    def set_deepl_api_key(self, key):
        self.deepl_api_key = key or None
        if self.deepl_api_key:
            # 無料キーは ":fx" で終わる / free keys end with ":fx"
            free = self.deepl_api_key.strip().endswith(":fx")
            host = "api-free.deepl.com" if free else "api.deepl.com"
            self.deepl_endpoint = f"https://{host}/v2/translate"
            print(f"DeepL APIキーが設定されています（{'無料' if free else '有料'}プラン）。DeepLを優先使用します。")
        else:
            self.deepl_endpoint = None
            print("DeepL APIキーなし。Google翻訳を使用します。")

    # --- 単件 / single ---
    def translate(self, text, dest_lang, src_lang='auto', max_attempts=3):
        if not text or not text.strip():
            return text
        return self.translate_many([text], dest_lang, src_lang, max_attempts)[0]

    # --- 複数件（バッチ）/ batch ---
    def translate_many(self, texts, dest_lang, src_lang='auto', max_attempts=3):
        """入力と同じ長さのリストを必ず返す。失敗した要素は原文のまま。
        Always returns a list of the same length; failed items keep the original text."""
        if not texts:
            return []

        # 空行は翻訳に出さず、位置だけ覚えておく
        targets = [i for i, t in enumerate(texts) if t and t.strip()]
        results = list(texts)
        if not targets:
            return results

        payload = [texts[i] for i in targets]
        translated = None

        if self.deepl_endpoint and dest_lang in DEEPL_TARGET:
            translated = self._deepl_many(payload, dest_lang)

        if translated is None:
            translated = self._google_many(payload, dest_lang, src_lang, max_attempts)

        for pos, i in enumerate(targets):
            value = translated[pos] if pos < len(translated) else None
            if value:
                results[i] = value
        return results

    def _deepl_many(self, texts, dest_lang):
        """成功したら翻訳リスト、失敗したら None（呼び出し側が Google に回す）。
        Returns the translations, or None so the caller falls back to Google."""
        target = DEEPL_TARGET.get(dest_lang)
        if not target:
            return None

        out = []
        headers = {"Authorization": f"DeepL-Auth-Key {self.deepl_api_key}"}
        for start in range(0, len(texts), DEEPL_BATCH_MAX):
            chunk = texts[start:start + DEEPL_BATCH_MAX]
            data = [("target_lang", target)] + [("text", t) for t in chunk]
            try:
                resp = requests.post(self.deepl_endpoint, data=data, headers=headers, timeout=15)
                if resp.status_code != 200:
                    # 456 = 文字数上限超過, 403 = キー不正
                    print(f"DeepL エラー HTTP {resp.status_code}: {resp.text[:200]} → Googleにフォールバック")
                    return None
                items = resp.json().get("translations", [])
                if len(items) != len(chunk):
                    print(f"DeepL の応答件数が不一致 ({len(items)} != {len(chunk)}) → Googleにフォールバック")
                    return None
                out.extend(item.get("text", "") for item in items)
            except Exception as e:
                print(f"DeepL 通信エラー: {e} → Googleにフォールバック")
                return None
        return out

    def _google_many(self, texts, dest_lang, src_lang, max_attempts):
        """Google は API 側がバッチ非対応なので並列に投げる。
        Google has no batch endpoint, so fire the requests in parallel."""
        if self._google_is_blocked():
            return list(texts)      # レート制限中は原文のまま返す
        if len(texts) == 1:
            return [self._google_one(texts[0], dest_lang, src_lang, max_attempts)]
        workers = min(GOOGLE_WORKERS, len(texts))
        with ThreadPoolExecutor(max_workers=workers) as pool:
            return list(pool.map(
                lambda t: self._google_one(t, dest_lang, src_lang, max_attempts), texts))

    @staticmethod
    def _is_rate_limit(err):
        text = str(err).lower()
        return "429" in text or "too many requests" in text

    def _google_one(self, text, dest_lang, src_lang, max_attempts):
        attempt = 1
        while attempt <= max_attempts:
            if self._google_is_blocked():
                return text
            try:
                return GoogleTranslator(source=src_lang, target=dest_lang).translate(text)
            except Exception as e:
                # レート制限は再試行しても悪化するだけなので即座に打ち切る
                # Retrying a rate limit only makes it worse — bail out at once.
                if self._is_rate_limit(e):
                    self._block_google()
                    return text
                if attempt == max_attempts:
                    print(f"Google翻訳エラー（{attempt}回目で断念）: {e}")
                    return text
                attempt += 1
                time.sleep(0.3)
        return text


class file_processor:
    def __init__(self, base_dir, lang, engine):
        self.base_dir = base_dir
        self.lang = lang
        self.engine = engine
        self.file_paths = {
            "send_msg": os.path.join(base_dir, "send_msg.dat"),
            "recv_msg": os.path.join(base_dir, "recv_msg.dat"),
            "send_name": os.path.join(base_dir, "send_name.dat"),
            "recv_name": os.path.join(base_dir, "recv_name.dat"),
        }
        self.translated_names = {}
        self.translated_chat_ids = set()
        self.chat_id_order = deque()
        print(f"ファイルプロセッサ準備完了: -> {self.lang}")

    def _remember_chat_id(self, chat_id):
        if chat_id in self.translated_chat_ids:
            return
        self.translated_chat_ids.add(chat_id)
        self.chat_id_order.append(chat_id)
        while len(self.chat_id_order) > CHAT_ID_MEMORY:
            self.translated_chat_ids.discard(self.chat_id_order.popleft())

    def load_translated_data(self):
        try:
            recv_msg = self.file_paths["recv_msg"]
            if os.path.exists(recv_msg):
                with open(recv_msg, 'r', encoding='utf-8', errors='ignore') as f:
                    for line in f:
                        parts = line.strip().split(':::')
                        if len(parts) == 6:
                            self._remember_chat_id(parts[0])
            recv_name = self.file_paths["recv_name"]
            if os.path.exists(recv_name):
                with open(recv_name, 'r', encoding='utf-8', errors='ignore') as f:
                    for line in f:
                        parts = line.strip().split(':::')
                        if len(parts) == 2:
                            self.translated_names[parts[0]] = parts[1]
            print(f"読み込み完了: 翻訳済みメッセージ {len(self.translated_chat_ids)}件, 名前 {len(self.translated_names)}件")
        except Exception as e:
            print(f"翻訳履歴の読み込みエラー: {e}")

    def _process_file(self, send_key, recv_key, process_lines_func):
        """send_*.dat を .processing に退避し、全行まとめて process_lines_func に渡す。
        Moves send_*.dat aside, then hands every line to process_lines_func at once
        so the engine can batch them."""
        send_path = self.file_paths[send_key]
        processing_path = send_path + ".processing"

        # 前回のクラッシュで残った.processingファイルを回収
        if os.path.exists(processing_path):
            if not os.path.exists(send_path):
                # send_datがない場合、processingをそのまま処理
                pass
            else:
                # 両方ある場合、processingの内容をsendに追加して再処理
                try:
                    with open(processing_path, 'r', encoding='utf-8', errors='ignore') as pf:
                        old_lines = pf.read()
                    with open(send_path, 'a', encoding='utf-8') as sf:
                        sf.write(old_lines)
                    os.remove(processing_path)
                except Exception:
                    try:
                        os.remove(processing_path)
                    except Exception:
                        pass

        if not os.path.exists(send_path) and not os.path.exists(processing_path):
            return
        if os.path.exists(send_path) and os.path.getsize(send_path) == 0:
            return

        if os.path.exists(send_path):
            try:
                os.rename(send_path, processing_path)
            except OSError:
                return

        lines_to_write = []
        try:
            with open(processing_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            lines_to_write = process_lines_func(lines)
        except Exception as e:
            print(f"{send_path} の処理中にエラー: {e}")
        finally:
            if os.path.exists(processing_path):
                os.remove(processing_path)

        if lines_to_write:
            with open(self.file_paths[recv_key], 'a', encoding='utf-8') as f:
                f.writelines(lines_to_write)

    def process_names(self):
        def _process_lines(lines):
            pending = []   # (original_name,) 翻訳が要るもの
            passthrough = []
            for line in lines:
                parts = line.strip().split(':::')
                if len(parts) != 2:
                    continue
                original_name, replace_name = parts
                if original_name in self.translated_names:
                    continue
                if original_name == replace_name:
                    pending.append(original_name)
                else:
                    passthrough.append((original_name, replace_name))

            out = []
            for original_name, replace_name in passthrough:
                self.translated_names[original_name] = replace_name
                out.append(f"{original_name}:::{replace_name}\n")

            if pending:
                translated = self.engine.translate_many(pending, dest_lang=self.lang)
                for original_name, result in zip(pending, translated):
                    replace_name = original_name
                    if result and result.lower() != original_name.lower():
                        replace_name = f"{{#FF0000}}★{{/}}{result}"
                    self.translated_names[original_name] = replace_name
                    out.append(f"{original_name}:::{replace_name}\n")
            return out

        self._process_file("send_name", "recv_name", _process_lines)

    def process_messages(self):
        def _process_lines(lines):
            rows = []
            for line in lines:
                parts = line.strip().split(':::')
                if len(parts) != 6:
                    continue
                chat_id = parts[0]
                if chat_id in self.translated_chat_ids:
                    continue
                self._remember_chat_id(chat_id)
                rows.append(parts)

            if not rows:
                return []

            translated = self.engine.translate_many([r[2] for r in rows], dest_lang=self.lang)

            out = []
            for (chat_id, msg_type, msg, sep, org_msg, org_name), result in zip(rows, translated):
                if result and result.lower() != msg.lower():
                    final_msg = f"{{#FF0000}}★{{/}}{result}"
                elif msg and msg.strip():
                    final_msg = msg
                else:
                    final_msg = "  "  # 空白でも何かしら送る
                final_org_name = self.translated_names.get(org_name, org_name)
                out.append(f"{chat_id}:::{msg_type}:::{final_msg}:::{sep}:::{org_msg}:::{final_org_name}\n")
            return out

        self._process_file("send_msg", "recv_msg", _process_lines)
        self._trim_log(self.file_paths["recv_msg"])

    def _trim_log(self, file_path, max_lines=350):
        try:
            if not os.path.exists(file_path):
                return
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            if len(lines) > max_lines:
                print(f"{file_path} が {max_lines}行を超えました。古い行を削除します。")
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.writelines(lines[-max_lines:])
        except Exception as e:
            print(f"ログの行数調整中にエラー: {e}")


class speech_processor:
    def __init__(self, base_dir, speech_lang, engine):
        self.base_dir = base_dir
        self.lang = speech_lang
        self.engine = engine
        self.send_path = os.path.join(base_dir, "my_send.dat")
        self.recv_path = os.path.join(base_dir, "my_recv.dat")
        print(f"発言翻訳プロセッサ準備完了: -> {self.lang}")

    def process(self):
        processing_path = self.send_path + ".processing"

        # 前回のクラッシュで残った.processingファイルを回収
        if os.path.exists(processing_path):
            if os.path.exists(self.send_path) and os.path.getsize(self.send_path) > 0:
                try:
                    with open(processing_path, 'r', encoding='utf-8', errors='ignore') as pf:
                        old_data = pf.read()
                    with open(self.send_path, 'a', encoding='utf-8') as sf:
                        sf.write(old_data)
                    os.remove(processing_path)
                except Exception:
                    try:
                        os.remove(processing_path)
                    except Exception:
                        pass
            # processingのみ存在 → そのまま処理続行

        if not os.path.exists(self.send_path) or os.path.getsize(self.send_path) == 0:
            if not os.path.exists(processing_path):
                return

        if not os.path.exists(processing_path):
            try:
                os.rename(self.send_path, processing_path)
            except OSError:
                return

        line = ""
        try:
            with open(processing_path, 'r', encoding='utf-8') as f:
                line = f.read().strip()
        finally:
            if os.path.exists(processing_path):
                os.remove(processing_path)

        if not line:
            return

        parts = line.split(':::')
        if len(parts) != 3:
            return

        msg_type, org_msg_return, org_msg = parts
        translated_msg = self.engine.translate(org_msg, dest_lang=self.lang)

        if translated_msg and translated_msg.lower() != org_msg.lower():
            result_line = f"{msg_type}{translated_msg}({org_msg_return})"
        else:
            result_line = f"{msg_type}{org_msg_return}"

        with open(self.recv_path, 'w', encoding='utf-8') as f:
            f.write(result_line)


class translation_manager:
    def __init__(self, base_dir):
        self.base_dir = base_dir
        self.engine = None
        self.file_processor = None
        self.speech_processor = None
        self.restart_file_path = os.path.join(base_dir, "restart.dat")
        self._stop_lock = threading.Lock()
        self._is_stopping = False
        if ACTIVE_ID:
            self.settings_path = os.path.join(self.base_dir, ACTIVE_ID, "settings.json")
        else:
            # 保険として、アカウントIDが取れなかった場合は古いパスを見る
            self.settings_path = os.path.join(self.base_dir, "settings.json")

    def _load_settings(self):
        settings = {}
        try:
            if os.path.exists(self.settings_path):
                with open(self.settings_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if content:
                        settings = json.loads(content)
        except Exception:
            pass
        return settings

    def run(self):
        settings = self._load_settings()

        deepl_api_key = settings.get("deepl_api_key") or None
        self.engine = translation_engine(deepl_api_key=deepl_api_key)

        incoming_lang = settings.get("lang") or "en"
        speech_lang = settings.get("recv_lang") or "en"

        self.file_processor = file_processor(self.base_dir, incoming_lang, self.engine)
        self.speech_processor = speech_processor(self.base_dir, speech_lang, self.engine)

        self.file_processor.load_translated_data()

        monitor = process_monitor(TOS_PROCESS_NAME, self.restart_file_path, self.stop)
        monitor.start()

        print("ファイル監視を開始しました。")

        loop_counter = 0
        while not self._is_stopping:
            try:
                if loop_counter % 10 == 0:  # 1秒ごとに設定をチェック
                    new_settings = self._load_settings()

                    new_api_key = new_settings.get("deepl_api_key") or None
                    if self.engine.deepl_api_key != new_api_key:
                        self.engine.set_deepl_api_key(new_api_key)

                    new_incoming_lang = new_settings.get("lang") or "en"
                    if self.file_processor.lang != new_incoming_lang:
                        print(f"受信チャットの翻訳言語が変更されました: {self.file_processor.lang} -> {new_incoming_lang}")
                        self.file_processor.lang = new_incoming_lang

                    new_speech_lang = new_settings.get("recv_lang") or "en"
                    if self.speech_processor.lang != new_speech_lang:
                        print(f"発言の翻訳言語が変更されました: {self.speech_processor.lang} -> {new_speech_lang}")
                        self.speech_processor.lang = new_speech_lang

                self.speech_processor.process()

                if loop_counter % 5 == 0:  # 0.5秒ごとにチャットと名前を処理
                    self.file_processor.process_names()
                    self.file_processor.process_messages()

            except Exception as e:
                show_error_and_exit("実行時エラー", f"翻訳処理中に予期せぬエラーが発生しました。\n\nエラー詳細: {e}")
                self.stop()
                break

            loop_counter = (loop_counter + 1) % 1000
            time.sleep(0.1)

    def stop(self):
        with self._stop_lock:
            if self._is_stopping:
                return
            self._is_stopping = True
        print("終了処理を開始します...")


if __name__ == "__main__":
    manager = None
    try:
        manager = translation_manager(base_dir=BASE_DIR)
        manager.run()
    except KeyboardInterrupt:
        print("\n手動で終了します...")
    except Exception as e:
        show_error_and_exit("致命的エラー", f"予期せぬエラーが発生しました。\n\nエラー詳細: {e}")
    finally:
        if manager:
            manager.stop()
        terminate_self()
