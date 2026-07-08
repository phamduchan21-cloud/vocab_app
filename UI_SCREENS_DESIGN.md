# 🎨 Thiết kế giao diện — Ứng dụng Học Từ Vựng VocaEng (MeuBeu)

> **App:** VocaEng (tên thân thiện: MeuBeu)  
> **Platform:** Flutter Web + Android  
> **Design System:** Cobalt Blue accent · Work Sans font · Material 3  
> **Bottom Nav:** 5 tabs: Trang chủ · Quiz · Flashcard · Test · Hồ sơ  
> **Tổng số màn hình:** 21 screens + 1 bottom nav + 1 sidebar (desktop)

---

## 📑 Mục lục

1. [Bottom Navigation & Sidebar](#1-bottom-navigation--sidebar)
2. [Splash Screen — `/splash`](#2-splash-screen)
3. [Onboarding — `/onboarding`](#3-onboarding)
4. [Đăng nhập — `/login`](#4-đăng-nhập)
5. [Đăng ký — `/register`](#5-đăng-ký)
6. [Dashboard — `/`](#6-dashboard)
7. [Quiz List — `/quiz`](#7-quiz-list)
8. [Quiz Play — `/quiz/play`](#8-quiz-play)
9. [Quiz Result — `/quiz/result/:id`](#9-quiz-result)
10. [Quiz History — `/quiz/history`](#10-quiz-history)
11. [Flashcard — `/flashcard`](#11-flashcard)
12. [Mock Test — `/mock-test`](#12-mock-test)
13. [Mock Test Play — `/mock-test/play/:level`](#13-mock-test-play)
14. [Mock Test Result — `/mock-test/result/:id`](#14-mock-test-result)
15. [Profile — `/profile`](#15-profile)
16. [Progress — `/progress`](#16-progress)
17. [Bookmark — `/bookmark`](#17-bookmark)
18. [Kho từ vựng — `/topics`](#18-kho-từ-vựng)
19. [Chi tiết chủ đề — `/topics/:lessonId`](#19-chi-tiết-chủ-đề)
20. [AI Chat — `/ai-chat`](#20-ai-chat)
21. [Vocabulary List — `/vocabulary`](#21-vocabulary-list)
22. [Vocabulary Form — `/vocabulary/new` & `/vocabulary/:id/edit`](#22-vocabulary-form)

---

## 0. 🎨 Design System Tokens

### Màu sắc

```dart
// Core
background:  #F8F9FA (xám nhạt)
surface:     #FFFFFF (trắng)
surfaceSubtle: #F1F3F5 (xám siêu nhạt)
ink:         #1A1D23 (đen chữ)
inkSoft:     #6B7280 (xám chữ phụ)
textHint:    #9CA3AF (xám gợi ý)

// Accent (Cobalt Blue)
blue:        #2563EB
blueLight:   #3B82F6
blueDark:    #1D4ED8
blueBg:      #EFF6FF (nền xanh nhạt)

// Semantic
success:     #059669 (xanh lá)
successBg:   #ECFDF5
danger:      #DC2626 (đỏ)
dangerBg:    #FEF2F2
warning:     #D97706 (vàng cam)
warningBg:   #FFFBEB
```

### Typography
- **Primary font:** Work Sans (Google Fonts)
- **Mono digits:** IBM Plex Mono (cho số, %, thời gian)
- **Headings:** `w700 · 28px`, `w600 · 22px`, `w600 · 18px`
- **Body:** `16px` (primary), `14px` (secondary), `12px` (hint)

### Component tokens
| Component | Style |
|-----------|-------|
| AppBar | Surface bg, center title, 0 elevation, scrolledUnderElevation: 0 |
| Card | Elevation 2, shadow 8% ink, radius 12 |
| Button | Blue bg, white text, 48px height, radius 10, 0 elevation |
| Input | Filled bg=background, radius 10, blue focus border 1.5px |
| Divider | 10% ink, height 1 |
| Snackbar | Ink bg, floating, radius 10 |

---

## 1. Bottom Navigation & Sidebar

### Bottom Nav (mobile)

| Index | Icon | Label | Route |
|:-----:|------|-------|-------|
| 0 | `home_outlined` | Trang chủ | `/` |
| 1 | `quiz_outlined` | Quiz | `/quiz` |
| 2 | `style_outlined` | Flashcard | `/flashcard` |
| 3 | `assignment_outlined` | Test | `/mock-test` |
| 4 | `person_outlined` | Hồ sơ | `/profile` |

**Trạng thái:** Active tab → blue icon + label + underline dot (16x2.5px)  
**Design:** White surface bg, top shadow, safe area padding 8px horizontal

### Sidebar (desktop, width ≥ 768px)

- Width 230px, dark bg (`#1A1D23`)
- Logo "VocaEng" + "HỌC TỪ VỰNG" subtitle
- 5 nav items with icon + label (active: light bg, inactive: dim)
- Bottom: Avatar circle + username + level label

---

## 2. Splash Screen

**Route:** `/splash`  
**Trạng thái:** Màn hình chào đầu tiên (public)

### Layout
```
┌──────────────────────────┐
│   [Gradient Blue bg]      │
│                           │
│       🐱 CatWidget         │  ← size 180, expression: happy
│       (animated fade+up)   │
│                           │
│        MeuBeu             │  ← Nunito 48px bold white
│    Học miễn phí. Suốt đời. │  ← 16px light white
│                           │
│   ┌───────────────────┐   │
│   │   Bắt đầu ngay     │   │  ← White btn, blue text, 56px
│   └───────────────────┘   │
│   Tôi đã có tài khoản      │  ← TextButton white
└──────────────────────────┘
```

### Chi tiết
- Gradient: `blue → blueDark`
- Animation: fadeIn + slideUp (1.2s), cat bobbing animation
- 2 actions: "Bắt đầu ngay" → `/onboarding`, "Tôi đã có tài khoản" → `/login`

---

## 3. Onboarding

**Route:** `/onboarding`  
**Trạng thái:** 9 trang dạng PageView (1 welcome + 8 câu hỏi)

### Layout chung
```
┌──────────────────────────┐
│ ●●○○○○○○○ (progress dots) │
│──────────────────────────│
│                           │
│  [PageView content]       │
│                           │
│──────────────────────────│
│  ┌───────────────────┐   │
│  │   Tiếp tục /       │   │  ← Gradient btn (disabled: grey)
│  │ Bắt đầu hành trình! │   │
│  └───────────────────┘   │
└──────────────────────────┘
```

### Welcome page (index 0)
- CatWidget (140px, happy, bouncing)
- Speech bubble: "Chào bạn! 🐱 Tớ là Meu!" (blue text)
- "Hãy trả lời 8 câu hỏi nhỏ để tớ hiểu bạn hơn nhé!"

### Question pages (index 1-8)
- Cat nhỏ (56px, talking) + speech bubble chứa câu hỏi
- Option cards: icon + label, selected → blue border + check circle
- Single select (radio) hoặc multi select (checkbox)
- Nút disabled nếu chưa chọn

### 8 câu hỏi
| # | Câu hỏi | Type | Options |
|:-:|---------|:----:|---------|
| 1 | Trước hết, bạn muốn học ngôn ngữ gì? | single | 🇬🇧🇯🇵🇰🇷🇨🇳🇫🇷🇩🇪🌐 |
| 2 | Trình độ hiện tại của bạn thế nào? | single | 🌱 Mới bắt đầu → 📕 Nâng cao |
| 3 | Tại sao bạn muốn học ngôn ngữ này? | multi | 🎯 CV, ✈️ DL, 🎓 Học, 🎬 Giải trí... |
| 4 | Bạn muốn dành bao nhiêu phút mỗi ngày? | single | ⚡5' · 🔥15' · 💪30' · 🏆60' |
| 5 | Bạn thích học theo cách nào? | multi | 👁️👂✍️🗣️📖 |
| 6 | Bạn có mục tiêu cụ thể gì không? | single | 🗣️📝🎬📖🌍 |
| 7 | Bạn muốn học vào thời gian nào trong ngày? | single | 🌅☀️🌤️🌆🌙🌃 |
| 8 | Bạn có muốn nhắc nhở học hàng ngày không? | single | 🔔 8h/12h/20h · ❌ Không |

---

## 4. Đăng nhập

**Route:** `/login`  
**Trạng thái:** Authenticating / Error / Success

### Layout
```
┌──────────────────────────┐
│  ← [back]  [Gradient bg]  │
│                           │
│       📖 (icon 56px)      │
│    Chào mừng trở lại!      │  ← Nunito 28px bold white
│  Đăng nhập để tiếp tục học  │
│                           │
│  ┌─────────────────────┐  │
│  │  Glassmorphism card   │  │  ← white 95% opacity, radius 24
│  │  [Email input]        │  │
│  │  [Password input]     │  │  ← show/hide toggle
│  │  [Error msg]          │  │  ← optional, red bg
│  │  ┌─────────────────┐  │  │
│  │  │   Đăng nhập      │  │  │  ← gradient btn
│  │  └─────────────────┘  │  │
│  └─────────────────────┘  │
│                           │
│  Chưa có tài khoản? Đăng ký│
└──────────────────────────┘
```

### States
| State | Hiển thị |
|-------|---------|
| **Loading** | CircularProgressIndicator thay text button |
| **Error** | Red container: icon error + message từ AuthProvider |
| **Success** | Redirect `/` (dashboard) |

---

## 5. Đăng ký

**Route:** `/register`  
**Layout:** Giống login nhưng thêm Username + Confirm password

### Form fields
1. **Tên người dùng** — `person_outlined` icon, required
2. **Email** — `email_outlined`, must contain `@`
3. **Mật khẩu** — `lock_outlined`, min 6 chars, show/hide toggle
4. **Xác nhận mật khẩu** — must match password

**Actions:** Đăng ký → tự động đăng nhập → redirect `/`

---

## 6. Dashboard

**Route:** `/`  
**Trạng thái:** Loading / Error / Empty (new user) / Data

### Hero Stats Bar
```
┌──────────────────────────────────┐
│ 👤 Xin chào, {username}!          │
│ 🔥 {streak}  ⭐ {xp}  💎 {gems}  │
│ Level {n} · {levelTitle}         │
│ 🎯 {progress}/{goal} từ hôm nay   │
│ [████████░░░░]                   │
│ [CẤP ĐỘ: {englishLevel}]         │
└──────────────────────────────────┘
```
- Blue gradient bg, white text
- Nếu có dailyGoal → progress bar

### Nội dung chính (Data state)

#### 📅 Học tập hôm nay (DailyTaskCards)
| Card | Icon | Title | Accent |
|------|------|-------|--------|
| 1 | 🗂️ | Ôn tập flashcard | Blue |
| 2 | ⚡ | Luyện tập quiz | Warning |
| 3 | 📝 | Kiểm tra trình độ | Danger |
| 4 | 📚 | Khám phá kho từ vựng | Success |

Mỗi card: emoji + title + description + optional meta badge + progress bar

#### 📊 Weekly Chart
- Bar chart 7 ngày (XP mỗi ngày)
- Đi kèm: `currentXp` + `weeklyXpGoal`

#### 🔥 Chủ đề hôm nay
- Gradient blue card
- Random topic từ danh sách 15 chủ đề
- CTA "Học ngay" → flashcard theo topic

#### 📚 Danh mục chủ đề (TopicGrid)
- Grid 2 cột các topic cards (icon, title, số từ)
- "Xem tất cả" → `/topics`

#### 🏆 Bảng xếp hạng (LeaderboardPreview)
- Top users theo XP
- "Xem tất cả" → `/profile`

### Empty state (new user)
- Cat emoji lớn + "Chào mừng đến với VocaEng!"
- 3 step guide cards:
  1. 📚 Khám phá kho từ vựng
  2. 🃏 Học với flashcard
  3. ⚡ Kiểm tra với quiz

### Error state
- ErrorStateWidget + Retry button

---

## 7. Quiz List

**Route:** `/quiz`  
**Trạng thái:** Configuring quiz parameters

### Layout
```
┌──────────────────────────┐
│    Quiz theo chủ đề       │  ← AppBar
├──────────────────────────┤
│  ┌────────────────────┐   │
│  │  Hero Card          │   │  ← Blue gradient
│  │  Tập trung vào      │   │
│  │  từng chủ đề         │   │
│  └────────────────────┘   │
│                           │
│  Chọn kỹ năng             │
│  [📚 Tất cả] [📖 TV]...   │  ← ChoiceChips
│                           │
│  Chọn chủ đề               │
│  [📚 Tất cả chủ đề ▼]     │  ← open bottom sheet
│                           │
│  Số câu hỏi               │
│  [5 câu] [10 câu] [15 câu]│  ← selectable chips
│                           │
│  [Quiz nhanh]             │  ← mode tile
│  [Luyện theo tiến độ]     │
│                           │
│  ┌────────────────────┐   │
│  │ 🤖 Quiz bằng AI     │   │  ← Purple-blue gradient
│  │ AI sinh câu hỏi...  │   │
│  └────────────────────┘   │
│                           │
│  ┌────────────────────┐   │
│  │  ▶ Bắt đầu quiz     │   │  ← CTA button
│  └────────────────────┘   │
│  [Xem lịch sử quiz]       │
└──────────────────────────┘
```

### Skill types
1. 📚 Tất cả
2. 📖 Từ vựng
3. 📐 Ngữ pháp
4. 📝 Đọc hiểu
5. 👂 Nghe hiểu

### Topic selection
- Bottom sheet (FlashcardTopicSheet) chọn topic
- Mỗi topic hiển thị số thẻ có sẵn
- "Tất cả chủ đề" là default

### Question count chips
- 5, 10, 15 câu (selectable, black bg khi chọn)

---

## 8. Quiz Play

**Route:** `/quiz/play`  
**Trạng thái:** Loading questions / Playing / Result / Error

### Playing layout
```
┌──────────────────────────┐
│ ← [back] Quiz theo chủ đề │  ← AppBar
├──────────────────────────┤
│  Câu 3/10  ██████░░░░ 00:45│  ← progress + timer
│           ██████░░░░       │  ← timer countdown bar
│                            │
│  ┌────────────────────┐    │
│  │ Nghĩa của từ 'hello'│   │  ← Question card
│  │ là gì?              │   │
│  └────────────────────┘    │
│                            │
│  ┌─○ A ─────────────────┐  │  ← Option (not selected)
│  │  tạm biệt             │  │
│  └───────────────────────┘  │
│  ┌─● B ─────────────────┐  │  ← Option (selected: blue)
│  │  xin chào             │  │
│  └───────────────────────┘  │
│  ┌─○ C ─────────────────┐  │
│  │  cảm ơn               │  │
│  └───────────────────────┘  │
│  ┌─○ D ─────────────────┐  │
│  │  xin lỗi              │  │
│  └───────────────────────┘  │
│                            │
│  [Câu trước] [Câu tiếp theo]│  ← navigation
└──────────────────────────┘
```

### Timer
- 60 giây mỗi câu
- Thanh đếm ngược: màu inkSoft, chuyển danger khi ≤ 10s
- Hết giờ → tự động chuyển câu
- Hiển thị `MM:SS` trong badge

### Interaction
- Tap option → select (blue bg, blue border, filled circle)
- "Câu tiếp theo" → next question
- Câu cuối → "Xem kết quả"
- Có thể quay lại câu trước

### Result (inline, không cần API)
- Score circle `{accuracy}%`
- Stats: Đúng/Sai, XP (+10/câu đúng), Thời gian
- Chi tiết đáp án: từng câu với đúng/sai
- Actions: "Về trang chủ" / "Làm lại"

---

## 9. Quiz Result

**Route:** `/quiz/result/:id`  
**Trạng thái:** Data / No data (result null)

### Layout
```
┌──────────────────────────┐
│ ← [back]    Kết quả       │  ← AppBar
├──────────────────────────┤
│       ┌───────┐           │
│       │ 80%   │           │  ← Postmark circle (dashed border)
│       │ /10   │           │     màu success/warning/danger
│       └───────┘           │
│      Xuất sắc!            │  ← message theo score
│      Quiz theo chủ đề     │
│                           │
│   6 Đúng | 4 Sai | 80%   │  ← stats row
│                           │
│  ┌───Chi tiết đáp án───┐  │
│  │ ✓ Câu 1: Đúng       │  │
│  │ ✗ Câu 2: Sai        │  │
│  │ ...                 │  │
│  └─────────────────────┘  │
│                           │
│  [Làm lại] [Về trang chủ]  │
└──────────────────────────┘
```

### Score color
| Score | Color | Message |
|:-----:|-------|---------|
| ≥ 80% | 🟢 success | Xuất sắc! |
| ≥ 50% | 🟡 warning | Cố gắng hơn nhé! |
| < 50% | 🔴 danger | Cần ôn tập thêm! |

---

## 10. Quiz History

**Route:** `/quiz/history`  
**Trạng thái:** Loading / Error / Empty / Data

### Layout
```
┌──────────────────────────┐
│    Lịch sử làm bài        │  ← AppBar
├──────────────────────────┤
│  ┌─── Summary card ──┐   │
│  │ 12 bài | 72% TB   │   │  ← 3 stats: count, avg, correct/total
│  │ 48/68 Đúng/Tổng   │   │
│  └───────────────────┘   │
│                           │
│  Các bài đã làm            │
│                           │
│  ┌─────────────────────┐  │  ← mỗi item
│  │ [score ring] Quiz    │  │
│  │ vocabulary           │  │
│  │ 6/10 câu đúng        │  │
│  │ 15/03/2026 14:30   >│  │
│  └─────────────────────┘  │
│  ...                      │
└──────────────────────────┘
```

### History item
- Score ring (CircularProgressIndicator với %)
- Quiz type, correct/total, date
- Tap → AlertDialog chi tiết (từng câu đúng/sai)
- Empty: "Chưa có lịch sử làm bài" + CTA

---

## 11. Flashcard

**Route:** `/flashcard`  
**Trạng thái:** Loading / Error / Empty / Data

### Layout
```
┌──────────────────────────┐
│ ← Flashcard theo chủ đề 🔀▶│  ← AppBar + shuffle + auto-play
├──────────────────────────┤
│ [●] {topic}         30 thẻ▼│  ← topic bar + progress ring
│ 📊 Hôm nay: 5 thẻ · 80%   │  ← session stats (nếu có)
│                           │
│       ┌───────────┐       │
│       │ TOPIC      │       │
│       │            │       │
│       │  "hello"   │       │  ← Front: word + speaker
│       │  🔊        │       │
│       │            │       │
│       │ Lật thẻ để │       │
│       │ xem nghĩa  │       │
│       └───────────┘       │
│                           │
│     😵Lại quên  🤔Hơi khó │  ← Review buttons (4 levels)
│     😊Nhớ rồi  🔥Dễ ợt  │
│                           │
│   [Trước]      [Sau]      │  ← navigation
└──────────────────────────┘
```

### Card flip
- **Front:** word (30px, bold white) + speaker button + topic badge
- **Back:** meaning (24px) + example sentence
- Animation: 3D Y-axis rotation (450ms)
- Tap card → flip, tap again → flip back

### Review buttons (SM-2)
| Button | Emoji | Quality | Color |
|--------|:-----:|:-------:|-------|
| Lại quên | 😵 | 0 | danger |
| Hơi khó | 🤔 | 2 | warning |
| Nhớ rồi | 😊 | 4 | blue |
| Dễ ợt | 🔥 | 5 | success |

- Chỉ hiện khi card đã lật
- Swipe left/right để chuyển thẻ
- Swipe down → về dashboard

### Topic bar
- Hiển thị progress ring theo độ thuần thục
- Tap → mở bottom sheet chọn topic
- Mỗi topic hiển thị số thẻ

### Features
- **Shuffle toggle** — xáo trộn thẻ
- **Auto-play** — tự động lật 5s/thẻ
- **Session stats** — số thẻ đã ôn hôm nay + độ chính xác

### States
| State | Hiển thị |
|-------|---------|
| **Loading** | Skeleton card |
| **Error** | ErrorStateWidget + retry |
| **Empty** | "Chưa có từ vựng" + CTA mở danh sách từ |

---

## 12. Mock Test

**Route:** `/mock-test`  
**Trạng thái:** Selecting level + topic

### Layout
```
┌──────────────────────────┐
│    Mini-test              │  ← AppBar
├──────────────────────────┤
│  Chọn cấp độ               │
│  Kiểm tra tổng hợp...      │
│                           │
│  ┌🌱 Cơ bản────────────○┐ │  ← level card (not selected)
│  │ 10 câu · 15 phút     │ │
│  │ Phù hợp cho người...  │ │
│  └──────────────────────┘ │
│  ┌🌿 Trung cấp─────────●┐ │  ← selected: blue bg + radio
│  │ 20 câu · 30 phút     │ │
│  └──────────────────────┘ │
│  ┌🔥 Nâng cao───────────○┐ │
│  │ 30 câu · 45 phút     │ │
│  └──────────────────────┘ │
│                           │
│  Chọn chủ đề (tuỳ chọn)    │
│  [Tất cả] [greetings] [..]│  ← ChoiceChips
│                           │
│  ┌────────────────────┐   │
│  │  ▶ Bắt đầu kiểm tra │   │  ← CTA
│  └────────────────────┘   │
│                           │
│  ─── Lịch sử kiểm tra ─── │
│  📈 Xu hướng điểm số      │  ← chart (nếu ≥ 2 bài)
│  [score] Cơ bản · Hạng A  │
│  [score] Trung cấp · Hạng B│
└──────────────────────────┘
```

### Level cards
| Level | Emoji | Questions | Time | Border |
|-------|:-----:|:---------:|:----:|--------|
| beginner | 🌱 | 10 | 15 min | green |
| intermediate | 🌿 | 20 | 30 min | warning |
| advanced | 🔥 | 30 | 45 min | danger |

### History
- Score chart (CustomPaint line chart) nếu ≥ 2 bài
- Mỗi history item: score ring, level badge, grade badge, retry button
- Grade: A (≥90%), B (≥75%), C (≥50%), D

---

## 13. Mock Test Play

**Route:** `/mock-test/play/:level?topic={topic}`  
**Trạng thái:** Loading / Error / Playing / Submitted (inline result) / Saving to server

### Layout — Mobile
```
┌──────────────────────────┐
│ ← Trang chủ  Mini-test   │  ← top bar
│ Bài kiểm tra 20 câu ⏱ 25:00│
├──────────────────────────┤
│ Danh sách câu hỏi         │
│ [1][2][3][4][5][6][7]...  │  ← horizontal navigator
│ ● Chưa làm  ● Đã trả lời  │  ← legend
│ ● Đang xem                │
├──────────────────────────┤
│  Câu 3 / 20               │
│                           │
│  "What does 'resilient'   │
│   mean?"                  │
│                           │
│  ○ A. Kiên cường          │
│  ● B. Hoãn lại            │
│  ○ C. Chân thật           │
│  ○ D. Kết quả             │
├──────────────────────────┤
│ [Câu trước] [Câu sau][Nộp]│  ← footer
└──────────────────────────┘
```

### Layout — Desktop (width ≥ 640px)
- **Left panel (220px):** Question grid (5 columns) + legend
- **Right panel:** Current question + options + footer

### Features
- Timer đếm ngược, hết giờ tự động nộp
- Question navigator: đang xem (blue), đã trả lời (green), chưa làm (grey)
- Prev/Next navigation
- Nộp bài → tính điểm inline (không cần server)
- Sau đó mới lưu lên server

### Result (inline, after submit)
- Stats: 4 cards (✓ Đúng, ✕ Sai, % Điểm, ⏱ Thời gian)
- Grade circle (A/B/C/D) + English level (C1/B2/B1/A2/A1)
- Level description text
- Chi tiết đáp án: từng câu với đáp án đã chọn
- Actions: "Lưu kết quả" (submit to server) + "Về trang chọn đề"

---

## 14. Mock Test Result

**Route:** `/mock-test/result/:id` (extra: MockTestResult)  
**Trạng thái:** Data (result passed via extra)

### Layout
```
┌──────────────────────────┐
│ ✕ [close] Kết quả thi thử │  ← AppBar
├──────────────────────────┤
│       ┌───────────┐       │
│       │   75%     │       │  ← Postmark circle
│       │  20 câu   │       │
│       └───────────┘       │
│                           │
│   Hoàn thành bài kiểm tra!│
│   Bạn đạt trình độ B2     │
│                           │
│  ┌─ Stats ────────────┐   │
│  │ 📝20  ✅15  ❌5    │   │  ← emoji stats row
│  └────────────────────┘   │
│                           │
│  ┌─ Level card ────────┐  │
│  │ [B] Trình độ B2     │  │  ← grade circle + level info
│  │ Xếp loại B          │  │
│  └─────────────────────┘  │
│                           │
│  [Về trang chủ] [Làm lại] │
└──────────────────────────┘
```

### Level mapping
| Score | Grade | Level | Description |
|:-----:|:-----:|:-----:|-------------|
| ≥ 90% | A | C1 | Trình độ cao cấp |
| ≥ 75% | B | B2 | Trung cao cấp |
| ≥ 50% | C | B1 | Trung cấp |
| < 50% | D | A2/A1 | Sơ cấp / Mới bắt đầu |

---

## 15. Profile

**Route:** `/profile`  
**Layout:** TabBar với 4 tabs  

### Hero section
- Blue gradient card
- Avatar circle + username + email + English level badge (editable)
- Stats: Level, XP, Streak, Gems
- 2 buttons: "Xem tiến độ" / "Nhận thưởng streak" (có animation level up)

### Tab 1: Tổng quan
- 4 mini stat cards (từ đã học, quiz đã làm, độ chính xác, tiến độ tuần)
- Recent quizzes list (score ring + topic + correct/total)

### Tab 2: Tiến độ
- Weekly activity bar chart (7 ngày)
- Topic progress list (name + % + progress bar + mastered/total)

### Tab 3: Huy hiệu
- Grid 2 columns
- Mỗi badge: icon (42px) + title + description
- Empty state: "Chưa mở khóa huy hiệu"

### Tab 4: Tài khoản
- Action tiles: Tên hiển thị, Email, Trình độ TA, Mục tiêu từ/ngày (slider 5-50), Lịch sử quiz, Từ đã lưu, Đăng xuất
- Edit profile via bottom sheet

---

## 16. Progress

**Route:** `/progress`  
**Trạng thái:** Loading / Error / Data (may be empty for new users)

### Layout
```
┌──────────────────────────┐
│    Tiến độ                │  ← AppBar
├──────────────────────────┤
│  Tiến độ học tập          │
│  Theo dõi quá trình...    │
│                           │
│  ┌────────────────────┐   │
│  │ 📘 42   Từ đã học   │   │  ← 4 stat cards in Wrap
│  │ 🔥 7    Ngày liên...│   │
│  │ 🎯 72%  Điểm quiz...│   │
│  │ ⭐ 1 230 Tổng XP    │   │
│  └────────────────────┘   │
│                           │
│  ┌─── Panel 1 ──┐┌─Panel2┐│  ← side-by-side (≥500px)
│  │ Hoạt động 7   ││ Mức độ││     stacked (<500px)
│  │ ngày          ││ ghi nhớ││
│  │ [bar chart]   ││[donut]││
│  └───────────────┘└───────┘│
│                           │
│  Lịch học 14 tuần gần đây  │
│  [14x7 heatmap grid]      │  ← 98 ô màu
│                           │
│  Huy hiệu                  │
│  [🔥] [📘] [🎯] [🌙] [🏆] │  ← badges grid
│   7n    100t   Điểm  Cúđêm  30n
│   streak  từ   TĐ            streak
└──────────────────────────┘
```

### Stat cards
| Icon | Label | Color |
|:----:|-------|-------|
| 📘 | Từ đã học | blue |
| 🔥 | Ngày liên tiếp | danger |
| 🎯 | Điểm quiz trung bình | warning |
| ⭐ | Tổng XP | success |

### Charts
1. **Bar chart 7 ngày** — cột dọc theo thứ T2-CN, hôm nay màu warning
2. **Donut chart** — mức độ ghi nhớ: Đã thuộc 🟢 / Đang học 🔵 / Mới ⚪
3. **Calendar heatmap** — 14 tuần × 7 ngày, 4 mức màu xanh lá

### Badges
- Circle icons, 56px, viền vàng khi unlocked, xám khi locked
- Tên badge bên dưới

---

## 17. Bookmark

**Route:** `/bookmark`  
**Trạng thái:** Loading / Error / Empty / Data

### Layout
```
┌──────────────────────────┐
│  Từ đã lưu       [Ôn tập] │  ← top bar
│  42 từ bạn đã đánh dấu    │
├──────────────────────────┤
│  🔍 Tìm từ đã lưu...      │  ← search (max 280px)
│                           │
│  [Tất cả·42] [Mới·12]    │  ← filter tabs (horizontal scroll)
│  [Đang học·20] [Đã thuộc·10]│
│                           │
│  ┌──────┐ ┌──────┐ ┌────┐│  ← stamp grid (4 cols desktop
│  │hello │ │world │ │cat ││     3 cols mobile)
│  │/heləʊ/│ │/wɜːld/│ │...││
│  │xin    │ │thế   │ │    ││
│  │chào   │ │giới  │ │    ││
│  │MỚI ⭐ │ │ĐANG  │ │    ││
│  └──────┘ └──────┘ └────┘│
└──────────────────────────┘
```

### Word stamp card
- Dashed border (CustomPaint)
- Word + IPA (blue) + meaning + tag badge
- Star toggle button (góc trên phải): warning khi starred
- Tag colors: Mới (warning), Đang học (blue), Đã thuộc (success)

### States
| State | Hiển thị |
|-------|---------|
| **Loading** | Skeleton grid |
| **Error** | ErrorStateWidget |
| **Empty (no words)** | "Chưa có từ vựng nào" + "Thêm từ mới" CTA |
| **Empty (filtered)** | "Không tìm thấy từ" + "Xoá bộ lọc" |

---

## 18. Kho từ vựng (Topic Browser)

**Route:** `/topics`  
**Trạng thái:** Loading / Error / Data / Empty search

### Layout
```
┌──────────────────────────┐
│    Kho từ vựng            │  ← AppBar
├──────────────────────────┤
│  🔍 Tìm chủ đề từ vựng...  │  ← search bar
│                           │
│  ┌─────────┐ ┌─────────┐  │  ← grid 2 columns
│  │  👋      │ │  👨‍👩‍👧‍👦    │  │
│  │ Greetings│ │ Family  │  │
│  │ 30 từ    │ │ 25 từ   │  │
│  └─────────┘ └─────────┘  │
│  ┌─────────┐ ┌─────────┐  │
│  │  ...     │ │  ...     │  │
│  └─────────┘ └─────────┘  │
└──────────────────────────┘
```

### Topic card
- Icon (48px box, blueBg, radius 14)
- Title (14px bold)
- Count (`{n} từ`)
- Aspect ratio: 0.9

### 15 topics
| # | Icon | Title | Words |
|:-:|:----:|-------|:-----:|
| 1 | 👋 | Greetings & Introductions | 30 |
| 2 | 👨‍👩‍👧‍👦 | Family & Relationships | 25 |
| 3 | 🔢 | Numbers, Time & Dates | 30 |
| 4 | ☀️ | Daily Routines | 30 |
| 5 | 🍕 | Food & Drinks | 35 |
| 6 | ✈️ | Travel & Directions | 30 |
| 7 | 🛍️ | Shopping & Prices | 30 |
| 8 | 🌤️ | Weather & Seasons | 25 |
| 9 | 🏥 | Health & Body | 30 |
| 10 | 💼 | Work & Business | 35 |
| 11 | 📚 | Education & School | 30 |
| 12 | 🎮 | Entertainment & Hobbies | 25 |
| 13 | 💻 | Technology & Internet | 30 |
| 14 | 💛 | Emotions & Feelings | 25 |
| 15 | 🌍 | Society & Culture | 30 |

---

## 19. Chi tiết chủ đề

**Route:** `/topics/:lessonId`  
**Trạng thái:** Loading / Error / Data

### Layout
```
┌──────────────────────────┐
│ ← {Topic name}            │  ← AppBar
├──────────────────────────┤
│  ┌────────────────────┐   │
│  │  ▶ Làm quiz         │   │  ← CTA: quiz theo topic
│  └────────────────────┘   │
│                           │
│  ┌────────────────────┐   │  ← mỗi vocab item
│  │  hello     🔊 [＋]   │   │
│  │  /həˈloʊ/            │   │
│  │  xin chào            │   │
│  │  ┌───────────────┐   │   │
│  │  │ "Hello, how    │   │   │  ← example (italic)
│  │  │  are you?"     │   │   │
│  │  └───────────────┘   │   │
│  └────────────────────┘   │
│  ...                      │
└──────────────────────────┘
```

### Vocab item
- Word (17px bold) + speaker button
- Pronunciation (IBM Plex Mono, 13px, grey)
- Meaning (15px, blue)
- Example sentence (italic, grey bg, radius 10)
- Add button (+) → thêm vào từ vựng cá nhân

---

## 20. AI Chat

**Route:** `/ai-chat`  
**Trạng thái:** Chat interface

### Layout
```
┌──────────────────────────┐
│ ← 🤖 Meu - Trợ lý AI     │  ← AppBar + status "Online"
│       Online              │
├──────────────────────────┤
│                           │
│  🤖 Chào bạn! 👋          │  ← AI bubble (white bg)
│  Tôi là Meu...            │
│       [Gợi ý 1] [Gợi ý 2]│  ← suggestion chips (blue bg)
│                           │
│                    ┌────┐ │
│                    │Hello│ │  ← User bubble (blue bg)
│                    └────┘ │
│                           │
│  🤖 "Hello" có nghĩa...   │
│       [Giải thích thêm]   │
│                           │
├──────────────────────────┤
│  ┌────────────────────┐ ▶ │  ← input bar
│  │ Hỏi Meu về từ vựng..│   │
│  └────────────────────┘   │
└──────────────────────────┘
```

### Features
- Welcome message with suggested topics
- User messages: blue bubble, right-aligned
- AI messages: white bubble, left-aligned, bot avatar
- Suggestion chips dưới mỗi câu trả lời AI
- Input: rounded pill, send button (blue circle)
- Loading: "Meu đang trả lời..." + spinner
- Error: "AI hiện không khả dụng" message + error detail

---

## 21. Vocabulary List

**Route:** `/vocabulary`  
**Trạng thái:** Loading / Error / Empty / Data

### Layout
```
┌──────────────────────────┐
│    Từ vựng            [≡] │  ← AppBar + drawer menu
├──────────────────────────┤
│  🔍 Tìm kiếm từ vựng...   │  ← search bar
│                           │
│  [Tất cả] [greetings] ... │  ← filter chips (horizontal)
│                           │
│  ┌────────────────────┐   │  ← VocabCard items
│  │ hello               │   │
│  │ xin chào            │   │
│  │ 📁 greetings  ★     │   │
│  │ ✏️ 🗑️              │   │
│  └────────────────────┘   │
│  ...                      │
├──────────────────────────┤
│                    [＋] FAB│  ← add new vocab
└──────────────────────────┘
```

### VocabCard
- Word + meaning
- Topic badge + bookmark star
- Edit/Delete actions (tap edit → form, tap delete → confirm dialog)

### States
| State | Hiển thị |
|-------|---------|
| **Loading** | Skeleton list |
| **Error** | ErrorStateWidget |
| **Empty (new user)** | "Chưa có từ vựng nào" + "Thêm từ đầu tiên" CTA |
| **Empty (filtered)** | "Không tìm thấy từ vựng" |
| **Data** | RefreshIndicator + ListView |

---

## 22. Vocabulary Form

**Routes:** `/vocabulary/new` (add), `/vocabulary/:id/edit` (edit)  
**Trạng thái:** Form entry / Loading (edit)

### Layout
```
┌──────────────────────────┐
│ ← Thêm từ mới / Sửa từ    │  ← AppBar
├──────────────────────────┤
│                           │
│  [Từ vựng *]              │  ← text field
│  [Nghĩa *]                │
│  [Ví dụ]                  │  ← 2 lines
│                           │
│  Chủ đề                   │
│  [Tổng hợp] [giao tiếp]   │  ← topic chips
│  [du lịch] [công việc]   │
│  [học tập] [Thêm mới +]   │  ← custom topic toggle
│                           │
│  ┌────────────────────┐   │
│  │  Lưu từ vựng        │   │  ← gradient CTA
│  └────────────────────┘   │
└──────────────────────────┘
```

### Fields
| Field | Required | Notes |
|-------|:--------:|-------|
| Từ vựng | ✅ | word input |
| Nghĩa | ✅ | meaning input |
| Ví dụ | ❌ | multi-line (2), optional |
| Chủ đề | ✅ | chip selector or custom input |

### States
| State | Hiển thị |
|-------|---------|
| **Loading (edit)** | Skeleton form |
| **Saving** | Spinner in button |
| **Success** | Snackbar + pop |
| **Error** | Error snackbar |

---

## 📊 Summary — Routes & States

| # | Screen | Route | States |
|:-:|--------|-------|--------|
| 1 | Splash | `/splash` | — (static animation) |
| 2 | Onboarding | `/onboarding` | — (static wizard) |
| 3 | Login | `/login` | Loading / Error / Success |
| 4 | Register | `/register` | Loading / Error / Success |
| 5 | Dashboard | `/` | Loading / Error / Empty / Data |
| 6 | Quiz List | `/quiz` | — (config only) |
| 7 | Quiz Play | `/quiz/play` | Loading questions / Playing / Result |
| 8 | Quiz Result | `/quiz/result/:id` | Data / No data |
| 9 | Quiz History | `/quiz/history` | Loading / Error / Empty / Data |
| 10 | Flashcard | `/flashcard` | Loading / Error / Empty / Data |
| 11 | Mock Test | `/mock-test` | Loading / Error / Data (history) |
| 12 | Mock Test Play | `/mock-test/play/:level` | Loading / Error / Playing / Submitted |
| 13 | Mock Test Result | `/mock-test/result/:id` | Data |
| 14 | Profile | `/profile` | Loading / Error / Data |
| 15 | Progress | `/progress` | Loading / Error / Empty / Data |
| 16 | Bookmark | `/bookmark` | Loading / Error / Empty / Filtered-empty / Data |
| 17 | Topic Browser | `/topics` | Loading / Error / Data / Empty search |
| 18 | Topic Detail | `/topics/:lessonId` | Loading / Error / Data |
| 19 | AI Chat | `/ai-chat` | Chat / Loading / Error |
| 20 | Vocabulary List | `/vocabulary` | Loading / Error / Empty / Data |
| 21 | Vocabulary Form | `/vocabulary/new`, `/vocabulary/:id/edit` | Form / Loading (edit) / Saving |

---

## 🎯 Design Guidelines cho UI mới

1. **Giữ nguyên Color System** — Cobalt Blue accent + semantic colors
2. **Giữ nguyên Font** — Work Sans (body) + IBM Plex Mono (numbers)
3. **Layout patterns:**
   - AppBar: surface bg, 0 elevation, center title
   - Card: white surface, radius 12-18, subtle border (8-14% ink)
   - Button: full-width 48-56px, radius 10-16, gradient blue
   - Input: filled bg=#F8F9FA, radius 10, blue focus
4. **4-state pattern cho mọi màn hình có data:** Loading → Error → Empty → Data
5. **Responsive:** Bottom nav (mobile) ↔ Sidebar (desktop ≥ 768px)
6. **Animation:** Page transitions dùng slide + fade (300ms easeOutCubic)
7. **Tiếng Việt** cho mọi text người dùng thấy
