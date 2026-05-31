from fastapi import APIRouter

from app.schemas.learning import (
    ExplainConceptRequest,
    ExplainConceptResponse,
    RecommendationRequest,
    RecommendationResponse,
    GenerateQuizRequest,
    ChatRequest,
    ChatResponse,
)
from app.core.llm_service import LLMService

router = APIRouter()


@router.post("/explain", response_model=ExplainConceptResponse)
async def explain_concept(payload: ExplainConceptRequest) -> ExplainConceptResponse:
    result = await LLMService.generate_explanation(payload.concept, payload.knowledge_level)
    return ExplainConceptResponse(
        concept=payload.concept,
        explanation=result.get("explanation", "Error generating explanation"),
        analogy=result.get("analogy", ""),
        quiz_prompt=result.get("quiz_prompt", ""),
        safety_note=result.get("safety_note", "Educational content only. Deterministic backend services own all money movement."),
    )


@router.post("/recommend", response_model=RecommendationResponse)
def recommend_next(payload: RecommendationRequest) -> RecommendationResponse:
    topics_by_level = {
        "BEGINNER": ["budgeting basics", "emergency funds", "simple interest"],
        "INTERMEDIATE": ["index funds", "risk diversification", "inflation"],
        "ADVANCED": ["asset allocation", "portfolio volatility", "tax-aware investing"],
    }
    return RecommendationResponse(
        recommended_topics=topics_by_level[payload.knowledge_level],
        difficulty=payload.knowledge_level,
        reason="Recommended from declared knowledge level and learning goals.",
    )

@router.post("/quiz")
async def generate_quiz(payload: GenerateQuizRequest) -> dict:
    return await LLMService.generate_quiz(payload.concept, payload.difficulty)

@router.post("/chat", response_model=ChatResponse)
async def chat(payload: ChatRequest) -> ChatResponse:
    reply = await LLMService.chat(payload.message, payload.history)
    return ChatResponse(reply=reply)
