"""A fake of the Slack Web API methods the coordinating-agents Slack scripts call.

In-memory, single workspace. It enforces what the real API (and the Docker
Sandboxes proxy) would: the token only in the Authorization header, channel
membership for reads and posts, bot-only reactions per user. Pages hold
PAGE_SIZE items so pagination is always exercised, and the first
conversations.history call answers 429 once so Retry-After handling is too.
Test-only endpoints under /test/ act as people or rogue bots.
"""

import json
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

PAGE_SIZE = int(os.environ.get("PAGE_SIZE", "2"))
# Bots whose app has only the public-channel scopes (channels:*), not groups:*.
PUBLIC_ONLY = set(filter(None, os.environ.get("FAKE_PUBLIC_ONLY", "").split(",")))
# token -> user id; users: id -> {name, is_bot}
TOKENS = dict(kv.split(":") for kv in os.environ["FAKE_TOKENS"].split(","))
USERS = {}
for spec in os.environ["FAKE_USERS"].split(","):
    uid, name, kind = spec.split(":")
    USERS[uid] = {"id": uid, "name": name, "is_bot": kind == "bot"}

lock = threading.Lock()
channels = {}  # id -> {name, members:set, messages:[...]}
clock = [1700000000_000000]
rate_limited_once = [False]
calls = {}  # method -> count, read and reset by /test/stats


def next_ts():
    clock[0] += 1000
    return f"{clock[0] // 1_000_000}.{clock[0] % 1_000_000:06d}"


def view(m, ch):
    out = {"type": "message", "ts": m["ts"], "user": m["user"], "text": m["text"]}
    if m.get("subtype"):
        out["subtype"] = m["subtype"]
    if m.get("thread_ts"):
        out["thread_ts"] = m["thread_ts"]
    replies = [r for r in ch["messages"] if r.get("thread_ts") == m["ts"] and r["ts"] != m["ts"]]
    if replies and m.get("thread_ts", m["ts"]) == m["ts"]:
        out["thread_ts"] = m["ts"]
        out["reply_count"] = len(replies)
        out["latest_reply"] = replies[-1]["ts"]
    if m.get("edited"):
        out["edited"] = {"user": m["user"], "ts": m["edited"]}
    if m["reactions"]:
        out["reactions"] = [{"name": k, "users": v, "count": len(v)} for k, v in m["reactions"].items()]
    return out


def page(items, args):
    start = int(args.get("cursor") or 0)
    limit = min(int(args.get("limit") or 100), PAGE_SIZE)
    chunk = items[start:start + limit]
    nxt = str(start + limit) if start + limit < len(items) else ""
    return chunk, {"next_cursor": nxt}


def slack_escape(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def post(ch, user, text, thread_ts=None, subtype=None):
    m = {"ts": next_ts(), "user": user, "text": text, "reactions": {}}
    if subtype:
        m["subtype"] = subtype
    if thread_ts:
        m["thread_ts"] = thread_ts
    ch["messages"].append(m)
    return m


def find(ch, ts):
    return next((m for m in ch["messages"] if m["ts"] == ts), None)


def api(method, me, a):
    def err(e):
        return {"ok": False, "error": e}

    if method == "auth.test":
        return {"ok": True, "user_id": me, "user": USERS[me]["name"], "team": "fake", "url": "https://fake.slack.com/"}
    if method == "users.info":
        u = USERS.get(a.get("user"))
        return {"ok": True, "user": u} if u else err("user_not_found")
    if method == "conversations.create":
        private = a.get("is_private") == "true"
        if private and me in PUBLIC_ONLY:
            return err("missing_scope")
        if any(c["name"] == a["name"] for c in channels.values()):
            return err("name_taken")
        cid = f"C{len(channels) + 1:04d}"
        channels[cid] = {"name": a["name"], "private": private, "members": {me}, "messages": []}
        return {"ok": True, "channel": {"id": cid, "name": a["name"], "is_private": private}}
    ch = channels.get(a.get("channel", ""))
    if ch is None:
        return err("channel_not_found")
    if me not in ch["members"]:
        return err("not_in_channel")
    if method == "conversations.invite":
        for uid in a["users"].split(","):
            if uid not in USERS:
                return err("user_not_found")
            ch["members"].add(uid)
            post(ch, uid, f"<@{uid}> has joined the channel", subtype="channel_join")
        return {"ok": True}
    if method == "conversations.history":
        top = [m for m in ch["messages"] if m.get("thread_ts", m["ts"]) == m["ts"]]
        top = [view(m, ch) for m in reversed(top)]
        chunk, meta = page(top, a)
        return {"ok": True, "messages": chunk, "has_more": bool(meta["next_cursor"]), "response_metadata": meta}
    if method == "conversations.replies":
        parent = find(ch, a["ts"])
        if parent is None:
            return err("thread_not_found")
        msgs = [parent] + [m for m in ch["messages"] if m.get("thread_ts") == a["ts"] and m["ts"] != a["ts"]]
        chunk, meta = page([view(m, ch) for m in msgs], a)
        return {"ok": True, "messages": chunk, "has_more": bool(meta["next_cursor"]), "response_metadata": meta}
    if method == "chat.postMessage":
        tts = a.get("thread_ts")
        if tts:
            parent = find(ch, tts)
            if parent is None or parent.get("thread_ts", parent["ts"]) != parent["ts"]:
                return err("thread_not_found")
        m = post(ch, me, slack_escape(a["text"]), tts)
        return {"ok": True, "channel": a["channel"], "ts": m["ts"], "message": view(m, ch)}
    if method == "reactions.add":
        m = find(ch, a["timestamp"])
        if m is None:
            return err("message_not_found")
        users = m["reactions"].setdefault(a["name"], [])
        if me in users:
            return err("already_reacted")
        users.append(me)
        return {"ok": True}
    if method == "pins.add":
        return {"ok": True} if find(ch, a["timestamp"]) else err("message_not_found")
    if method == "chat.getPermalink":
        return {"ok": True, "permalink": f"https://fake.slack.com/archives/{a['channel']}/p{a['message_ts'].replace('.', '')}"}
    return err("unknown_method")


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def send(self, code, body, headers=None):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length") or 0)).decode()
        if self.path.startswith("/test/"):
            a = json.loads(raw or "{}")
            with lock:
                ch = channels.get(a.get("channel", ""))
                if self.path == "/test/post":
                    m = post(ch, a["user"], a["text"], a.get("thread_ts"))
                    return self.send(200, {"ok": True, "ts": m["ts"]})
                if self.path == "/test/edit":
                    m = find(ch, a["ts"])
                    m["text"], m["edited"] = a["text"], next_ts()
                    return self.send(200, {"ok": True})
                if self.path == "/test/stats":
                    out = dict(calls)
                    calls.clear()
                    return self.send(200, out)
                if self.path == "/test/channels":
                    return self.send(200, {c: {"name": v["name"], "private": v["private"]} for c, v in channels.items()})
            return self.send(404, {})
        a = {k: v[0] for k, v in parse_qs(raw, keep_blank_values=True).items()}
        if "token" in a:
            return self.send(200, {"ok": False, "error": "token_in_body: the sbx proxy only substitutes headers"})
        auth = self.headers.get("Authorization", "")
        me = TOKENS.get(auth.removeprefix("Bearer "))
        if not auth.startswith("Bearer ") or me is None:
            return self.send(200, {"ok": False, "error": "not_authed"})
        method = self.path.removeprefix("/api/")
        with lock:
            calls[method] = calls.get(method, 0) + 1
        with lock:
            if method == "conversations.history" and not rate_limited_once[0]:
                rate_limited_once[0] = True
                return self.send(429, {"ok": False, "error": "ratelimited"}, {"Retry-After": "1"})
            return self.send(200, api(method, me, a))


ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
