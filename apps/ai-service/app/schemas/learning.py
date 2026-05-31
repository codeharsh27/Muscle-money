from typing import Literal

from pydantic import BaseModel, Field


class ExplainConceptRequest(BaseModel):
    concept: str = Field(min_length=2, max_length=120)
    knowledge_level: Literal["BEGINNER", "INTERMEDIATE", "ADVANCED"]
    locale: str = Field(default="en-IN", max_length=16)


class ExplainConceptResponse(BaseModel):
    concept: str
    explanation: str
    analogy: str
    quiz_prompt: str
    safety_note: str


class RecommendationRequest(BaseModel):
    knowledge_level: Literal["BEGINNER", "INTERMEDIATE", "ADVANCED"]
    goals: list[str] = Field(default_factory=list, max_length=8)
    recent_lesson_slugs: list[str] = Field(default_factory=list, max_length=20)


class RecommendationResponse(BaseModel):
    recommended_topics: list[str]
    difficulty: Literal["BEGINNER", "INTERMEDIATE", "ADVANCED"]
    reason: str

class GenerateQuizRequest(BaseModel):
    concept: str = Field(min_length=2, max_length=120)
    difficulty: Literal["BEGINNER", "INTERMEDIATE", "ADVANCED"]

class ChatMessage(BaseModel):
    text: str
    isCoach: bool

class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    history: list[ChatMessage] = Field(default_factory=list)

class ChatResponse(BaseModel):
    reply: str
