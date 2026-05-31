from fastapi import FastAPI

from app.api.v1.learning import router as learning_router
from app.core.settings import settings

app = FastAPI(
    title="Muscle Money AI Service",
    version="0.1.0",
    docs_url="/docs" if settings.environment != "production" else None,
)

app.include_router(learning_router, prefix="/api/v1/learning", tags=["learning"])


@app.get("/health", tags=["system"])
def health() -> dict[str, str]:
    return {"status": "ok", "service": "ai-service"}
