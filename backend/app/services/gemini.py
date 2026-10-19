from datetime import datetime
from zoneinfo import ZoneInfo
from google import genai
from google.genai import types
from ..config import settings
from ..schemas import BreakdownIn, BreakdownOut

client = genai.Client(api_key=settings.gemini_api_key)

def breakdown(inp: BreakdownIn) -> BreakdownOut:
    today = datetime.now(ZoneInfo("Asia/Bangkok")).date().isoformat()
    prompt = f"""คุณคือ Orbi ผู้ช่วยวางแผนการเรียนของนิสิต
วันนี้: {today}
วิชา: {inp.subject}
รายละเอียดงาน: {inp.description}
กำหนดส่ง: {inp.deadline}
งานวิชาอื่นที่ยังค้าง (ภาระคงเหลือ 1-100): {inp.other_subjects}

ทำตามนี้:
1) แตกงานเป็นขั้นตอนที่ลงมือทำได้จริง 3-10 ข้อ เรียงลำดับ
2) ใส่ plan_date (YYYY-MM-DD) ตั้งแต่วันนี้ถึงก่อนกำหนดส่งอย่างน้อย 1 วัน กระจายให้สมดุล
3) ประเมิน minutes ของแต่ละข้อ
4) ให้ workload_score 1-100 โดยเทียบกับงานวิชาอื่นข้างต้น
5) reasoning เขียนสั้นๆ ภาษาไทย
"""
    resp = client.models.generate_content(
        model=settings.gemini_model,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=BreakdownOut,
            temperature=0.4,
        ),
    )
    if resp.parsed is None:
        raise ValueError("Gemini returned no parsable result")
    return resp.parsed
