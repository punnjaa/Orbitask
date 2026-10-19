def _dur(m):
    if m >= 480 and m % 480 == 0:
        return f"{m // 480} วัน"
    if m >= 60:
        return f"{m // 60} ชม." if m % 60 == 0 else f"{m / 60:.1f} ชม."
    return f"{m} นาที"


def deadline_flex(subject, title, deadline, days_left, color="#7C6CF0"):
    return {
        "type": "flex",
        "altText": f"⏰ {subject}: {title} ส่งอีก {days_left} วัน",
        "contents": {
            "type": "bubble", "size": "kilo",
            "header": {"type": "box", "layout": "vertical", "backgroundColor": color,
                       "paddingAll": "12px",
                       "contents": [{"type": "text", "text": subject, "color": "#FFFFFF", "weight": "bold"}]},
            "body": {"type": "box", "layout": "vertical", "spacing": "sm", "contents": [
                {"type": "text", "text": title, "weight": "bold", "size": "lg", "wrap": True},
                {"type": "text", "text": f"กำหนดส่ง {deadline}", "size": "sm", "color": "#888888"},
                {"type": "text", "text": f"เหลืออีก {days_left} วัน", "size": "xl",
                 "weight": "bold", "color": "#E8590C"},
            ]},
        },
    }

def digest_flex(rows, date_th):
    items = [{"type": "text", "wrap": True, "size": "sm",
              "text": f"☐ {r['title']} · {_dur(r['minutes'])}"} for r in rows]
    return {
        "type": "flex", "altText": f"☀️ แผนวันนี้ {len(rows)} งาน",
        "contents": {"type": "bubble", "body": {"type": "box", "layout": "vertical", "spacing": "sm",
            "contents": [{"type": "text", "text": f"☀️ แผนวันนี้ ({date_th})", "weight": "bold", "size": "lg"},
                         {"type": "separator"}, *items]}},
    }
