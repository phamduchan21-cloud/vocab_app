"""
AI Service — Gemini (primary) + OpenAI (fallback)

Cung cấp 3 chức năng:
1. generate_quiz_questions — Sinh câu hỏi quiz bằng AI
2. chat_with_ai — Chat với AI Tutor
3. explain_word — Giải thích từ vựng chi tiết

Strategy pattern: thử Gemini trước, nếu fail → OpenAI → raise
"""

import json
import os
from abc import ABC, abstractmethod
from typing import List, Optional

from core.config import settings


# ─── Base Provider ───────────────────────────────────────────────────


class AIProvider(ABC):
    @abstractmethod
    async def generate_quiz(
        self, vocabs: list, count: int, topic: str, level: str
    ) -> list[dict]:
        ...

    @abstractmethod
    async def generate_mock_questions(
        self, vocabs: list, count: int, level: str, topic: str
    ) -> list[dict]:
        ...

    @abstractmethod
    async def chat(self, message: str, context: dict) -> dict:
        ...

    @abstractmethod
    async def explain_word(self, word: str, meaning: str, context: str) -> dict:
        ...


# ─── Gemini Provider ────────────────────────────────────────────────


class GeminiProvider(AIProvider):
    """Google Gemini API — free tier (60 req/min)."""

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model = "gemini-2.0-flash"  # Free model (fast & capable)

    async def _call(self, prompt: str) -> str:
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not configured")

        import httpx

        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.7, "maxOutputTokens": 2048},
        }

        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(url, json=payload)
            data = response.json()

        if "candidates" not in data or not data["candidates"]:
            raise ValueError(f"Gemini API error: {data.get('error', {}).get('message', 'unknown')}")

        return data["candidates"][0]["content"]["parts"][0]["text"]

    async def generate_quiz(self, vocabs: list, count: int, topic: str, level: str) -> list[dict]:
        words_str = ", ".join([f"{v['word']} ({v['meaning']})" for v in vocabs[:20]])
        prompt = f"""You are a vocabulary quiz generator. Generate {count} multiple-choice questions.
Level: {level}
Topic: {topic}
Available words: {words_str}

Rules:
- Questions must be in Vietnamese
- 4 options per question, only 1 correct
- Mix question types: meaning_match, fill_blank, synonym, antonym
- Return ONLY valid JSON array, no markdown, no explanation

Format:
[{{"question": "...?", "options": ["A", "B", "C", "D"], "correctAnswer": "A"}}]"""
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())

    async def generate_mock_questions(self, vocabs: list, count: int, level: str, topic: str) -> list[dict]:
        words_str = ", ".join([f"{v['word']} ({v['meaning']})" for v in vocabs[:30]])
        prompt = f"""You are an English mock test generator. Generate {count} multiple-choice questions.
Level: {level}
Topic: {topic}
Available words: {words_str}

Rules:
- Questions MUST be in Vietnamese
- 4 options per question, only 1 correct
- Mix question types: meaning_match, definition_match, fill_blank, synonym, antonym
- For fill_blank: create a natural English sentence with ______
- Return ONLY valid JSON array, no markdown, no explanation

Format:
[{{"question": "...?", "options": ["A", "B", "C", "D"], "correctAnswer": "A", "question_type": "meaning_match", "difficulty": "easy"}}]"""
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())

    async def chat(self, message: str, context: dict) -> dict:
        topic = context.get("topic", "từ vựng")
        prompt = f"""You are 'Meu', an AI tutor for Vietnamese students learning English.
Be friendly, use emojis occasionally, keep answers concise (under 200 words).
Current topic: {topic}
Student's question: {message}

Return in JSON:
{{"reply": "...", "suggestions": ["Câu hỏi gợi ý 1", "Câu hỏi gợi ý 2"]}}"""
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())

    async def explain_word(self, word: str, meaning: str, context: str) -> dict:
        prompt = f"""Explain the English word "{word}" ({meaning}) for a Vietnamese learner.
Context: {context}

Return JSON:
{{"explanation": "...", "examples": ["...", "..."], "synonyms": ["...", "..."], "tips": "..."}}"""
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())


# ─── OpenAI Provider ────────────────────────────────────────────────


class OpenAIProvider(AIProvider):
    """OpenAI ChatGPT API — fallback khi Gemini fail."""

    def __init__(self):
        self.api_key = settings.OPENAI_API_KEY
        self.model = "gpt-4o-mini"  # Cheaper model

    async def _call(self, prompt: str, response_format: str = "json") -> str:
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY not configured")

        from openai import AsyncOpenAI

        client = AsyncOpenAI(api_key=self.api_key)
        response = await client.chat.completions.create(
            model=self.model,
            messages=[{"role": "system", "content": "You are a helpful English tutor. Respond in Vietnamese."},
                     {"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=2048,
        )
        return response.choices[0].message.content or ""

    async def generate_quiz(self, vocabs: list, count: int, topic: str, level: str) -> list[dict]:
        words_str = ", ".join([f"{v['word']} ({v['meaning']})" for v in vocabs[:20]])
        prompt = f"Generate {count} English vocabulary quiz questions. Level: {level}, Topic: {topic}. Words: {words_str}\nReturn JSON array."
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())

    async def generate_mock_questions(self, vocabs: list, count: int, level: str, topic: str) -> list[dict]:
        words_str = ", ".join([f"{v['word']} ({v['meaning']})" for v in vocabs[:30]])
        prompt = f"Generate {count} English mock test questions. Level: {level}, Topic: {topic}. Words: {words_str}\nMix types: meaning_match, definition_match, fill_blank, synonym, antonym. Return JSON array."
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())

    async def chat(self, message: str, context: dict) -> dict:
        topic = context.get("topic", "vocabulary")
        prompt = f"Student asks: {message}\nContext: {topic}\nReply as a friendly English tutor in Vietnamese. Return JSON with 'reply' and 'suggestions'."
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())

    async def explain_word(self, word: str, meaning: str, context: str) -> dict:
        prompt = f"Explain '{word}' ({meaning}) to a Vietnamese learner. Context: {context}. Return JSON with explanation, examples, synonyms, tips."
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())


# ─── Main AI Service ────────────────────────────────────────────────


class AIService:
    """AI Service with auto-fallback strategy."""

    def __init__(self):
        self.providers: list[AIProvider] = []
        if settings.GEMINI_API_KEY:
            self.providers.append(GeminiProvider())
        if settings.OPENAI_API_KEY:
            self.providers.append(OpenAIProvider())
        if not self.providers:
            print("[AIService] WARNING: No AI providers configured. Set GEMINI_API_KEY or OPENAI_API_KEY in .env")

    async def _call(self, fn_name: str, *args, **kwargs):
        """Try each provider in order until one succeeds."""
        errors = []
        for provider in self.providers:
            try:
                return await getattr(provider, fn_name)(*args, **kwargs)
            except Exception as e:
                errors.append(f"{provider.__class__.__name__}: {e}")
                continue
        raise Exception(f"All AI providers failed: {'; '.join(errors)}")

    async def generate_mock_questions(self, vocabs: list, count: int, level: str, topic: str) -> list[dict]:
        """Generate mock test questions — meaning_match, definition_match, fill_blank, synonym, antonym."""
        words_str = ", ".join([f"{v['word']} ({v['meaning']})" for v in vocabs[:30]])
        prompt = f"""You are an English mock test generator. Generate {count} multiple-choice questions.
Level: {level}
Topic: {topic}
Available words: {words_str}

Rules:
- Questions MUST be in Vietnamese
- 4 options per question, only 1 correct
- Mix question types: meaning_match, definition_match, fill_blank, synonym, antonym
- For fill_blank: create a natural English sentence with ______
- Return ONLY valid JSON array, no markdown, no explanation

Format:
[{{"question": "...?", "options": ["A", "B", "C", "D"], "correctAnswer": "A", "question_type": "meaning_match", "difficulty": "easy"}}]"""
        text = await self._call(prompt)
        return json.loads(text.replace("```json", "").replace("```", "").strip())

    async def generate_quiz(self, vocabs: list, count: int = 5, topic: str = "general", level: str = "intermediate") -> list[dict]:
        """Generate quiz questions using AI."""
        return await self._call("generate_quiz", vocabs, count, topic, level)

    async def chat(self, message: str, context: dict = None) -> dict:
        """Chat with AI tutor."""
        return await self._call("chat", message, context or {})

    async def explain_word(self, word: str, meaning: str = "", context: str = "") -> dict:
        """Get detailed explanation of a word."""
        return await self._call("explain_word", word, meaning, context)
