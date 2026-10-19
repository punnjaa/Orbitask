import secrets
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, Header, HTTPException, Request
from ..deps import current_user, sb
from ..services.line_client import verify_signature, reply

router = APIRouter(prefix="/line", tags=["line"])
ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

@router.post("/link-code")
def create_code(user=Depends(current_user)):
    code = "".join(secrets.choice(ALPHABET) for _ in range(6))
    exp = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()
    sb.table("line_links").upsert(
        {"user_id": user.id, "link_code": code, "code_expires_at": exp}).execute()
    return {"code": code, "expires_in": 600}

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
