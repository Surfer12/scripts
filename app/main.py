from fastapi import FastAPI

from .decision import decide_style
from .models import InteractionContext, StyleDecision


app = FastAPI(title="Adaptive Interaction Style API", version="0.1.0")


@app.post("/decide", response_model=StyleDecision)
async def decide_endpoint(context: InteractionContext):
    """Return the selected interaction style for a given user context."""
    decision = decide_style(context)
    return decision


@app.get("/healthz")
async def health_check():
    return {"status": "ok"}