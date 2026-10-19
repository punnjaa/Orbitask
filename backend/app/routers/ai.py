from fastapi import APIRouter, Depends, HTTPException
from ..deps import current_user
from ..schemas import BreakdownIn, BreakdownOut
from ..services.gemini import breakdown

router = APIRouter(prefix="/ai", tags=["ai"])

@router.post("/breakdown", response_model=BreakdownOut)
def ai_breakdown(body: BreakdownIn, user=Depends(current_user)):
    try:
        return breakdown(body)
    except Exception as e:
        raise HTTPException(502, f"AI error: {e}")
