from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class KnowledgeLevel(str, Enum):
    novice = "novice"
    intermediate = "intermediate"
    expert = "expert"


class Emotion(str, Enum):
    positive = "positive"
    neutral = "neutral"
    negative = "negative"


class GoalClarity(str, Enum):
    clear = "clear"
    ambiguous = "ambiguous"


class Urgency(str, Enum):
    high = "high"
    normal = "normal"
    low = "low"


class Stakes(str, Enum):
    high = "high"
    medium = "medium"
    low = "low"


class InteractionContext(BaseModel):
    knowledge: Optional[KnowledgeLevel] = Field(None, description="Estimated knowledge level of the user")
    emotion: Optional[Emotion] = Field(None, description="Detected emotional valence")
    clarity: Optional[GoalClarity] = Field(None, description="Clarity of the user's goal")
    urgency: Optional[Urgency] = Field(None, description="Urgency level")
    stakes: Optional[Stakes] = Field(None, description="Risk level of the task")


class StyleDecision(BaseModel):
    style: str
    matched_rule_index: int