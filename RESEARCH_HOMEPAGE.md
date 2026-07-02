# 🔬 Nghiên cứu & Giải pháp — Trang Chủ (Dashboard / Home Screen)

> **Ngày cập nhật:** 30/06/2026
> **Mục tiêu:** Phân tích UI/UX của các app học ngôn ngữ hàng đầu (Duolingo, TOPIK, Memrise, Quizlet) và đề xuất giải pháp tối ưu cho trang chủ của Ứng dụng Học Từ Vựng.

---

## 📑 Mục lục

1. [Phân tích đối thủ](#1-phân-tích-đối-thủ)
   - [1.1 Duolingo](#11-duolingo)
   - [1.2 TOPIK Study Apps](#12-topik-study-apps)
   - [1.3 Memrise](#13-memrise)
   - [1.4 Quizlet](#14-quizlet)
2. [So sánh ưu nhược điểm](#2-so-sánh-ưu-nhược-điểm)
3. [Nguyên lý thiết kế Home Page](#3-nguyên-lý-thiết-kế-home-page)
4. [Giải pháp đề xuất — Chi tiết](#4-giải-pháp-đề-xuất--chi-tiết)
5. [Gamification System](#5-gamification-system)
6. [Widget Tree đề xuất](#6-widget-tree-đề-xuất)
7. [Data Flow cho Home Page](#7-data-flow-cho-home-page)
8. [API endpoints cần thêm](#8-api-endpoints-cần-thêm)
9. [Wireframe (text-based)](#9-wireframe-text-based)
10. [Kế hoạch triển khai](#10-kế-hoạch-triển-khai)

---

## 1. Phân tích đối thủ

### 1.1 Duolingo

> **Mô hình:** App học ngôn ngữ số 1 thế giới — gamification cực mạnh.

#### 🎯 Bố cục Home Screen

```
┌──────────────────────────────┐
│  🔥 12   ⭐ 450   💎 2300   │  ← Streak + XP + Gems (top bar)
│  📅 Học xong hôm nay!       │  ← Daily goal status
├──────────────────────────────┤
│  Unit 5: Travel             │
│  ┌────────────────────────┐ │
│  │  ○ → ○ → ○ → ● → ●    │ │  ← Learning path (dạng snake)
│  │              ↓          │ │
│  │  ○ → ★(bài test) → ○   │ │
│  │              ↓          │ │
│  │  ○ → ○ → ○ → ○         │ │
│  └────────────────────────┘ │
│                              │
│  [📘 Bài học hôm nay]       │  ← CTA chính
├──────────────────────────────┤
│  🏆 League: Gold (top 5)    │  ← Bảng xếp hạng
│  👥 Bạn bè: 3 online        │
│  📊 Thống kê tuần           │
└──────────────────────────────┘
```

#### 🔑 Tính năng chính

| Tính năng | Mô tả | Tác dụng |
|-----------|-------|----------|
| **Streak (🔥)** | Số ngày học liên tiếp | Tạo thói quen daily |
| **Daily Goal** | Mục tiêu XP mỗi ngày | Giữ người dùng quay lại |
| **Learning Path** | Đường đi tuần tự theo unit | Cấu trúc rõ ràng |
| **Leagues (🏆)** | Bảng xếp hạng tuần | Cạnh tranh xã hội |
| **Gems (💎)** | Tiền ảo — mua streak freeze, power-ups | Kinh tế vi mô |
| **Hearts (❤️)** | Mạng sống — sai mất tim | Tăng focus |
| **Notifications** | Push nhắc nhở hàng ngày | Retention |

#### ⚡ Cơ chế Gamification

```
Input (học)          → Output (phần thưởng)
──────────────────────────────────────────
Mỗi bài học          → +10-20 XP
Daily goal đạt       → +5 gems + streak duy trì
Streak 7 ngày        → +50 gems + huy hiệu
Lên rank             → +200 gems
Hoàn thành unit      → Mở khoá unit mới + crown
```

---

### 1.2 TOPIK Study Apps

> **Mô hình:** Các app luyện thi TOPIK (Hàn ngữ) — tập trung vào ôn thi, học theo cấp độ.

#### 🎯 Bố cục Home Screen điển hình

```
┌──────────────────────────────┐
│  🇰🇷 TOPIK II 준비           │
│  🔥 5일 연속                │
├──────────────────────────────┤
│  📊 TIẾN ĐỘ ÔN THI          │
│  ┌──────────────────────┐   │
│  │  Từ vựng: ████░░ 60% │   │
│  │  Ngữ pháp: ██░░ 30%  │   │
│  │  Đọc hiểu: █████ 50% │   │
│  └──────────────────────┘   │
├──────────────────────────────┤
│  CẤP ĐỘ TOPIK              │
│  [TOPIK 1] [TOPIK 2] [3-4] │
│                              │
│  📂 Từ vựng theo chủ đề    │
│  ┌───┬───┬───┬───┬───┐    │
│  │Sinh│Công│Gia │Du  │YTế │
│  │hoạt│việc│đình│lịch│    │
│  └───┴───┴───┴───┴───┘    │
├──────────────────────────────┤
│  📝 Luyện đề             │
│  [Đề 64회] [Đề 83회] ...  │
├──────────────────────────────┤
│  ⏰ Ôn tập hôm nay: 15 từ │
│  [Bắt đầu ôn tập]          │
└──────────────────────────────┘
```

#### 🔑 Tính năng chính

| Tính năng | Mô tả | Ghi chú |
|-----------|-------|---------|
| **Level-based** | Phân cấp TOPIK 1, 2, 3-6 | Mục tiêu rõ ràng |
| **Progress bars** | % hoàn thành từng kỹ năng | Động lực cải thiện |
| **Topic-based vocab** | Từ vựng chia chủ đề | Học có hệ thống |
| **Mock tests** | Đề thi thử các năm | Luyện thi thực tế |
| **Spaced Repetition** | Ôn tập theo lịch trình | Ghi nhớ lâu dài |

---

### 1.3 Memrise

> **Mô hình:** Học từ vựng qua flashcard + video người bản xứ.

#### 🎯 Bố cục Home Screen

```
┌──────────────────────────────┐
│  🌱 Memrise                 │
│  🔥 Day 45  |  XP: 2,400   │
├──────────────────────────────┤
│  📋 TIẾP TỤC HỌC           │
│  ┌──────────────────────┐   │
│  │  Level 3: Greetings  │   │
│  │  ████████░░ 80%      │   │
│  │  [Tiếp tục →]         │   │
│  └──────────────────────┘   │
├──────────────────────────────┤
│  🔄 ÔN TẬP HÔM NAY          │
│  12 từ cần ôn               │
│  [Bắt đầu ôn tập]           │
├──────────────────────────────┤
│  📂 KHOÁ HỌC               │
│  ┌──────┐ ┌──────┐ ┌─────┐ │
│  │Tiếng │ │Du lịch│ │Công │ │
│  │ Nhật │ │       │ │việc │ │
│  └──────┘ └──────┘ └─────┘ │
└──────────────────────────────┘
```

#### 🔑 Tính năng chính

| Tính năng | Tác dụng |
|-----------|----------|
| **Learn → Review cycle** | Học mới → ôn cũ — spaced repetition tự nhiên |
| **Video clips** | Nghe người bản xứ — phát âm chuẩn |
| **Difficulty progress** | Cảm giác "lên level" rõ rệt |
| **Grow system** | "Trồng" từ vựng — tưới cây bằng ôn tập |

---

### 1.4 Quizlet

> **Mô hình:** Flashcard học tập đa năng.

#### 🎯 Bố cục Home Screen

```
┌──────────────────────────────┐
│  🔍 Tìm kiếm bộ thẻ...      │
├──────────────────────────────┤
│  📚 BỘ THẺ CỦA BẠN          │
│  ┌────────────────────────┐  │
│  │  🌸 Từ vựng tiếng Nhật │  │
│  │  24 thuật ngữ · Đã học │  │
│  ├────────────────────────┤  │
│  │  📖 Kanji N3           │  │
│  │  50 thuật ngữ · 30%    │  │
│  ├────────────────────────┤  │
│  │  📝 TOPIK vocabulary   │  │
│  │  100 thuật ngữ · Mới   │  │
│  └────────────────────────┘  │
├──────────────────────────────┤
│  ⚡ HỌC NHANH                │
│  [Flashcard] [Kiểm tra] [Ghép] │
└──────────────────────────────┘
```

#### 🔑 Tính năng chính

| Tính năng | Tác dụng |
|-----------|----------|
| **Flashcard (học nhanh)** | Tối giản, focus |
| **Learn mode** | Học có hệ thống |
| **Test mode** | Kiểm tra tổng hợp |
| **Match game** | Ghép từ — học mà chơi |
| **Sets organization** | Người dùng tự tạo bộ |

---

## 2. So sánh ưu nhược điểm

| Tiêu chí | Duolingo | TOPIK apps | Memrise | Quizlet |
|----------|----------|------------|---------|---------|
| **Streak (liên tiếp)** | ✅ Cực mạnh | ✅ Có | ✅ Có | ❌ Không |
| **Learning path** | ✅ Rõ ràng | ❌ Không | ✅ Có | ❌ Không |
| **Spaced repetition** | ❌ Không | ✅ Có | ✅ Có | ✅ Có |
| **Gamification** | ✅ Xuất sắc | ⚠️ Trung bình | ✅ Tốt | ⚠️ Trung bình |
| **Social/League** | ✅ Có | ❌ Không | ❌ Không | ✅ Có (classes) |
| **Topic organization** | ✅ Theo unit | ✅ Theo cấp độ | ✅ Khoá học | ✅ Bộ thẻ |
| **Daily goal** | ✅ Rõ ràng | ✅ Có | ✅ Có | ⚠️ Cơ bản |
| **Progress tracking** | ✅ Chi tiết | ✅ Biểu đồ | ✅ Cơ bản | ✅ Cơ bản |
| **Mock exams** | ❌ Không | ✅ Trọng tâm | ❌ Không | ✅ Test mode |
| **Offline mode** | ✅ Có | ⚠️ Tuỳ app | ✅ Có | ✅ Có |
| **Spaced Review** | ❌ Yếu | ✅ Tốt | ✅ Tốt | ✅ Learn mode |

---

## 3. Nguyên lý thiết kế Home Page

### 3.1 Mục tiêu của Home Page

1. **Kích hoạt habit** — Người dùng mở app → muốn học NGAY
2. **Hiển thị tiến độ** — Cho thấy "hôm nay đã học gì, còn bao nhiêu"
3. **Động lực ngắn hạn** — Streak, daily goal, phần thưởng
4. **Định hướng dài hạn** — Tổng quan hành trình từ vựng
5. **Giảm friction** — Càng ít bước để bắt đầu học càng tốt

### 3.2 Nguyên tắc thiết kế

| # | Nguyên tắc | Áp dụng |
|---|------------|---------|
| 1 | **Above the fold = CTA chính** | Nút "Học ngay" / "Ôn tập" phải thấy ngay |
| 2 | **Streak là vua** | Hiển thị streak to, rõ, kích thích giữ streak |
| 3 | **Progress = dopamine** | Progress bar, % hoàn thành, level |
| 4 | **F-shaped scanning** | Người dùng đọc theo chữ F → quan trọng nhất ở trên |
| 5 | **Less is more** | Không quá 5-7 section trên home |
| 6 | **Personalization** | "Chào mừng trở lại, Nam" — cảm giác cá nhân |
| 7 | **Visual hierarchy** | Kích thước, màu sắc dẫn mắt đến hành động chính |

---

## 4. Giải pháp đề xuất — Chi tiết

### 🏆 Tầm nhìn

> **"Duolingo-style engagement + TOPIK-level content + Spaced Repetition"**

Kết hợp sức hút gamification của Duolingo, tính hệ thống của TOPIK,
và khoa học ghi nhớ của spaced repetition — tối ưu cho học từ vựng tiếng Hàn.

---

### 4.1 Home Screen — Bố cục

```
┌──────────────────────────────────────┐
│  🔥 Streak bar (ngang)              │  ← SECTION 1: TOP BAR
│  ┌──────┬──────────┬──────────────┐ │
│  │ 🔥 12 │ 📊 Học xong│ 💎 2,300  │ │
│  │ ngày  │  78% tuần │            │ │
│  └──────┴──────────┴──────────────┘ │
├──────────────────────────────────────┤
│                                      │
│  📖 ÔN TẬP HÔM NAY                  │  ← SECTION 2: REVIEW (spaced rep)
│  ┌──────────────────────────────┐   │
│  │  📚 5 từ cần ôn hôm nay      │   │
│  │  ████████████░░ 2/5          │   │
│  │  [        Ôn tập ngay →     ]│   │  ← CTA chính #1
│  └──────────────────────────────┘   │
│                                      │
│  📘 HỌC TỪ MỚI                      │  ← SECTION 3: NEW WORDS
│  ┌──────────────────────────────┐   │
│  │  🌟 Chủ đề: Du lịch          │   │
│  │  3 từ mới hôm nay            │   │
│  │  [     Học từ mới →         ]│   │  ← CTA chính #2
│  └──────────────────────────────┘   │
│                                      │
│  🎯 QUIZ NHANH                       │  ← SECTION 4: QUICK QUIZ
│  ┌──────────────────────────────┐   │
│  │  ⚡ Quiz 5 câu — 2 phút      │   │
│  │  [   Làm quiz nhanh →       ]│   │
│  └──────────────────────────────┘   │
│                                      │
│  📊 TIẾN ĐỘ TỔNG QUAN               │  ← SECTION 5: OVERVIEW
│  ┌──────────────────────────────┐   │
│  │  📚 Tổng từ: 120              │   │
│  │  🧠 Đã thuộc: 85 (71%)       │   │
│  │  📈 Độ chính xác: 82%        │   │
│  │  ┌────────────────────────┐  │   │
│  │  │   Biểu đồ ôn tập 7 ngày │  │   │
│  │  │   T2 T3 T4 T5 T6 T7 CN │  │   │
│  │  └────────────────────────┘  │   │
│  └──────────────────────────────┘   │
│                                      │
│  📂 DANH MỤC CHỦ ĐỀ                  │  ← SECTION 6: TOPICS
│  ┌─────┬─────┬─────┬─────┬─────┐   │
│  │🌍 DL│💼 CV│🍜 Ăn│🏥 YT│🎓 Học│   │
│  │ 45t │ 32t │ 28t │ 15t │ 20t │   │
│  └─────┴─────┴─────┴─────┴─────┘   │
│                                      │
│  🏆 BẢNG XẾP HẠNG                    │  ← SECTION 7: SOCIAL
│  🥇 Bạn · 1200 XP                   │
│  🥈 Ngọc · 980 XP                   │
│  🥉 Minh · 750 XP                   │
└──────────────────────────────────────┘
│  📌 Navigation Bar                    │
│  [🏠 Home] [📚 Từ vựng] [🎯 Quiz] [👤 Hồ sơ] │
└──────────────────────────────────────┘
```

---

### 4.2 Chi tiết từng section

#### SECTION 1: Top Bar (Streak Bar)

```
┌────────────────────────────────────┐
│  🔥 12    🎯 78% tuần    💎 2,300 │
│  "Chăm chỉ quá! Học thêm 3 ngày    │
│   nữa là được huy hiệu 15 ngày! 🏅"│
└────────────────────────────────────┘
```

| Element | Mô tả | Dữ liệu từ |
|---------|-------|------------|
| Streak 🔥 | Số ngày học liên tiếp | `GET /api/dashboard` → `streak` |
| Weekly progress 🎯 | % hoàn thành mục tiêu tuần | `GET /api/dashboard` → `weekly_progress` |
| Gems 💎 | Tiền ảo | `GET /api/dashboard` → `gems` |
| Message động | Động viên theo streak level | Tính phía client dựa trên streak |

**States:**
- **Loading:** Skeleton shimmer 3 ô nhỏ
- **Error:** Ẩn streak, chỉ hiện icon offline
- **Empty (new user):** "🔥 Bắt đầu streak ngay hôm nay!"
- **Data:** Hiện đầy đủ

#### SECTION 2: Today's Review (Spaced Repetition)

```
┌────────────────────────────────────┐
│  📖 Ôn tập hôm nay                 │
│  ┌──────────────────────────────┐  │
│  │  📚 5 từ cần ôn              │  │
│  │  🔄 Đã ôn 2/5 (40%)          │  │
│  │  ████████████░░░░░░░░░░░░    │  │
│  │                              │  │
│  │  [▶  Ôn tập ngay — 3 phút]  │  │  ← Màu xanh, nút lớn
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

| State | Hiển thị |
|-------|----------|
| **Loading** | Skeleton dạng card |
| **Error** | "Không thể tải dữ liệu ôn tập" + [Thử lại] |
| **Empty** (0 từ cần ôn) | "🎉 Hôm nay bạn đã ôn xong! Quay lại vào ngày mai." |
| **Data** | Số từ + progress bar + nút CTA |

> **Spaced Repetition Algorithm:**
> - Dùng SM-2 (SuperMemo) đơn giản hoá:
>   - Lần 1: hôm sau
>   - Lần 2: 3 ngày sau
>   - Lần 3: 7 ngày sau
>   - Lần 4: 16 ngày sau
>   - Lần 5+: 30 ngày sau
> - `next_review_date` lưu trong DB mỗi từ

#### SECTION 3: New Words

```
┌────────────────────────────────────┐
│  📘 Học từ mới                     │
│  ┌──────────────────────────────┐  │
│  │  🌟 Chủ đề: "Du lịch"        │  │
│  │  📝 3 từ mới hôm nay         │  │
│  │  Bổ sung từ vựng bạn chưa có │  │
│  │                              │  │
│  │  [➕  Học từ mới →]          │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

**Cơ chế:** Mỗi ngày gợi ý 3-5 từ mới dựa trên:
1. Chủ đề user chưa học nhiều
2. Từ có độ khó phù hợp (chưa biết nhưng không quá xa lạ)
3. User có thể bỏ qua / chọn chủ đề khác

| State | Hiển thị |
|-------|----------|
| **Loading** | Skeleton |
| **Error** | "Không thể tải từ mới" + [Thử lại] |
| **Empty** | "Bạn đã học hết từ! 🎉 [Tạo từ vựng mới]" |
| **Data** | Chủ đề + số lượng + CTA |

#### SECTION 4: Quick Quiz

```
┌────────────────────────────────────┐
│  🎯 Quiz nhanh                     │
│  ┌──────────────────────────────┐  │
│  │  ⚡ Làm quiz 5 câu           │  │
│  │  ⏱ Chỉ mất 2 phút           │  │
│  │  🔄 Trắc nghiệm từ hôm qua   │  │
│  │                              │  │
│  │  [🎮  Làm quiz →]            │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

| State | Hiển thị |
|-------|----------|
| **Loading** | Skeleton card |
| **Error** | "Không thể tạo quiz" + [Thử lại] |
| **Empty** (chưa có từ) | "Hãy thêm từ vựng trước khi làm quiz!" |
| **Data** | Thông tin quiz + CTA |

#### SECTION 5: Progress Overview

```
┌────────────────────────────────────┐
│  📊 Tiến độ tổng quan              │
│  ┌──────────────────────────────┐  │
│  │ 📚 Tổng: 120 từ              │  │
│  │ 🧠 Đã thuộc: 85/120 (71%)    │  │
│  │ 📈 Quiz accuracy: 82%        │  │
│  │                              │  │
│  │ 📅 Học 5/7 ngày trong tuần   │  │
│  │ T2 ■ T3 ■ T4 ■ T5 □ T6 □ CN  │  │
│  │ [Xem chi tiết →]             │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

| State | Hiển thị |
|-------|----------|
| **Loading** | Skeleton |
| **Error** | "Không thể tải thống kê" |
| **Empty** (chưa có dữ liệu) | "Bắt đầu học để xem tiến độ của bạn!" |
| **Data** | Stats + mini heatmap |

#### SECTION 6: Topic Grid

```
┌────────────────────────────────────┐
│  📂 Danh mục chủ đề                │
│  ┌─────┬─────┬─────┬─────┐       │
│  │🗺 DLịch│💼 CViệc│🍜 Ẩm thực│🏥 Y tế│ │
│  │ 45 từ │ 32 từ │ 28 từ │ 15 từ │ │
│  │ 📈82% │ 📈75% │ 📈60% │ 📈40% │ │
│  ├─────┼─────┼─────┼─────┤       │
│  │🎓 Htập│🏠 Gđình│🎬 Giải trí│💪 S.khỏe│ │
│  │ 20 từ │ 18 từ │ 12 từ │ 8 từ  │ │
│  │ 📈90% │ 📈85% │ 📈50% │ 📈25% │ │
│  └─────┴─────┴─────┴─────┘       │
│  [Xem tất cả chủ đề →]            │
└────────────────────────────────────┘
```

| State | Hiển thị |
|-------|----------|
| **Loading** | 4× skeleton grid |
| **Error** | Ẩn section (không critical) |
| **Empty** (chưa có topic) | "Thêm từ vựng để tạo chủ đề!" |
| **Data** | Grid 2 hàng × 4 cột |

#### SECTION 7: Leaderboard (Social)

```
┌────────────────────────────────────┐
│  🏆 Bảng xếp hạng tuần này        │
│  ┌──────────────────────────────┐  │
│  │ 🥇 Bạn · 1,200 XP           │  │
│  │ 🥈 Ngọc · 980 XP            │  │
│  │ 🥉 Minh · 750 XP            │  │
│  │ 4. Lan · 620 XP             │  │
│  │ 5. Huy · 500 XP             │  │
│  └──────────────────────────────┘  │
│  [Xem bảng xếp hạng →]            │
└────────────────────────────────────┘
```

| State | Hiển thị |
|-------|----------|
| **Loading** | Skeleton |
| **Error** | Ẩn section |
| **Empty** (chưa có bạn bè) | "Mời bạn bè để cùng học!" |
| **Data** | Top 5 + highlight user hiện tại |

---

## 5. Gamification System

### 5.1 Streak System (🔥)

| Streak | Phần thưởng | Message động |
|--------|-------------|--------------|
| 1-6 ngày | +10 gems/ngày | "Bắt đầu tốt!" |
| **7 ngày** | 🏅 Huy hiệu + 50 gems | "1 tuần — giỏi lắm!" |
| 14 ngày | 100 gems | "2 tuần liên tiếp!" |
| **30 ngày** | 🏅 Huy hiệu + 200 gems | "1 tháng — xuất sắc!" |
| 60 ngày | 300 gems | "Kiên trì quá!" |
| **100 ngày** | 🏅 Huy hiệu + 500 gems + Avatar khung | "Huyền thoại!" |

**Cơ chế:** Streak chỉ được tính nếu user học ≥ 1 bài/ngày. Có streak freeze (dùng gems mua) nếu bỏ lỡ 1 ngày.

### 5.2 XP System (⭐)

| Hành động | XP |
|-----------|----|
| Học 1 từ mới | +5 XP |
| Ôn tập 1 từ | +3 XP |
| Quiz trả lời đúng | +10 XP |
| Quiz hoàn thành | +15 XP |
| Streak milestone | +50-200 XP |
| Hoàn thành chủ đề | +100 XP |

### 5.3 Level System

| Level | XP cần | Danh hiệu |
|-------|--------|-----------|
| 1-5 | 0-500 | 🌱 Mầm non |
| 6-10 | 500-1500 | 🌿 Lá xanh |
| 11-20 | 1500-4000 | 🌳 Cây lớn |
| 21-35 | 4000-8000 | 🏔️ Cao thủ |
| 36-50 | 8000-15000 | 🦅 Phiêu lưu |
| 50+ | 15000+ | 👑 Huyền thoại |

### 5.4 Achievement System (🏅)

| Thành tựu | Điều kiện | Phần thưởng |
|-----------|-----------|-------------|
| "First Step" | Học từ đầu tiên | 50 XP |
| "Word Collector" | Thêm 50 từ | 100 XP |
| "Dictionary" | Thêm 200 từ | 200 XP |
| "Perfect Quiz" | Quiz 100% đúng | 150 XP |
| "Streak 7" | 7 ngày liên tiếp | 🏅 Huy hiệu + 200 XP |
| "Streak 30" | 30 ngày | 🏅 Huy hiệu + 500 XP |
| "Streak 100" | 100 ngày | 🏅 Huy hiệu + 1000 XP + Khung |
| "Polyglot" | Học 5 chủ đề trở lên | 300 XP |
| "Night Owl" | Học sau 10pm | 50 XP |
| "Early Bird" | Học trước 7am | 50 XP |

---

## 6. Widget Tree đề xuất

### 6.1 Cấu trúc Widget

```
DashboardScreen (ConsumerWidget)
├── _buildLoading()                     → LoadingWidget (skeleton)
├── _buildError(String message)         → ErrorStateWidget + [Thử lại]
├── _buildEmpty()                       → EmptyStateWidget + [Thêm từ đầu tiên]
└── _buildContent(DashboardData data)
    ├── RefreshIndicator (pull-to-refresh)
    │   └── CustomScrollView
    │       ├── SliverAppBar
    │       │   └── StreakBar            → Widget chung (🔥 streak, 💎 gems, 🎯 goal)
    │       │
    │       ├── SliverToBoxAdapter
    │       │   ├── SectionHeader("📖 Ôn tập hôm nay")
    │       │   └── ReviewCard           → Widget chung
    │       │       ├── Loading → Skeleton
    │       │       ├── Empty → "🎉 Hoàn thành"
    │       │       └── Data → Progress + [Ôn tập]
    │       │
    │       ├── SliverToBoxAdapter
    │       │   ├── SectionHeader("📘 Học từ mới")
    │       │   └── NewWordsCard         → Widget chung
    │       │       ├── Loading → Skeleton
    │       │       ├── Empty → "Đã học hết!"
    │       │       └── Data → Topic + [Học mới]
    │       │
    │       ├── SliverToBoxAdapter
    │       │   ├── SectionHeader("🎯 Quiz nhanh")
    │       │   └── QuickQuizCard        → Widget chung
    │       │       ├── Loading → Skeleton
    │       │       ├── Empty → "Hãy thêm từ"
    │       │       └── Data → [Làm quiz]
    │       │
    │       ├── SliverToBoxAdapter
    │       │   └── ProgressOverview      → Widget chung
    │       │       ├── Loading → Skeleton
    │       │       ├── Empty → "Chưa có dữ liệu"
    │       │       └── Data → Stats + Heatmap
    │       │
    │       ├── SliverToBoxAdapter
    │       │   └── TopicGrid             → Widget chung
    │       │       ├── Loading → SkeletonGrid
    │       │       ├── Empty → "Chưa có chủ đề"
    │       │       └── Data → 2×4 grid
    │       │
    │       └── SliverToBoxAdapter
    │           └── LeaderboardPreview    → Widget chung
    │               ├── Loading → Skeleton
    │               ├── Empty → "Mời bạn bè"
    │               └── Data → Top 5
    │
    └── BottomNavigationBar
        ├── Home (active)
        ├── Vocabulary
        ├── Quiz
        └── Profile
```

### 6.2 Provider State

```dart
class DashboardProvider extends ChangeNotifier {
  // 3-state pattern
  bool _isLoading = false;
  DashboardData? _data;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  DashboardData? get data => _data;
  String? get errorMessage => _errorMessage;

  // Hàm chính
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi 2 API song song
      final results = await Future.wait([
        _dashboardService.getDashboard(),  // GET /api/dashboard
        _dashboardService.getTodayReview(), // GET /api/dashboard/today-review
      ]);
      _data = DashboardData(
        stats: results[0] as DashboardResponse,
        reviews: results[1] as List<VocabReview>,
      );
    } catch (e) {
      _errorMessage = "Không thể tải dữ liệu. Vui lòng thử lại!";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Data model
class DashboardData {
  final DashboardResponse stats;     // vocab_count, streak, xp, gems, etc.
  final List<VocabReview> reviews;   // today's reviews
  final List<Vocabulary> newWords;   // suggested new words
  final List<QuizResult> recentQuizzes;
  final List<TopicStat> topicStats;
  final List<LeaderboardEntry> leaderboard;
}
```

---

## 7. Data Flow cho Home Page

```
User mở app
    │
    ▼
DashboardScreen.build()
    │
    ├── isLoading = true → show Skeleton
    │
    ├── context.read<DashboardProvider>().loadDashboard()
    │       │
    │       ▼
    ├── Provider.loadDashboard()
    │       │
    │       ├── Gọi GET /api/dashboard (song song)
    │       ├── Gọi GET /api/dashboard/today-review
    │       └── Gọi GET /api/dashboard/topic-progress
    │       │
    │       ▼
    ├── THÀNH CÔNG
    │   ├── _data = response
    │   ├── isLoading = false
    │   └── notifyListeners()
    │       │
    │       ▼
    │   UI rebuild → show _buildContent()
    │
    ├── LỖI MẠNG / SERVER
    │   ├── _errorMessage = "..."
    │   ├── isLoading = false
    │   └── notifyListeners()
    │       │
    │       ▼
    │   UI rebuild → show _buildError()
    │
    └── DỮ LIỆU RỖNG (user mới)
        ├── _data = DashboardData.empty()
        ├── isLoading = false
        └── notifyListeners()
            │
            ▼
        UI rebuild → show _buildEmpty()
```

---

## 8. API Endpoints cần thêm

### 8.1 Dashboard API — Mở rộng

| Method | Endpoint | Response | Mục đích |
|--------|----------|----------|----------|
| GET | `/api/dashboard` | `{ streak, xp, gems, level, vocab_count, ... }` | Stats tổng quan (đã có) |
| **GET** | **`/api/dashboard/today-review`** | `{ total: 5, completed: 2, words: [...] }` | **Spaced repetition hôm nay** |
| **GET** | **`/api/dashboard/topic-progress`** | `[{ topic, total, mastered, accuracy }, ...]` | **Progress từng chủ đề** |
| **GET** | **`/api/dashboard/weekly-activity`** | `{ days: [{ date, xp, quizzes }] }` | **Heatmap cho 7 ngày** |
| GET | `/api/dashboard/leaderboard` | `[{ rank, username, xp }]` | Bảng xếp hạng |

### 8.2 Spaced Repetition API

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| **GET** | **`/api/vocabularies/review?today=true&limit=10`** | Lấy từ cần ôn hôm nay |
| **PUT** | **`/api/vocabularies/{id}/review`** | `{ quality: 0-5 }` — Cập nhật lịch ôn (SM-2) |

### 8.3 Gamification API

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/gamification/learn` | +XP tích luỹ |
| GET | `/api/gamification/achievements` | Danh sách thành tựu |
| POST | `/api/gamification/claim-streak` | Claim streak reward |

---

## 9. Wireframe (Text-based)

### 9.1 Desktop / Tablet Layout (màn rộng)

```
┌──────────────────────────────────────────────────────────────────┐
│  🔥 Streak 12    🎯 78%    💎 2,300    "Chào mừng trở lại, Nam!" │
├──────────────────────────────────────────────────────────────────┤
│                                       │                           │
│  ┌─────────────────────────┐          │  ┌─────────────────────┐ │
│  │ 📖 ÔN TẬP HÔM NAY       │          │  │ 📊 TIẾN ĐỘ          │ │
│  │ 5 từ cần ôn · 40%      │          │  │ 📚 120 từ           │ │
│  │ [████████░░░░░░░░░░░]   │          │  │ 🧠 85 thuộc (71%)   │ │
│  │ [▶ Ôn tập ngay]        │          │  │ 📈 82% accuracy     │ │
│  └─────────────────────────┘          │  └─────────────────────┘ │
│                                       │                           │
│  ┌─────────────────────────┐          │  ┌─────────────────────┐ │
│  │ 📘 HỌC TỪ MỚI           │          │  │ 🏆 BXH              │ │
│  │ 🌟 Chủ đề: Du lịch      │          │  │ 🥇 Bạn · 1200       │ │
│  │ 3 từ mới hôm nay        │          │  │ 🥈 Ngọc · 980       │ │
│  │ [➕ Học từ mới →]       │          │  │ 🥉 Minh · 750       │ │
│  └─────────────────────────┘          │  └─────────────────────┘ │
│                                       │                           │
│  ┌─────────────────────────┐          │  ┌─────────────────────┐ │
│  │ 🎯 QUIZ NHANH           │          │  │ 📂 CHỦ ĐỀ           │ │
│  │ ⚡ 5 câu · 2 phút      │          │  │ [DL] [CV] [Ăn] [YT] │ │
│  │ [🎮 Làm quiz →]        │          │  │ [HL] [GD] [GT] [SK] │ │
│  └─────────────────────────┘          │  └─────────────────────┘ │
│                                       │                           │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  📅 Hoạt động 7 ngày qua: ■■■□■■□                        │    │
│  └──────────────────────────────────────────────────────────┘    │
├──────────────────────────────────────────────────────────────────┤
│  [🏠 Home]  [📚 Vocabulary]  [🎯 Quiz]  [👤 Profile]           │
└──────────────────────────────────────────────────────────────────┘
```

### 9.2 Mobile Layout (màn hẹp) — ưu tiên cuộn dọc

```
┌──────────────────────────┐
│ 🔥 12   🎯 78%   💎 2300│
│ "Chăm chỉ quá! 🎉"       │
├──────────────────────────┤
│                          │
│ 📖 ÔN TẬP HÔM NAY       │
│ ┌────────────────────┐   │
│ │ 5 từ · 2/5 (40%)   │   │
│ │ ████████░░░░░░░░░░ │   │
│ │ [▶ Ôn tập ngay]    │   │
│ └────────────────────┘   │
│                          │
│ 📘 HỌC TỪ MỚI           │
│ ┌────────────────────┐   │
│ │ 🌟 Du lịch: 3 từ   │   │
│ │ [➕ Học từ mới]    │   │
│ └────────────────────┘   │
│                          │
│ 🎯 QUIZ NHANH            │
│ ┌────────────────────┐   │
│ │ ⚡ 5 câu · 2 phút  │   │
│ │ [🎮 Làm quiz]      │   │
│ └────────────────────┘   │
│                          │
│ 📊 TIẾN ĐỘ              │
│ 📚 120 từ ⋅ 🧠 71% thuộc │
│ 📈 82% accuracy          │
│                          │
│ 📂 CHỦ ĐỀ                │
│ ┌───┬───┬───┬───┐       │
│ │DL │CV │Ăn │YT │       │
│ │45t│32t│28t│15t│       │
│ └───┴───┴───┴───┘       │
│                          │
│ 🏆 BXH                   │
│ 🥇 Bạn · 1200 XP        │
│ 🥈 Ngọc · 980 XP        │
│ 🥉 Minh · 750 XP        │
│                          │
│ 📅 Hoạt động 7 ngày     │
│ ■■■□■■□                  │
├──────────────────────────┤
│ 🏠  📚  🎯  👤         │
└──────────────────────────┘
```

---

## 10. Kế hoạch triển khai

### 🟢 Phase 1: Backend — Dashboard API mở rộng

| Task | Mô tả | File |
|------|-------|------|
| 1. Dashboard Service mở rộng | Thêm `streak`, `xp`, `gems`, level tính toán | `services/dashboard_service.py` |
| 2. Today Review API | Lấy từ vựng đến hạn ôn tập (spaced repetition) | `services/vocabulary_service.py` |
| 3. Topic Progress API | Thống kê từng chủ đề | `services/dashboard_service.py` |
| 4. Weekly Activity API | Heatmap 7 ngày | `services/dashboard_service.py` |
| 5. Gamification model | Bảng achievements + user_xp | `models.py` + `services/gamification_service.py` |
| 6. Thêm router gamification | Endpoints achievements, claim reward | `routers/gamification.py` |

### 🟢 Phase 2: Frontend — Dashboard Screen rewrite

| Task | Mô tả | File |
|------|-------|------|
| 1. DashboardData model | Model cho dữ liệu dashboard mới | `models/dashboard_data.dart` |
| 2. DashboardService update | Thêm API calls mới | `services/dashboard_service.dart` |
| 3. DashboardProvider | Load song song, 3-state | `providers/dashboard_provider.dart` |
| 4. StreakBar widget | Thanh streak + gems + goal | `widgets/streak_bar.dart` |
| 5. ReviewCard widget | Ôn tập hôm nay | `widgets/review_card.dart` |
| 6. NewWordsCard widget | Học từ mới | `widgets/new_words_card.dart` |
| 7. QuickQuizCard widget | Quiz nhanh | `widgets/quiz_card.dart` |
| 8. ProgressOverview widget | Thống kê + heatmap | `widgets/progress_overview.dart` |
| 9. TopicGrid widget | Grid chủ đề | `widgets/topic_grid.dart` |
| 10. DashboardScreen rewrite | Rebuild với sections | `screens/dashboard_screen.dart` |

### 🟢 Phase 3: Gamification & Social

| Task | Mô tả |
|------|-------|
| 1. Streak logic + streak freeze | Tính streak, gems để freeze |
| 2. Achievement system | Badge, unlock conditions |
| 3. Leaderboard | Bảng xếp hạng bạn bè |
| 4. Push notifications | Nhắc nhở học hàng ngày |

---

## 📋 Tổng kết

### So sánh giải pháp đề xuất vs Đối thủ

| Tính năng | Duolingo | TOPIK app | Memrise | Quizlet | **App này** |
|-----------|----------|-----------|---------|---------|---------|
| Streak | ✅ | ⚠️ | ✅ | ❌ | **✅ Mạnh** |
| Learning path | ✅ | ❌ | ✅ | ❌ | **⚠️ Theo chủ đề** |
| Spaced Repetition | ❌ | ✅ | ✅ | ✅ | **✅ SM-2** |
| Gamification | ✅✅ | ⚠️ | ✅ | ⚠️ | **✅ Đầy đủ** |
| Topic vocab | ✅ | ✅ | ✅ | ✅ | **✅ Grid topic** |
| Quiz daily | ✅ | ✅ | ⚠️ | ✅ | **✅ Quiz nhanh** |
| Progress tracking | ✅ | ✅ | ⚠️ | ⚠️ | **✅ Chi tiết** |
| Leaderboard | ✅ | ❌ | ❌ | ⚠️ | **✅ Có** |
| Achievements | ✅ | ❌ | ❌ | ❌ | **✅ Có** |
| Daily goals | ✅ | ⚠️ | ✅ | ❌ | **✅ Weekly goal** |

### Workflow khi user mở app

```
1. Mở app → splash → check auth
2. Token valid → DashboardScreen
3. Provider.loadDashboard() (Future.wait 3 API)
4. Hiển thị content:
   ┌─ Streak (🔥) → motivation
   ├─ Review (📖) → spaced repetition
   ├─ New Words (📘) → học mới
   ├─ Quick Quiz (🎯) → kiểm tra nhanh
   ├─ Progress (📊) → thống kê
   ├─ Topics (📂) → danh mục
   └─ Leaderboard (🏆) → cạnh tranh
5. User click CTA → navigate tương ứng
```

---

> **Kết luận:** Giải pháp này kết hợp **strength của Duolingo** (gamification, streak, engagement) với **khoa học của Memrise** (spaced repetition) và **tính hệ thống của TOPIK app** (chủ đề, cấp độ), tạo ra một trải nghiệm học từ vựng vừa **vui** vừa **hiệu quả**.
