from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import ai, line, jobs

app = FastAPI(title="Orbitask API")
app.add_middleware(CORSMiddleware, allow_origins=["*"],  # ตอน deploy ให้ระบุโดเมนจริง
                   allow_methods=["*"], allow_headers=["*"])
app.include_router(ai.router)
app.include_router(line.router)
app.include_router(jobs.router)

@app.get("/health")
def health():
    return {"ok": True}
