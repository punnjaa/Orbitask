from pydantic import BaseModel

class BreakdownIn(BaseModel):
    subject: str
    description: str
    deadline: str                      # YYYY-MM-DD
    other_subjects: list[dict] = []    # [{"name": "...", "remaining_score": 40}]

class SubtaskOut(BaseModel):
    title: str
    plan_date: str                     # YYYY-MM-DD
    minutes: int

class BreakdownOut(BaseModel):
    workload_score: int
    reasoning: str
    subtasks: list[SubtaskOut]
