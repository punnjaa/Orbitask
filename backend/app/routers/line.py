import re
import secrets
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel
from ..deps import current_user, sb
from ..services.flex import digest_flex
from ..services.line_client import push, reply, verify_signature

router = APIRouter(prefix="/line", tags=["line"])
ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

class SettingsIn(BaseModel):
    digest_time: str = "07:00"      # HH:MM เวลาไทย
    digest_enabled: bool = True
    deadline_enabled: bool = True

@router.post("/link-code")
def create_code(user=Depends(current_user)):
    code = "".join(secrets.choice(ALPHABET) for _ in range(6))
    exp = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()
    sb.table("line_links").upsert(
        {"user_id": user.id, "link_code": code, "code_expires_at": exp}).execute()
    return {"code": code, "expires_in": 600}

@router.get("/settings")
def get_settings(user=Depends(current_user)):
    r = sb.table("line_links").select("line_user_id,digest_time,digest_enabled,deadline_enabled") \
          .eq("user_id", user.id).execute().data
    x = r[0] if r else {}
    return {
        "linked": bool(x.get("line_user_id")),
        "digest_time": (x.get("digest_time") or "07:00")[:5],
        "digest_enabled": x.get("digest_enabled", True),
        "deadline_enabled": x.get("deadline_enabled", True),
    }

@router.post("/settings")
def set_settings(body: SettingsIn, user=Depends(current_user)):
    if not re.fullmatch(r"([01]\d|2[0-3]):[0-5]\d", body.digest_time):
        raise HTTPException(400, "รูปแบบเวลาต้องเป็น HH:MM")
    sb.table("line_links").upsert({
        "user_id": user.id, "digest_time": body.digest_time,
        "digest_enabled": body.digest_enabled, "deadline_enabled": body.deadline_enabled,
        "last_digest_on": None,   # ตั้งเวลาใหม่ -> ให้ส่งได้อีกครั้งในวันนี้
    }).execute()
    return {"ok": True}

@router.post("/test")
def test_push(user=Depends(current_user)):
    r = sb.table("line_links").select("line_user_id").eq("user_id", user.id).execute().data
    if not r or not r[0].get("line_user_id"):
        raise HTTPException(400, "ยังไม่ได้เชื่อม LINE")
    rows = sb.table("subtasks").select("title,minutes").eq("user_id", user.id) \
             .eq("done", False).order("plan_date").limit(5).execute().data
    if rows:
        push(r[0]["line_user_id"], [digest_flex(rows, "ข้อความทดสอบ")])
    else:
        push(r[0]["line_user_id"], [{"type": "text", "text": "ไม่มีงานค้างเลย 🎉"}])
    return {"ok": True}

@router.post("/webhook")
async def webhook(request: Request, x_line_signature: str = Header(...)):
    body = await request.body()
    if not verify_signature(body, x_line_signature):
        raise HTTPException(403, "bad signature")
    for ev in (await request.json()).get("events", []):
        if ev.get("type") != "message" or ev["message"].get("type") != "text":
            continue
        code = ev["message"]["text"].strip().upper()
        rows = sb.table("line_links").select("user_id, code_expires_at") \
                 .eq("link_code", code).execute().data
        now = datetime.now(timezone.utc)
        valid = [r for r in rows if datetime.fromisoformat(r["code_expires_at"]) > now]
        if valid:
            sb.table("line_links").update({
                "line_user_id": ev["source"]["userId"],
                "linked_at": now.isoformat(),
                "link_code": None, "code_expires_at": None,
            }).eq("user_id", valid[0]["user_id"]).execute()
            reply(ev["replyToken"], "เชื่อมต่อ Orbitask สำเร็จแล้ว ✅")
        else:
            reply(ev["replyToken"], "รหัสไม่ถูกต้องหรือหมดอายุ ลองขอรหัสใหม่ในแอปนะ")
    return {"ok": True}
