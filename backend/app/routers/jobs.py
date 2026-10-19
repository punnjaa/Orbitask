from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from fastapi import APIRouter, Header, HTTPException
from ..config import settings
from ..deps import sb
from ..services.line_client import push
from ..services.flex import digest_flex, deadline_flex

router = APIRouter(prefix="/jobs", tags=["jobs"])
TZ = ZoneInfo("Asia/Bangkok")

def _guard(secret: str):
    if secret != settings.cron_secret:
        raise HTTPException(403)

def _line_id(user_id: str):
    r = sb.table("line_links").select("line_user_id").eq("user_id", user_id) \
          .not_.is_("line_user_id", "null").execute().data
    return r[0]["line_user_id"] if r else None

@router.post("/digest")
def morning_digest(x_cron_secret: str = Header(...)):
    _guard(x_cron_secret)
    today = datetime.now(TZ).date()
    links = sb.table("line_links").select("user_id,line_user_id") \
              .not_.is_("line_user_id", "null").execute().data
    sent = 0
    for l in links:
        rows = sb.table("subtasks").select("title,minutes").eq("user_id", l["user_id"]) \
                 .eq("plan_date", today.isoformat()).eq("done", False).execute().data
        if rows:
            push(l["line_user_id"], [digest_flex(rows, today.strftime("%d/%m/%Y"))])
            sent += 1
    return {"sent": sent}

@router.post("/deadlines")
def deadline_alerts(x_cron_secret: str = Header(...)):
    _guard(x_cron_secret)
    today = datetime.now(TZ).date()
    for days, flag in [(3, "notified_d3"), (1, "notified_d1")]:
        target = (today + timedelta(days=days)).isoformat()
        tasks = sb.table("tasks").select("id,user_id,title,deadline,subjects(name,color)") \
                  .eq("deadline", target).eq(flag, False).execute().data
        for t in tasks:
            uid = _line_id(t["user_id"])
            if uid:
                s = t["subjects"]
                push(uid, [deadline_flex(s["name"], t["title"], t["deadline"], days, s["color"])])
            sb.table("tasks").update({flag: True}).eq("id", t["id"]).execute()
    return {"ok": True}
