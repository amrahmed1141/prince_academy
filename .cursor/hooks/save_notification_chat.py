#!/usr/bin/env python3
"""Append Agent Chat turns into ai/chats/notification.md + notification.jsonl.

Wired from .cursor/hooks.json:
  - beforeSubmitPrompt  → user messages
  - afterAgentResponse  → assistant final text
  - stop                → optional full transcript sync
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CHAT_DIR = ROOT / "ai" / "chats"
MD_PATH = CHAT_DIR / "notification.md"
JSONL_PATH = CHAT_DIR / "notification.jsonl"
TRANSCRIPT_COPY = CHAT_DIR / "notification.transcript.jsonl"
SESSION_IDS = CHAT_DIR / "notification.session-ids"


def _now() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def _read_stdin() -> dict:
    raw = sys.stdin.buffer.read()
    if not raw:
        return {}
    # Windows hook stdin can mangle UTF-8; prefer utf-8 then replace.
    text = raw.decode("utf-8", errors="replace")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {"_raw": text}


def _ensure_files() -> None:
    CHAT_DIR.mkdir(parents=True, exist_ok=True)
    if not MD_PATH.exists():
        MD_PATH.write_text(
            "# Notification chat log\n\n## Live turns (auto-appended)\n",
            encoding="utf-8",
        )
    if not JSONL_PATH.exists():
        JSONL_PATH.write_text("", encoding="utf-8")
    if not SESSION_IDS.exists():
        SESSION_IDS.write_text("", encoding="utf-8")


def _track_session(conversation_id: str | None) -> None:
    if not conversation_id:
        return
    known = {
        line.strip()
        for line in SESSION_IDS.read_text(encoding="utf-8").splitlines()
        if line.strip()
    }
    if conversation_id in known:
        return
    with SESSION_IDS.open("a", encoding="utf-8") as f:
        f.write(conversation_id + "\n")


def _append_jsonl(entry: dict) -> None:
    with JSONL_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def _append_md(role: str, body: str, conversation_id: str | None) -> None:
    body = (body or "").strip()
    if not body:
        return
    # Cap huge blobs so the markdown stay readable.
    if len(body) > 12000:
        body = body[:12000] + "\n\n…(truncated)…"
    header = f"### {_now()} — {role}"
    if conversation_id:
        header += f" (`{conversation_id[:8]}…`)"
    block = f"\n{header}\n\n{body}\n\n---\n"
    with MD_PATH.open("a", encoding="utf-8") as f:
        f.write(block)


def _sync_transcript(transcript_path: str | None) -> None:
    if not transcript_path:
        return
    src = Path(transcript_path)
    if not src.is_file():
        return
    try:
        TRANSCRIPT_COPY.write_bytes(src.read_bytes())
    except OSError:
        pass


def main() -> int:
    data = _read_stdin()
    _ensure_files()

    event = str(data.get("hook_event_name") or "")
    conversation_id = data.get("conversation_id")
    if isinstance(conversation_id, str):
        _track_session(conversation_id)
    else:
        conversation_id = None

    if event == "beforeSubmitPrompt":
        prompt = data.get("prompt") or ""
        _append_md("user", str(prompt), conversation_id)
        _append_jsonl(
            {
                "ts": _now(),
                "event": event,
                "role": "user",
                "conversation_id": conversation_id,
                "generation_id": data.get("generation_id"),
                "content": prompt,
            }
        )
        # Required so submission proceeds.
        print(json.dumps({"continue": True}))
        return 0

    if event == "afterAgentResponse":
        text = data.get("text") or ""
        _append_md("assistant", str(text), conversation_id)
        _append_jsonl(
            {
                "ts": _now(),
                "event": event,
                "role": "assistant",
                "conversation_id": conversation_id,
                "generation_id": data.get("generation_id"),
                "content": text,
            }
        )
        _sync_transcript(data.get("transcript_path"))
        return 0

    if event == "stop":
        _append_jsonl(
            {
                "ts": _now(),
                "event": event,
                "role": "system",
                "conversation_id": conversation_id,
                "status": data.get("status"),
                "loop_count": data.get("loop_count"),
            }
        )
        _sync_transcript(data.get("transcript_path"))
        return 0

    # Unknown event — fail open.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
