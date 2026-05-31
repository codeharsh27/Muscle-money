import os
import json
from google import genai
from google.genai import types
from openai import OpenAI

from app.core.settings import settings

# Configure Gemini (new SDK)
GEMINI_API_KEY = settings.gemini_api_key
gemini_client = genai.Client(api_key=GEMINI_API_KEY) if GEMINI_API_KEY else None

# Configure OpenRouter Fallback
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
openrouter_client = OpenAI(
  base_url="https://openrouter.ai/api/v1",
  api_key=OPENROUTER_API_KEY,
) if OPENROUTER_API_KEY else None

GEMINI_MODEL = settings.gemini_model

SYSTEM_PROMPT = (
    "You are Nova, the Muscle Money AI Coach — a highly intelligent, warm, and highly knowledgeable senior friend/mentor who makes finance simple, fun, and extremely valuable. "
    "You teach users about personal finance, saving, budgeting, investing concepts, and the Muscle Money app (simulator, wallet, etc.). "
    "Always greet the user warmly and with high energy (using terms like 'champ', 'bro', 'my friend', or their real name if provided in the context). "
    "Be extremely helpful in EVERYTHING they ask. You have access to their full app context (wallet, portfolio, learning progress) — use it dynamically to give highly personalized, contextual advice. "
    "Keep answers conversational but feel free to give detailed step-by-step guidance when needed. "
    "Use simple language, relatable analogies, and emojis. "
    "NEVER give specific regulated financial advice (like 'buy X stock now'), but DO educate them on how to analyze it. "
    "Respond only as Nova."
)


class LLMService:
    @staticmethod
    async def generate_explanation(concept: str, knowledge_level: str) -> dict:
        prompt = (
            f"Explain the concept of '{concept}' to a student with a '{knowledge_level}' knowledge level. "
            "Keep it engaging, simple, and safe. Do not give investment advice. "
            "Return a JSON object with: 'explanation' (the main text), 'analogy' (a simple analogy), "
            "'quiz_prompt' (a single question to test understanding), and 'safety_note' (a warning that this is educational)."
        )
        result_text = await LLMService._call_llm(prompt, expect_json=True)
        try:
            return json.loads(result_text)
        except json.JSONDecodeError:
            return {
                "explanation": "Failed to generate explanation.",
                "analogy": "",
                "quiz_prompt": "",
                "safety_note": "Educational content only. Not financial advice."
            }

    @staticmethod
    async def generate_quiz(concept: str, difficulty: str) -> dict:
        prompt = (
            f"Generate a 3-question multiple choice quiz about '{concept}' at a '{difficulty}' difficulty. "
            "Return the result strictly as a JSON object with a 'questions' array, where each question has "
            "'id', 'question', 'options' (array of 'id' and 'text'), and 'answerId'."
        )
        result_text = await LLMService._call_llm(prompt, expect_json=True)
        try:
            return json.loads(result_text)
        except json.JSONDecodeError:
            return {"error": "Failed to generate valid JSON quiz."}

    @staticmethod
    async def chat(message: str, history: list) -> str:
        # Build conversation history from Pydantic models
        history_lines = []
        for msg in history[-10:]:
            speaker = "Nova" if msg.isCoach else "User"
            history_lines.append(f"{speaker}: {msg.text}")

        history_text = "\n".join(history_lines)

        nl = "\n"
        full_prompt = (
            f"{SYSTEM_PROMPT}\n\n"
            f"{'Conversation so far:' + nl + history_text + nl + nl if history_text else ''}"
            f"User: {message}\n"
            f"Nova:"
        )

        return await LLMService._call_llm(full_prompt, expect_json=False)

    @staticmethod
    async def _call_llm(prompt: str, expect_json: bool = False) -> str:
        import asyncio

        # Primary: OpenRouter (uses openai/gpt-4o)
        if openrouter_client:
            try:
                def _openrouter_call():
                    return openrouter_client.chat.completions.create(
                        model="openai/gpt-4o",
                        messages=[
                            {"role": "system", "content": SYSTEM_PROMPT},
                            {"role": "user", "content": prompt}
                        ],
                        response_format={"type": "json_object"} if expect_json else None,
                    )
                completion = await asyncio.to_thread(_openrouter_call)
                content = completion.choices[0].message.content
                if content:
                    return content.strip()
            except Exception as e:
                print(f"OpenRouter API failed: {e}. Trying Gemini fallback...")

        # Fallback: direct Gemini (new SDK)
        if gemini_client:
            try:
                config = types.GenerateContentConfig(
                    system_instruction=SYSTEM_PROMPT,
                    response_mime_type="application/json" if expect_json else "text/plain",
                )
                def _gemini_call():
                    return gemini_client.models.generate_content(
                        model=GEMINI_MODEL,
                        contents=prompt,
                        config=config,
                    )
                response = await asyncio.to_thread(_gemini_call)
                if response.text:
                    return response.text.strip()
            except Exception as e:
                print(f"Gemini API failed: {e}.")

        return '{"error": "AI Service unavailable."}' if expect_json else "AI Service is currently unavailable."
