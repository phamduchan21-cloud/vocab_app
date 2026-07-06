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
                    "word": v["word"],
                    "meaning": v["meaning"],
                    "example": v.get("example", ""),
                    "topic": v.get("topic", "general"),
                })
            else:
                result.append({
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
            question_type="definition_match",
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
        )

    # ═══════════════════════════════════════════════════════════════════
    # Main builder — phân bổ câu hỏi theo tỉ lệ
    # ═══════════════════════════════════════════════════════════════════

    async def _build_questions(
        self, vocabs: list, count: int, level: str
    ) -> List[MockTestQuestion]:
        """Xây dựng câu hỏi với đa dạng loại hình và độ khó."""
        vocab_list = self._extract_vocab_data(vocabs)
        random.shuffle(vocab_list)

        if len(vocab_list) < count:
            count = len(vocab_list)
        if count <= 0:
            return []

        # ── 1. Tính số lượng mỗi loại câu hỏi ─────────────────────────
        distrib = TYPE_DISTRIBUTION.get(level, TYPE_DISTRIBUTION["intermediate"])
        targets: Dict[str, int] = {
            qt: max(1, int(count * prob)) for qt, prob in distrib.items()
        }

        total_targeted = sum(targets.values())
        if total_targeted > count:
            # Cắt bớt từ meaning_match (loại dễ nhất, linh hoạt nhất)
            targets["meaning_match"] -= (total_targeted - count)
        elif total_targeted < count:
            # Thêm vào meaning_match
            targets["meaning_match"] += (count - total_targeted)

        # Đảm bảo không âm
        for qt in targets:
            targets[qt] = max(0, targets[qt])

        word_set: Set[str] = {v["word"] for v in vocab_list}
        used_words: Set[str] = set()
        questions: List[MockTestQuestion] = []

        def _available(src: Optional[List[dict]] = None) -> List[dict]:
            pool = src if src is not None else vocab_list
            return [v for v in pool if v["word"] not in used_words]

        # ── 2. fill_blank — ưu tiên từ có câu ví dụ ─────────────────
        fb_pool = [v for v in vocab_list if len(v.get("example", "")) > 10]
        for _ in range(targets["fill_blank"]):
            avail = _available(fb_pool)
            if not avail:
                break
            v = random.choice(avail)
            q = self._make_fill_blank(v, vocab_list)
            if q:
                questions.append(q)
                used_words.add(v["word"])

        # ── 3. synonym ──────────────────────────────────────────────
        for _ in range(targets["synonym"]):
            syn_candidates = [
                v for v in _available()
                if v["word"].lower() in SYNONYM_LOOKUP
                and SYNONYM_LOOKUP[v["word"].lower()].lower() in word_set
            ]
            if not syn_candidates:
                break
            v = random.choice(syn_candidates)
            q = self._make_synonym(v, vocab_list, word_set)
            if q:
                questions.append(q)
                used_words.add(v["word"])

        # ── 4. antonym ──────────────────────────────────────────────
        for _ in range(targets["antonym"]):
            ant_candidates = [
                v for v in _available()
                if v["word"].lower() in ANTONYM_LOOKUP
                and ANTONYM_LOOKUP[v["word"].lower()].lower() in word_set
            ]
            if not ant_candidates:
                break
            v = random.choice(ant_candidates)
            q = self._make_antonym(v, vocab_list, word_set)
            if q:
                questions.append(q)
                used_words.add(v["word"])

        # ── 5. definition_match ─────────────────────────────────────
        for _ in range(targets["definition_match"]):
            avail = _available()
            if not avail:
                break
            v = random.choice(avail)
            q = self._make_definition_match(v, vocab_list)
            if q:
                questions.append(q)
                used_words.add(v["word"])

        # ── 6. meaning_match — fill nốt số còn thiếu ─────────────────
        remaining = count - len(questions)
        for _ in range(remaining):
            # Nếu hết từ chưa dùng, cho phép dùng lại (vòng 2)
            if not _available():
                used_words.clear()
            avail = _available()
            if not avail:
                break
            v = random.choice(avail)
            q = self._make_meaning_match(v, vocab_list)
            if q:
                questions.append(q)
                used_words.add(v["word"])

        random.shuffle(questions)
        return questions[:count]

    # ═══════════════════════════════════════════════════════════════════
    # Public API
    # ═══════════════════════════════════════════════════════════════════

    async def generate(
        self, user_id: str, level: str, topic: Optional[str] = None
    ) -> Tuple[str, List[MockTestQuestion], int, int]:
        """Tạo đề kiểm tra từ vựng tiếng Anh từ từ vựng của người dùng + seed data."""
        config = LEVEL_CONFIG.get(level)
        if not config:
            raise ValueError(
                f"Cấp độ không hợp lệ: {level}. "
                f"Hỗ trợ: beginner, intermediate, advanced"
            )

        count = config["total"]
        duration = config["duration"]

        # Lấy từ vựng của user
        query = select(Vocabulary).where(Vocabulary.user_id == user_id)
        if topic:
            query = query.where(Vocabulary.topic == topic)

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
            ))

        score_percent = round((correct / total) * 100, 2) if total > 0 else 0
        grade = get_grade(score_percent)

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
