from fastapi import Header, HTTPException
from supabase import create_client
from .config import settings

sb = create_client(settings.supabase_url, settings.supabase_service_key)

def current_user(authorization: str = Header(...)):
    token = authorization.removeprefix("Bearer ").strip()
    try:
        user = sb.auth.get_user(token).user
    except Exception:
        user = None
    if not user:
        raise HTTPException(401, "invalid token")
    return user
