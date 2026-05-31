FROM python:3.11-slim
WORKDIR /app
COPY apps/ai-service/pyproject.toml .
RUN pip install --no-cache-dir fastapi "uvicorn[standard]" pydantic-settings google-generativeai
COPY apps/ai-service/app app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
