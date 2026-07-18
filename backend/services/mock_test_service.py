import random
import re
import uuid
from typing import List, Tuple, Optional, Dict, Set

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from models import Vocabulary, MockTest
from schemas import (
    MockTestQuestion,
    MockTestAnswer,
    MockTestResultResponse,
    MockTestHistoryItem,
)
from seed_data import SEED_VOCABULARIES

# ─── Cấu hình theo cấp độ ─────────────────────────────────────────────

LEVEL_CONFIG = {
    "beginner": {"total": 10, "duration": 15},
    "intermediate": {"total": 20, "duration": 30},
    "advanced": {"total": 30, "duration": 45},
}

# ─── Tỉ lệ phân bổ loại câu hỏi theo cấp độ ───────────────────────────
# meaning_match:  "Nghĩa của từ 'X' là gì?"  (kiểm tra mặt chữ → nghĩa)
# definition_match: "Từ nào có nghĩa là 'Y'?"  (kiểm tra nghĩa → mặt chữ)
# fill_blank:  "Điền từ: 'Example with ___'"   (kiểm tra ngữ cảnh)
# synonym:  "Từ nào ĐỒNG NGHĨA với 'X'?"       (kiểm tra từ vựng nâng cao)
# antonym:  "Từ nào TRÁI NGHĨA với 'X'?"       (kiểm tra từ vựng nâng cao)

TYPE_DISTRIBUTION = {
    "beginner": {
        "meaning_match": 0.50,
        "definition_match": 0.30,
        "fill_blank": 0.10,
        "synonym": 0.05,
        "antonym": 0.05,
    },
    "intermediate": {
        "meaning_match": 0.35,
        "definition_match": 0.25,
        "fill_blank": 0.25,
        "synonym": 0.08,
        "antonym": 0.07,
    },
    "advanced": {
        "meaning_match": 0.20,
        "definition_match": 0.20,
        "fill_blank": 0.30,
        "synonym": 0.15,
        "antonym": 0.15,
    },
}

# ─── Synonym/Antonym curated pairs ────────────────────────────────────
# Only pairs where BOTH words are common English vocabulary.
# The generator checks that both words exist in the user + seed pool
# before creating a synonym/antonym question.

SYNONYM_PAIRS: List[Tuple[str, str]] = [
    # ── Beginner (30 pairs) ──────────────────────────────────────
    ("nice", "fine"),
    ("study", "learn"),
    ("shop", "store"),
    ("happy", "glad"),
    ("quick", "fast"),
    ("begin", "start"),
    ("cheap", "inexpensive"),
    ("correct", "right"),
    ("almost", "nearly"),
    ("angry", "mad"),
    ("calm", "relaxed"),
    ("tired", "exhausted"),
    ("simple", "easy"),
    ("parent", "mother"),
    ("dad", "father"),
    ("test", "exam"),
    ("task", "job"),
    ("price", "cost"),
    ("pretty", "beautiful"),
    ("smart", "intelligent"),
    ("hard", "difficult"),
    ("help", "aid"),
    ("buy", "purchase"),
    ("present", "gift"),
    ("select", "choose"),
    ("complete", "finish"),
    ("protect", "defend"),
    ("show", "display"),
    ("tell", "inform"),
    ("stop", "cease"),
    ("big", "large"),
    ("small", "tiny"),
    ("sad", "unhappy"),
    ("funny", "humorous"),
    ("kind", "gentle"),
    ("old", "elderly"),
    ("young", "youthful"),
    ("tasty", "delicious"),
    ("cute", "adorable"),
    ("brave", "courageous"),
    # ── Intermediate (40 pairs) ──────────────────────────────────
    ("important", "vital"),
    ("necessary", "essential"),
    ("famous", "well-known"),
    ("different", "distinct"),
    ("difficult", "challenging"),
    ("improve", "enhance"),
    ("increase", "boost"),
    ("decrease", "reduce"),
    ("explain", "clarify"),
    ("gather", "collect"),
    ("create", "produce"),
    ("destroy", "ruin"),
    ("connect", "link"),
    ("separate", "divide"),
    ("maintain", "sustain"),
    ("achieve", "accomplish"),
    ("consider", "regard"),
    ("require", "demand"),
    ("provide", "supply"),
    ("support", "uphold"),
    ("suggest", "propose"),
    ("demand", "insist"),
    ("establish", "found"),
    ("generate", "produce"),
    ("operate", "function"),
    ("perform", "execute"),
    ("replace", "substitute"),
    ("release", "publish"),
    ("remain", "stay"),
    ("remove", "eliminate"),
    ("require", "necessitate"),
    ("respond", "reply"),
    ("reveal", "disclose"),
    ("review", "examine"),
    ("struggle", "strive"),
    ("transform", "convert"),
    ("verify", "confirm"),
    ("witness", "observe"),
    ("abandon", "desert"),
    ("accept", "embrace"),
    # ── Advanced (30 pairs) ──────────────────────────────────────
    ("abundant", "plentiful"),
    ("accumulate", "amass"),
    ("alleviate", "relieve"),
    ("comprehend", "grasp"),
    ("confine", "restrict"),
    ("contemplate", "ponder"),
    ("convey", "communicate"),
    ("cultivate", "nurture"),
    ("diminish", "dwindle"),
    ("discern", "detect"),
    ("elevate", "uplift"),
    ("emphasize", "highlight"),
    ("endure", "persist"),
    ("flourish", "thrive"),
    ("hinder", "impede"),
    ("initiate", "commence"),
    ("interpret", "construe"),
    ("negotiate", "bargain"),
    ("obtain", "acquire"),
    ("persuade", "convince"),
    ("possess", "own"),
    ("predict", "forecast"),
    ("prohibit", "forbid"),
    ("promote", "advance"),
    ("rebel", "revolt"),
    ("remedy", "cure"),
    ("signify", "denote"),
    ("terminate", "conclude"),
    ("utilize", "employ"),
    ("warrant", "justify"),
]

ANTONYM_PAIRS: List[Tuple[str, str]] = [
    # ── Beginner (40 pairs) ──────────────────────────────────────
    ("hot", "cold"),
    ("happy", "sad"),
    ("love", "hate"),
    ("expensive", "cheap"),
    ("early", "late"),
    ("summer", "winter"),
    ("new", "old"),
    ("good", "bad"),
    ("fast", "slow"),
    ("light", "dark"),
    ("long", "short"),
    ("rich", "poor"),
    ("strong", "weak"),
    ("beautiful", "ugly"),
    ("quiet", "loud"),
    ("clean", "dirty"),
    ("safe", "dangerous"),
    ("easy", "hard"),
    ("sweet", "bitter"),
    ("day", "night"),
    ("laugh", "cry"),
    ("push", "pull"),
    ("give", "take"),
    ("buy", "sell"),
    ("win", "lose"),
    ("open", "close"),
    ("begin", "end"),
    ("sunny", "rainy"),
    ("student", "teacher"),
    ("husband", "wife"),
    ("son", "daughter"),
    ("spring", "autumn"),
    ("enter", "exit"),
    ("big", "small"),
    ("high", "low"),
    ("thick", "thin"),
    ("dry", "wet"),
    ("full", "empty"),
    ("heavy", "light"),
    ("wide", "narrow"),
    # ── Intermediate (35 pairs) ──────────────────────────────────
    ("arrival", "departure"),
    ("question", "answer"),
    ("success", "failure"),
    ("health", "sickness"),
    ("peace", "war"),
    ("love", "hate"),
    ("life", "death"),
    ("young", "elderly"),
    ("rich", "needy"),
    ("ancient", "modern"),
    ("major", "minor"),
    ("active", "passive"),
    ("increase", "decrease"),
    ("appear", "vanish"),
    ("build", "demolish"),
    ("connect", "disconnect"),
    ("construct", "destroy"),
    ("create", "annihilate"),
    ("demand", "supply"),
    ("encourage", "discourage"),
    ("expand", "shrink"),
    ("export", "import"),
    ("forward", "backward"),
    ("generous", "stingy"),
    ("guilty", "innocent"),
    ("include", "exclude"),
    ("permanent", "temporary"),
    ("polite", "rude"),
    ("possess", "lack"),
    ("praise", "criticize"),
    ("privacy", "publicity"),
    ("profit", "loss"),
    ("progress", "decline"),
    ("protection", "exposure"),
    ("succeed", "fail"),
    # ── Advanced (25 pairs) ──────────────────────────────────────
    ("abundant", "scarce"),
    ("accurate", "inaccurate"),
    ("anonymity", "fame"),
    ("artificial", "natural"),
    ("ascend", "descend"),
    ("benevolent", "malevolent"),
    ("clarity", "confusion"),
    ("compliance", "defiance"),
    ("compulsory", "voluntary"),
    ("conceal", "reveal"),
    ("diligent", "lazy"),
    ("domestic", "foreign"),
    ("elegance", "vulgarity"),
    ("flexible", "rigid"),
    ("harmony", "discord"),
    ("humble", "arrogant"),
    ("legitimate", "illegitimate"),
    ("maturity", "immaturity"),
    ("optimistic", "pessimistic"),
    ("orthodox", "unconventional"),
    ("patience", "impatience"),
    ("plentiful", "meager"),
    ("scarcity", "abundance"),
    ("superior", "inferior"),
    ("transparent", "opaque"),
]

# Build lookup dictionaries (lowercase keys)
SYNONYM_LOOKUP: Dict[str, str] = {}
for a, b in SYNONYM_PAIRS:
    SYNONYM_LOOKUP[a] = b
    SYNONYM_LOOKUP[b] = a

ANTONYM_LOOKUP: Dict[str, str] = {}
for a, b in ANTONYM_PAIRS:
    ANTONYM_LOOKUP[a] = b
    ANTONYM_LOOKUP[b] = a


def get_grade(score_percent: float) -> str:
    """Xếp loại dựa trên % điểm."""
    if score_percent >= 90:
        return "A"
    if score_percent >= 75:
        return "B"
    if score_percent >= 50:
        return "C"
    return "D"


class MockTestService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # ═══════════════════════════════════════════════════════════════════
    # Helper methods
    # ═══════════════════════════════════════════════════════════════════

    def _extract_vocab_data(self, vocabs: list) -> List[dict]:
        """Chuẩn hoá danh sách từ vựng (model ORM hoặc dict) thành list[dict]."""
        result = []
        for v in vocabs:
            if isinstance(v, dict):
                result.append({
                    "id": str(v.get("id", "")),
                    "word": v["word"],
                    "meaning": v["meaning"],
                    "example": v.get("example", ""),
                    "topic": v.get("topic", "general"),
                })
            else:
                result.append({
                    "id": str(v.id),
                    "word": v.word,
                    "meaning": v.meaning,
                    "example": v.example or "",
                    "topic": getattr(v, "topic", "general"),
                })
        return result

    def _pick_distractors(
        self,
        correct_word: str,
        correct_topic: str,
        pool: List[dict],
        value_key: str,
        count: int = 3,
        exclude_words: Optional[Set[str]] = None,
    ) -> List[str]:
        """
        Chọn `count` đáp án sai từ ngân hàng từ vựng.
        ưu tiên các từ KHÁC CHỦ ĐỀ với từ đúng → câu hỏi khó hơn.
        """
        excluded = {correct_word.lower()}
        if exclude_words:
            excluded.update(w.lower() for w in exclude_words)

        # Lọc bỏ từ đúng và các từ bị loại trừ
        filtered = [v for v in pool if v["word"].lower() not in excluded]

        # Tách làm 2 nhóm: khác chủ đề (ưu tiên) và cùng chủ đề
        different = [v[value_key] for v in filtered if v["topic"] != correct_topic]
        same = [v[value_key] for v in filtered if v["topic"] == correct_topic]

        random.shuffle(different)
        random.shuffle(same)

        chosen = different[:count]
        if len(chosen) < count:
            need = count - len(chosen)
            chosen += same[:need]

        # Fallback: nếu vẫn chưa đủ, lấy bất kỳ từ nào còn lại
        if len(chosen) < count:
            used_values = set(chosen)
            extra = [
                v[value_key] for v in filtered
                if v[value_key] not in used_values
            ]
            random.shuffle(extra)
            chosen += extra[:count - len(chosen)]

        random.shuffle(chosen)
        return chosen[:count]

    def _shuffle_options(
        self, correct: str, distractors: List[str]
    ) -> Tuple[List[str], str]:
        """Trộn đáp án đúng với các đáp án nhiễu, trả về (options, correctAnswer)."""
        # Đảm bảo không trùng lặp text
        all_values = [correct] + distractors
        if len(set(all_values)) < len(all_values):
            # Có trùng → loại bỏ trùng từ distractors
            seen = {correct}
            deduped = [correct]
            for v in distractors:
                if v not in seen:
                    seen.add(v)
                    deduped.append(v)
            all_values = deduped

        options = all_values[:]
        random.shuffle(options)
        # correctAnswer vẫn là text string → frontend so sánh text, không phải index
        return options, correct

    def _fill_blank_sentence(self, example: str, word: str) -> str:
        """Thay thế từ trong câu bằng ______ (dùng regex để tránh lỗi replace từng phần)."""
        return re.sub(
            r'\b' + re.escape(word) + r'\b',
            '______',
            example,
            count=1,
            flags=re.IGNORECASE,
        )

    # ═══════════════════════════════════════════════════════════════════
    # Question generators (mỗi loại một phương thức riêng)
    # ═══════════════════════════════════════════════════════════════════

    def _make_meaning_match(
        self, vocab: dict, pool: List[dict]
    ) -> Optional[MockTestQuestion]:
        """
        meaning_match: "Nghĩa của từ 'X' là gì?"
        Độ khó: easy
        """
        distractors = self._pick_distractors(
            vocab["word"], vocab["topic"], pool, "meaning"
        )
        if len(distractors) < 3:
            return None

        options, correct = self._shuffle_options(vocab["meaning"], distractors)
        return MockTestQuestion(
            question=f"Nghĩa của từ '{vocab['word']}' là gì?",
            options=options,
            correctAnswer=correct,
            difficulty="easy",
            question_type="meaning_match",
            skill="meaning",
            explanation=f"'{vocab['word']}' nghĩa là '{vocab['meaning']}'.",
            vocab_id=vocab.get("id") or None,
        )

    def _make_definition_match(
        self, vocab: dict, pool: List[dict]
    ) -> Optional[MockTestQuestion]:
        """
        definition_match: "Từ nào có nghĩa là 'Y'?"
        Độ khó: medium
        """
        distractors = self._pick_distractors(
            vocab["word"], vocab["topic"], pool, "word"
        )
        if len(distractors) < 3:
            return None

        options, correct = self._shuffle_options(vocab["word"], distractors)
        return MockTestQuestion(
            question=f"Từ nào có nghĩa là '{vocab['meaning']}'?",
            options=options,
            correctAnswer=correct,
            difficulty="medium",
            question_type="matching",
            skill="vocabulary",
            explanation=f"Từ phù hợp với nghĩa '{vocab['meaning']}' là '{vocab['word']}'.",
            vocab_id=vocab.get("id") or None,
        )

    def _make_fill_blank(
        self, vocab: dict, pool: List[dict]
    ) -> Optional[MockTestQuestion]:
        """
        fill_blank: "Điền từ thích hợp: 'Example with ______'"
        Độ khó: hard
        """
        example = vocab.get("example", "")
        if not example or len(example) < 5:
            return None

        blank_sentence = self._fill_blank_sentence(example, vocab["word"])
        # Nếu câu không thay đổi → từ không xuất hiện trong câu
        if blank_sentence == example:
            return None

        distractors = self._pick_distractors(
            vocab["word"], vocab["topic"], pool, "word"
        )
        if len(distractors) < 3:
            return None

        options, correct = self._shuffle_options(vocab["word"], distractors)
        return MockTestQuestion(
            question=f"Điền từ thích hợp: '{blank_sentence}'",
            options=options,
            correctAnswer=correct,
            difficulty="hard",
            question_type="fill_blank",
            skill="context",
            explanation=f"Từ đúng trong ngữ cảnh này là '{vocab['word']}'.",
            vocab_id=vocab.get("id") or None,
        )

    def _make_synonym(
        self, vocab: dict, pool: List[dict], word_set: Set[str]
    ) -> Optional[MockTestQuestion]:
        """
        synonym: "Từ nào ĐỒNG NGHĨA với 'X'?"
        Độ khó: hard — yêu cầu vốn từ rộng hơn.
        """
        wl = vocab["word"].lower()
        synonym = SYNONYM_LOOKUP.get(wl)
        if not synonym or synonym.lower() not in word_set:
            return None

        # Exclude cả từ gốc và từ đồng nghĩa khỏi distractor pool
        distractors = self._pick_distractors(
            synonym, vocab["topic"], pool, "word",
            exclude_words={vocab["word"], synonym},
        )
        if len(distractors) < 3:
            return None

        options, correct = self._shuffle_options(synonym, distractors)
        return MockTestQuestion(
            question=f"Từ nào ĐỒNG NGHĨA với '{vocab['word']}'?",
            options=options,
            correctAnswer=correct,
            difficulty="hard",
            question_type="synonym",
            skill="vocabulary",
            explanation=f"'{synonym}' đồng nghĩa với '{vocab['word']}'.",
            vocab_id=vocab.get("id") or None,
        )

    def _make_antonym(
        self, vocab: dict, pool: List[dict], word_set: Set[str]
    ) -> Optional[MockTestQuestion]:
        """
        antonym: "Từ nào TRÁI NGHĨA với 'X'?"
        Độ khó: hard — yêu cầu vốn từ rộng hơn.
        """
        wl = vocab["word"].lower()
        antonym = ANTONYM_LOOKUP.get(wl)
        if not antonym or antonym.lower() not in word_set:
            return None

        # Exclude cả từ gốc và từ trái nghĩa khỏi distractor pool
        distractors = self._pick_distractors(
            antonym, vocab["topic"], pool, "word",
            exclude_words={vocab["word"], antonym},
        )
        if len(distractors) < 3:
            return None

        options, correct = self._shuffle_options(antonym, distractors)
        return MockTestQuestion(
            question=f"Từ nào TRÁI NGHĨA với '{vocab['word']}'?",
            options=options,
            correctAnswer=correct,
            difficulty="hard",
            question_type="antonym",
            skill="vocabulary",
            explanation=f"'{antonym}' trái nghĩa với '{vocab['word']}'.",
            vocab_id=vocab.get("id") or None,
        )

    def _make_listening(
        self, vocab: dict, pool: List[dict]
    ) -> Optional[MockTestQuestion]:
        """Read an English word aloud and ask learners to choose its meaning."""
        distractors = self._pick_distractors(
            vocab["word"], vocab["topic"], pool, "meaning"
        )
        if len(distractors) < 3:
            return None
        options, correct = self._shuffle_options(vocab["meaning"], distractors)
        return MockTestQuestion(
            question="Nghe và chọn nghĩa đúng của từ được phát âm.",
            options=options,
            correctAnswer=correct,
            difficulty="medium",
            question_type="listening",
            skill="pronunciation",
            explanation=f"Từ bạn vừa nghe là '{vocab['word']}', nghĩa là '{vocab['meaning']}'.",
            audio_text=vocab["word"],
            vocab_id=vocab.get("id") or None,
        )

    def _make_sentence_order(
        self, vocab: dict, pool: List[dict]
    ) -> Optional[MockTestQuestion]:
        """Ask learners to identify the correctly ordered example sentence."""
        example = vocab.get("example", "").strip()
        words = example.split()
        if len(words) < 4:
            return None

        distractors: List[str] = []
        attempts = 0
        while len(distractors) < 3 and attempts < 20:
            shuffled = words[:]
            random.shuffle(shuffled)
            candidate = " ".join(shuffled)
            if candidate != example and candidate not in distractors:
                distractors.append(candidate)
            attempts += 1
        if len(distractors) < 3:
            return None

        options, correct = self._shuffle_options(example, distractors)
        return MockTestQuestion(
            question="Chọn câu được sắp xếp đúng.",
            options=options,
            correctAnswer=correct,
            difficulty="hard",
            question_type="sentence_order",
            skill="grammar",
            explanation=f"Trật tự đúng là: {example}",
            vocab_id=vocab.get("id") or None,
        )

    # ═══════════════════════════════════════════════════════════════════
    # Main builder — phân bổ câu hỏi theo tỉ lệ
    # ═══════════════════════════════════════════════════════════════════

    async def _build_questions(
        self, vocabs: list, count: int, level: str
    ) -> List[MockTestQuestion]:
        """Build a balanced test and avoid long runs of one question type."""
        vocab_list = self._extract_vocab_data(vocabs)
        random.shuffle(vocab_list)
        if not vocab_list or count <= 0:
            return []

        type_cycles = {
            "beginner": [
                "meaning_match", "listening", "matching", "fill_blank",
                "sentence_order",
            ],
            "intermediate": [
                "fill_blank", "listening", "matching", "sentence_order",
                "meaning_match", "synonym", "antonym",
            ],
            "advanced": [
                "sentence_order", "fill_blank", "listening", "synonym",
                "antonym", "matching", "meaning_match",
            ],
        }
        cycle = type_cycles.get(level, type_cycles["intermediate"])
        word_set: Set[str] = {v["word"].lower() for v in vocab_list}
        used_indexes: Set[int] = set()
        questions: List[MockTestQuestion] = []
        attempts = 0

        while len(questions) < count and attempts < count * len(cycle) * 4:
            question_type = cycle[attempts % len(cycle)]
            available = [
                (index, vocab) for index, vocab in enumerate(vocab_list)
                if index not in used_indexes
            ]
            if not available:
                used_indexes.clear()
                available = list(enumerate(vocab_list))
            index, vocab = random.choice(available)

            if question_type == "fill_blank":
                question = self._make_fill_blank(vocab, vocab_list)
            elif question_type == "listening":
                question = self._make_listening(vocab, vocab_list)
            elif question_type == "matching":
                question = self._make_definition_match(vocab, vocab_list)
            elif question_type == "sentence_order":
                question = self._make_sentence_order(vocab, vocab_list)
            elif question_type == "synonym":
                question = self._make_synonym(vocab, vocab_list, word_set)
            elif question_type == "antonym":
                question = self._make_antonym(vocab, vocab_list, word_set)
            else:
                question = self._make_meaning_match(vocab, vocab_list)

            if question is not None:
                questions.append(question)
                used_indexes.add(index)
            attempts += 1

        # Sparse example/synonym data can leave gaps; meaning questions are safe.
        while len(questions) < count:
            vocab = random.choice(vocab_list)
            question = self._make_meaning_match(vocab, vocab_list)
            if question is None:
                break
            questions.append(question)

        return questions[:count]

    # ═══════════════════════════════════════════════════════════════════
    # Public API
    # ═══════════════════════════════════════════════════════════════════

    async def generate(
        self,
        user_id: str,
        level: str,
        topic: Optional[str] = None,
        question_count: int = 10,
        duration_minutes: int = 10,
        purpose: str = "general",
    ) -> Tuple[str, List[MockTestQuestion], int, int]:
        """Tạo đề kiểm tra từ vựng tiếng Anh từ từ vựng của người dùng + seed data."""
        config = LEVEL_CONFIG.get(level)
        if not config:
            raise ValueError(
                f"Cấp độ không hợp lệ: {level}. "
                f"Hỗ trợ: beginner, intermediate, advanced"
            )

        count = max(5, min(question_count, 20))
        duration = max(2, min(duration_minutes, 60))

        # Lấy từ vựng của user
        query = select(Vocabulary).where(Vocabulary.user_id == user_id)
        if topic:
            query = query.where(Vocabulary.topic == topic)
        if purpose == "weak":
            query = query.order_by(
                (Vocabulary.times_wrong - Vocabulary.times_correct).desc(),
                Vocabulary.next_review_date.asc(),
            )
        elif purpose == "due_review":
            query = query.order_by(Vocabulary.next_review_date.asc())

        result = await self.db.execute(query)
        all_vocabs = list(result.scalars().all())

        # Kết hợp với seed data
        seed_vocabs = SEED_VOCABULARIES
        if topic:
            seed_vocabs = [v for v in seed_vocabs if v.get("topic") == topic]
        combined = list(all_vocabs) + seed_vocabs

        if len(combined) < count:
            # Nếu vẫn không đủ, fallback AI generate
            try:
                from services.ai_service import AIService
                ai = AIService()
                vocab_data = []
                seen = set()
                for v in combined:
                    if isinstance(v, dict):
                        w = v.get("word", "")
                        m = v.get("meaning", "")
                    else:
                        w = v.word
                        m = v.meaning
                    if w.lower() not in seen:
                        vocab_data.append({"word": w, "meaning": m})
                        seen.add(w.lower())

                # Bổ sung thêm seed data nếu thiếu ngữ cảnh
                if len(vocab_data) < 10:
                    for s in SEED_VOCABULARIES:
                        w = s.get("word", "")
                        if w.lower() not in seen:
                            vocab_data.append({"word": w, "meaning": s.get("meaning", "")})
                            seen.add(w.lower())
                            if len(vocab_data) >= 30:
                                break

                ai_questions = await ai.generate_mock_questions(
                    vocabs=vocab_data,
                    count=count,
                    level=level,
                    topic=topic or "general",
                )

                # Convert AI questions to MockTestQuestion format
                questions = []
                for q in ai_questions:
                    questions.append(MockTestQuestion(
                        question=q.get("question", ""),
                        options=q.get("options", []),
                        correctAnswer=q.get("correctAnswer", ""),
                        difficulty=q.get("difficulty", level),
                        question_type=q.get("question_type", "meaning_match"),
                    ))

                test_id = str(uuid.uuid4())
                return test_id, questions[:count], count, duration

            except Exception as e:
                raise ValueError(
                    f"Không đủ từ vựng (cần {count}, có {len(combined)}) "
                    f"và AI không khả dụng: {e}"
                )

        questions = await self._build_questions(combined, count, level)

        test_id = str(uuid.uuid4())
        return test_id, questions, count, duration

    async def submit(
        self,
        user_id: str,
        test_id: str,
        answers: List[MockTestAnswer],
        topic: Optional[str] = None,
        duration_seconds: int = 0,
        purpose: str = "general",
        difficulty: str = "intermediate",
    ) -> MockTestResultResponse:
        """Chấm điểm bài kiểm tra và lưu kết quả."""
        correct = 0
        total = len(answers)
        graded_answers = []

        for answer in answers:
            # So sánh text — không phải index — nên vẫn đúng sau shuffle
            is_correct = answer.selected == answer.correct_answer
            if is_correct:
                correct += 1
            graded_answers.append(MockTestAnswer(
                question=answer.question,
                options=answer.options,
                selected=answer.selected,
                correct_answer=answer.correct_answer,
                is_correct=is_correct,
                question_type=answer.question_type,
                skill=answer.skill,
                explanation=answer.explanation,
                audio_text=answer.audio_text,
                vocab_id=answer.vocab_id,
            ))

        score_percent = round((correct / total) * 100, 2) if total > 0 else 0
        grade = get_grade(score_percent)
        breakdown: Dict[str, dict] = {}
        for answer in graded_answers:
            skill = answer.skill or "vocabulary"
            stats = breakdown.setdefault(skill, {"correct": 0, "total": 0})
            stats["total"] += 1
            if answer.is_correct:
                stats["correct"] += 1
        for stats in breakdown.values():
            stats["percent"] = round(
                stats["correct"] * 100 / stats["total"], 1
            ) if stats["total"] else 0

        difficulty_multiplier = {
            "beginner": 1.0,
            "intermediate": 1.25,
            "advanced": 1.5,
        }.get(difficulty, 1.0)
        xp_earned = int(correct * 10 * difficulty_multiplier)
        if total > 0 and correct == total:
            xp_earned += 50
        badge = None
        if score_percent == 100:
            badge = "Bưu kiện hoàn hảo"
        elif score_percent >= 90:
            badge = "Tem vàng tri thức"
        elif score_percent >= 75:
            badge = "Chuyến thư bền bỉ"

        # Xác định test_level dựa trên số lượng câu
        if total <= 10:
            test_level = "beginner"
        elif total <= 20:
            test_level = "intermediate"
        else:
            test_level = "advanced"

        result = MockTest(
            id=test_id,
            user_id=user_id,
            test_level=test_level,
            total_questions=total,
            correct_answers=correct,
            score_percent=score_percent,
            grade=grade,
            topic=topic,
            answers=[a.model_dump() for a in graded_answers],
        )
        self.db.add(result)
        await self.db.commit()
        await self.db.refresh(result)

        try:
            from services.gamification_service import GamificationService
            from schemas import RecordActivityRequest

            gamification = GamificationService(self.db)
            await gamification.record_activity(
                user_id=user_id,
                request=RecordActivityRequest(
                    activity_type="quiz",
                    xp_earned=xp_earned,
                    metadata={
                        "source": "mini_test",
                        "purpose": purpose,
                        "difficulty": difficulty,
                        "score": score_percent,
                    },
                ),
            )
        except Exception:
            pass

        return MockTestResultResponse(
            id=str(result.id),
            test_level=result.test_level,
            total_questions=result.total_questions,
            correct_answers=result.correct_answers,
            score_percent=float(result.score_percent),
            grade=result.grade or "C",
            topic=result.topic,
            details=result.answers,
            completed_at=result.completed_at,
            duration_seconds=duration_seconds,
            xp_earned=xp_earned,
            badge=badge,
            breakdown=breakdown,
        )

    async def get_history(
        self, user_id: str, page: int = 1, limit: int = 20
    ) -> Tuple[List[MockTestHistoryItem], int]:
        """Lấy lịch sử kiểm tra."""
        base_query = select(MockTest).where(MockTest.user_id == user_id)
        count_query = select(func.count()).select_from(base_query.subquery())
        total = await self.db.scalar(count_query) or 0

        query = (
            base_query
            .order_by(MockTest.completed_at.desc())
            .offset((page - 1) * limit)
            .limit(limit)
        )
        result = await self.db.execute(query)
        items = list(result.scalars().all())

        history = [
            MockTestHistoryItem(
                id=str(m.id),
                test_level=m.test_level,
                total_questions=m.total_questions,
                correct_answers=m.correct_answers,
                score_percent=float(m.score_percent),
                grade=m.grade or "C",
                topic=m.topic,
                completed_at=m.completed_at,
            )
            for m in items
        ]

        return history, total

    async def get_available_topics(self, user_id: str) -> list:
        """Lấy danh sách chủ đề có thể kiểm tra (từ user vocab + seed data)."""
        query = (
            select(Vocabulary.topic)
            .where(
                Vocabulary.user_id == user_id,
                Vocabulary.topic.isnot(None),
                Vocabulary.topic != "",
            )
            .distinct()
        )
        result = await self.db.execute(query)
        user_topics = [row[0] for row in result.fetchall()]

        seed_topics = list(set(
            v.get("topic", "general") for v in SEED_VOCABULARIES
            if v.get("topic")
        ))

        union = list(set(user_topics + seed_topics))
        union.sort()
        return union
