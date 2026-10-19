import base64, hashlib, hmac
import httpx
from ..config import settings

HEAD = {"Authorization": f"Bearer {settings.line_channel_token}"}

def verify_signature(body: bytes, signature: str) -> bool:
    mac = hmac.new(settings.line_channel_secret.encode(), body, hashlib.sha256).digest()
    return hmac.compare_digest(base64.b64encode(mac).decode(), signature)

def push(to: str, messages: list):
    httpx.post("https://api.line.me/v2/bot/message/push", headers=HEAD,
               json={"to": to, "messages": messages}, timeout=10).raise_for_status()

def reply(reply_token: str, text: str):
    httpx.post("https://api.line.me/v2/bot/message/reply", headers=HEAD, timeout=10,
               json={"replyToken": reply_token, "messages": [{"type": "text", "text": text}]})
