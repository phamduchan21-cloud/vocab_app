# 🎨 Phân tích & Giải pháp Thiết kế Trang Chủ — MeuBeu

> **Ngày cập nhật:** 30/06/2026  
> **Mục tiêu:** Thiết kế Home Screen ấn tượng, tối ưu trải nghiệm học từ vựng, lấy cảm hứng từ các mẫu tham khảo

---

## 📸 Phân tích Ảnh tham khảo

### Ảnh 1 — Duolingo-style Learning Path

```
┌──────────────────────────────────────┐
│ 🔥 12  ·  💎 2300  ·  ⭐ 450        │  ← Streak Bar + Gems + XP
├──────────────────────────────────────┤
│  🌟 VIP (trial 3 days)               │  ← Upsell banner
│                                      │
│  ┌────────────────────────────────┐  │
│  │  ○ → ○ → ○ → ○ → ○ → ○       │  │  ← Learning path (dạng node)
│  │              ↓                │  │
│  │  ○ → ★ Quiz → ○               │  │
│  │              ↓                │  │
│  │  ○ → ○ → ○ → ○               │  │
│  └────────────────────────────────┘  │
│                                      │
│  [🔤 Học chữ cái]                    │  ← CTA chính
│  [🛒 Shop] [🏆 League] [👤 Profile]  │  ← Bottom nav
└──────────────────────────────────────┘
```

#### 🎯 Điểm mạnh:
- **Streak bar nổi bật** — kích thích giữ streak mỗi ngày
- **Learning path trực quan** — thấy rõ tiến độ, bài tiếp theo
- **Gamification elements** — gems, avatar, shop
- **Mascot thân thiện** — tạo cảm giác gần gũi

#### ⚠️ Điểm yếu (với app học từ vựng):
- Không có **spaced repetition** — ôn tập từ cũ
- Không hiển thị **thống kê học tập** (từ đã học, độ chính xác)
- Thiếu **danh mục chủ đề** — học viên không biết từ theo topic

---

### Ảnh 2 & 3 — Modern Dashboard (Progress Tracking)

```
┌──────────────────────────────────────┐
│  📚 YOUR COURSES                     │
│  ┌──────────────────────────────┐    │
│  │  📖 Tiếng Anh cơ bản         │    │
│  │  ████████████░░░░ 68%        │    │
│  │  Tiếp tục →                    │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │  📖 Từ vựng TOPIK            │    │
│  │  ████████░░░░░░ 45%          │    │
│  │  Tiếp tục →                    │    │
│  └──────────────────────────────┘    │
│                                      │
│  📊 YOUR STATS                       │
│  ┌──────┬──────┬──────┬──────┐      │
│  │ 📝 24│ 🔥 12 │ ⭐ 450│ 💎 23│      │
│  │ Bài  │Ngày  │ XP   │ Gems │      │
│  └──────┴──────┴──────┴──────┘      │
│                                      │
│  📅 TODAY'S REVIEW                   │
│  Bạn có 5 từ cần ôn hôm nay          │
│  [Bắt đầu ôn tập]                     │
└──────────────────────────────────────┘
```

#### 🎯 Điểm mạnh:
- **Progress bar theo course** — thấy rõ tiến độ
- **Stats grid** — tổng quan nhanh
- **Today's review section** — nhắc nhở ôn tập
- **Layout sạch sẽ** — dễ nhìn, dễ thao tác

#### ⚠️ Điểm yếu:
- Thiếu **gamification** — không có streak, achievement
- Thiếu **tính tương tác** — chỉ hiển thị thông tin
- **Màu sắc đơn điệu** — chưa tạo cảm hứng

---

## 💡 Giải pháp thiết kế — MeuBeu Home Screen

### 🎯 Triết lý thiết kế

> **Kết hợp tinh hoa:** Duolingo (gamification + engagement) × Dashboard (progress + stats) × MeuBeu (từ vựng + spaced repetition)

---

### 🏠 Bố cục Home Screen MeuBeu

```
┌──────────────────────────────────────────────┐
│  🔥 Streak Bar (Section 1)                   │
│  ┌───────┬──────────────────┬──────────────┐ │
│  │  🔥   │ 📊 78% tuần     │ 💎 2,300      │ │
│  │  12   │ Mục tiêu: 500 XP │              │ │
│  │  ngày │                  │              │ │
│  └───────┴──────────────────┴──────────────┘ │
│  "Học thêm 3 ngày nữa là được huy hiệu 15!"  │
├──────────────────────────────────────────────┤
│                                              │
│  📖 Ôn tập hôm nay (Section 2)               │
│  ┌──────────────────────────────────────┐   │
│  │  🧠 5 từ cần ôn · Đã ôn 2/5 (40%)   │   │
│  │  ████████████░░░░░░░░░░░░░░░░░░░░░░  │   │
│  │  [▶  Ôn tập ngay — 3 phút]           │   │  ← CTA chính #1
│  └──────────────────────────────────────┘   │
│                                              │
│  📘 Học từ mới (Section 3)                   │
│  ┌──────────────────────────────────────┐   │
│  │  🌟 Chủ đề: "Du lịch"               │   │
│  │  📝 3 từ mới hôm nay                 │   │
│  │  [➕  Học từ mới →]                  │   │  ← CTA chính #2
│  └──────────────────────────────────────┘   │
│                                              │
│  📊 Tiến độ tổng quan (Section 4)            │
│  ┌──────┬──────┬──────┬──────┐              │
│  │ 📚   │ 🧠   │ 📈   │ 🏆   │              │
│  │ 120  │ 85   │ 82%  │ Level│              │
│  │ từ   │ thuộc│ chính │ 5 🌳 │              │
│  │      │      │ xác  │      │              │
│  └──────┴──────┴──────┴──────┘              │
│                                              │
│  📂 Chủ đề từ vựng (Section 5)               │
│  ┌──────┬──────┬──────┬──────┐              │
│  │ 🌍   │ 💼   │ 🍜   │ 🏥   │              │
│  │ DLịch │ CViệc│ Ẩm   │ Y tế │              │
│  │ 45 từ │ 32 từ │ thực │ 15 từ│              │
│  │ 📈82%│ 📈75%│ 28 từ│ 📈40%│              │
│  │      │      │ 📈60%│      │              │
│  └──────┴──────┴──────┴──────┘              │
│  [Xem tất cả chủ đề →]                       │
│                                              │
│  🏆 Bảng xếp hạng (Section 6)                │
│  ┌──────────────────────────────────────┐   │
│  │ 🥇 Bạn · 1,200 XP                    │   │
│  │ 🥈 Ngọc · 980 XP                     │   │
│  │ 🥉 Minh · 750 XP                     │   │
│  └──────────────────────────────────────┘   │
│  [Xem bảng xếp hạng →]                       │
│                                              │
├──────────────────────────────────────────────┤
│  🏠  📚  🎯  👤                            │  ← Bottom Nav
└──────────────────────────────────────────────┘
```

---

### 📐 Chi tiết từng Section

#### Section 1: Streak Bar (🔥)

```
┌──────────────────────────────────────┐
│  🔥 12    📊 78%     💎 2,300       │
│  "Học thêm 3 ngày nữa là được       │
│   huy hiệu 15 ngày! 🏅"              │
└──────────────────────────────────────┘
```

Design:
- **Nền gradient tím** — màu chủ đạo MeuBeu
- **Streak 🔥** — icon lửa + số ngày, to và rõ
- **Progress tuần** — % hoàn thành mục tiêu XP
- **Gems 💎** — tiền ảo
- **Message động** — thay đổi theo streak (1→6: "Bắt đầu tốt!", 7→13: "1 tuần — giỏi lắm!", ...)

**States:**
| State | Hiển thị |
|-------|----------|
| Loading | Skeleton 3 cột |
| Error | Ẩn gem, chỉ hiện offline |
| Empty | "🔥 Bắt đầu streak ngay hôm nay!" |
| Data | Đầy đủ streak + progress + gems |

#### Section 2: Today's Review — Spaced Repetition (📖)

```
┌──────────────────────────────────────┐
│  📖 Ôn tập hôm nay                   │
│  ┌──────────────────────────────┐    │
│  │  🧠 5 từ cần ôn             │    │
│  │  Đã ôn 2/5 (40%)             │    │
│  │  ████████████░░░░░░░░░░░░░░  │    │
│  │                              │    │
│  │  [▶  Ôn tập ngay — 3 phút]  │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**Logic:** Lấy từ vựng có `next_review_date <= today` (SM-2 algorithm).
- Nếu chưa review lần nào → ưu tiên ôn trước
- Nếu đã ôn hết → "🎉 Hôm nay bạn đã ôn xong!"

**States:**
| State | Hiển thị |
|-------|----------|
| Loading | Skeleton card |
| Error | "Không thể tải dữ liệu" + [Thử lại] |
| Empty | "🎉 Đã ôn xong! Quay lại vào ngày mai." |
| Data | Progress bar + CTA |

#### Section 3: New Words (📘)

```
┌──────────────────────────────────────┐
│  📘 Học từ mới                       │
│  ┌──────────────────────────────┐    │
│  │  🌟 Chủ đề: "Du lịch"        │    │
│  │  📝 3 từ mới hôm nay         │    │
│  │                              │    │
│  │  [➕  Học từ mới →]          │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**Cơ chế:** Mỗi ngày gợi ý 3-5 từ mới từ chủ đề user chưa học nhiều.

**States:**
| State | Hiển thị |
|-------|----------|
| Loading | Skeleton |
| Error | "Không thể tải từ mới" + [Thử lại] |
| Empty | "🎉 Bạn đã học hết từ! [Tạo từ vựng mới]" |
| Data | Chủ đề + số lượng + CTA |

#### Section 4: Stats Grid (📊)

```
┌──────────────────────────────────────┐
│  📊 Tiến độ tổng quan                │
│  ┌──────┬──────┬──────┬──────┐      │
│  │ 📚   │ 🧠   │ 📈   │ 🏆   │      │
│  │ 120  │ 85   │ 82%  │ Level│      │
│  │ từ   │ thuộc│ chính│ 5 🌳 │      │
│  │      │      │ xác  │      │      │
│  └──────┴──────┴──────┴──────┘      │
└──────────────────────────────────────┘
```

**Stats:**
- 📚 **Tổng từ** — số từ đã thêm
- 🧠 **Đã thuộc** — words có review_count ≥ 3 và times_correct > times_wrong
- 📈 **Độ chính xác** — từ tất cả quiz
- 🏆 **Level** — 6 cấp từ 🌱 Mầm non đến 👑 Huyền thoại

**States:**
| State | Hiển thị |
|-------|----------|
| Loading | 4× skeleton box |
| Error | Ẩn section |
| Empty | "Bắt đầu học để xem thống kê!" |
| Data | 4 ô stats |

#### Section 5: Topic Grid (📂)

```
┌──────────────────────────────────────┐
│  📂 Chủ đề từ vựng                   │
│  ┌──────┬──────┬──────┬──────┐      │
│  │ 🌍   │ 💼   │ 🍜   │ 🏥   │      │
│  │ DLịch │ CViệc│ Ẩm thực│ Y tế │      │
│  │ 45 từ │ 32 từ │ 28 từ │ 15 từ │      │
│  │ 📈82%│ 📈75%│ 📈60%│ 📈40%│      │
│  └──────┴──────┴──────┴──────┘      │
│  [Xem tất cả →]                      │
└──────────────────────────────────────┘
```

**Thiết kế:** Grid 2 hàng × 4 cột (mobile) hoặc 1 hàng × 4 cột (tablet).
Mỗi ô hiển thị:
- Icon chủ đề
- Tên chủ đề
- Số từ + % mastery

**States:**
| State | Hiển thị |
|-------|----------|
| Loading | 4× skeleton box |
| Error | Ẩn section (không critical) |
| Empty | "Thêm từ vựng để tạo chủ đề!" |
| Data | Grid đầy đủ |

#### Section 6: Leaderboard (🏆)

```
┌──────────────────────────────────────┐
│  🏆 Bảng xếp hạng tuần này          │
│  ┌──────────────────────────────┐    │
│  │ 🥇 Bạn · 1,200 XP           │    │ ← Highlight user
│  │ 🥈 Ngọc · 980 XP            │    │
│  │ 🥉 Minh · 750 XP            │    │
│  │ 4. Lan · 620 XP             │    │
│  │ 5. Huy · 500 XP             │    │
│  └──────────────────────────────┘    │
│  [Xem tất cả →]                      │
└──────────────────────────────────────┘
```

**States:**
| State | Hiển thị |
|-------|----------|
| Loading | Skeleton |
| Error | Ẩn section |
| Empty | "Mời bạn bè để cùng học!" |
| Data | Top 5 + highlight user |

---

## 🎮 Gamification System

### Streak Milestones

| Streak | Reward | Message |
|--------|--------|---------|
| 1-6 | +10 gems/ngày | "🔥 Khởi đầu tốt!" |
| **7** | 🏅 Huy hiệu + 50 gems | "🔥 1 tuần — giỏi lắm!" |
| 14 | 100 gems | "🔥 2 tuần liên tiếp!" |
| **30** | 🏅 Huy hiệu + 200 gems | "🔥 1 tháng — xuất sắc!" |
| 60 | 300 gems | "🔥 Kiên trì quá!" |
| **100** | 🏅 Huy hiệu + 500 gems | "🔥 Huyền thoại!" |

### XP System

| Hành động | XP |
|-----------|----|
| Học 1 từ mới | +5 |
| Ôn tập 1 từ | +3 |
| Quiz đúng 1 câu | +10 |
| Hoàn thành quiz | +15 |
| Streak milestone | +50~1000 |

### Levels

| Level | XP Required | Title |
|-------|-------------|-------|
| 1-5 | 0-500 | 🌱 Mầm non |
| 6-10 | 500-1500 | 🌿 Lá xanh |
| 11-20 | 1500-4000 | 🌳 Cây lớn |
| 21-35 | 4000-8000 | 🏔️ Cao thủ |
| 36-50 | 8000-15000 | 🦅 Phiêu lưu |
| 50+ | 15000+ | 👑 Huyền thoại |

---

## 🧩 Widget Tree (Flutter)

```
DashboardScreen (ConsumerWidget)
├── _buildLoading()          → SkeletonLoading
├── _buildError(msg)         → ErrorStateWidget + [Thử lại]
├── _buildEmpty()            → EmptyStateWidget + [Thêm từ đầu tiên]
└── _buildContent(DashboardData)
    ├── RefreshIndicator
    │   └── CustomScrollView
    │       ├── SliverToBoxAdapter
    │       │   └── StreakBar
    │       │       ├── StreakCounter
    │       │       ├── WeeklyProgress
    │       │       └── GemsDisplay
    │       │
    │       ├── SliverToBoxAdapter
    │       │   └── ReviewCard
    │       │       ├── [Loading] → Skeleton
    │       │       ├── [Empty] → "🎉 Hoàn thành"
    │       │       └── [Data] → Progress + [Ôn tập]
    │       │
    │       ├── SliverToBoxAdapter
    │       │   └── NewWordsCard
    │       │       ├── [Loading] → Skeleton
    │       │       ├── [Empty] → "Đã học hết!"
    │       │       └── [Data] → Topic + [Học mới]
    │       │
    │       ├── SliverToBoxAdapter
    │       │   └── StatsGrid
    │       │       ├── [Loading] → 4× skeleton
    │       │       ├── [Empty] → "Chưa có dữ liệu"
    │       │       └── [Data] → 4 ô stats
    │       │
    │       ├── SliverToBoxAdapter
    │       │   └── TopicGrid
    │       │       ├── [Loading] → 4× skeleton grid
    │       │       ├── [Empty] → "Chưa có chủ đề"
    │       │       └── [Data] → 2×4 grid
    │       │
    │       └── SliverToBoxAdapter
    │           └── LeaderboardPreview
    │               ├── [Loading] → Skeleton
    │               ├── [Empty] → "Mời bạn bè"
    │               └── [Data] → Top 5
    │
    └── BottomNavigationBar
        ├── Home (active)
        ├── Vocabulary
        ├── Quiz
        └── Profile
```

---

## 📦 Provider State

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

  // Main load function
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi song song 4 API
      final results = await Future.wait([
        _dashboardService.getStats(),          // GET /api/dashboard
        _dashboardService.getTodayReview(),     // GET /api/dashboard/today-review
        _dashboardService.getTopicProgress(),   // GET /api/dashboard/topic-progress
        _gamificationService.getLeaderboard(),  // GET /api/gamification/leaderboard
      ]);
      _data = DashboardData(
        stats: results[0] as DashboardResponse,
        reviews: results[1] as TodayReviewResponse,
        topics: results[2] as TopicProgressResponse,
        leaderboard: results[3] as LeaderboardResponse,
      );
    } catch (e) {
      _errorMessage = "Rất tiếc! Không thể tải dữ liệu. Vui lòng thử lại!";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## 🔄 Data Flow

```
App mở → Auth check → DashboardScreen.build()
    │
    ├── isLoading = true → Skeleton
    │
    ├── Provider.loadDashboard()
    │   ├── FUTURE.WAIT:
    │   │   ├── GET /api/dashboard
    │   │   ├── GET /api/dashboard/today-review
    │   │   ├── GET /api/dashboard/topic-progress
    │   │   └── GET /api/gamification/leaderboard
    │   │
    │   ├── SUCCESS → _data = response → notify
    │   └── ERROR → _errorMessage = "..." → notify
    │
    ├── Data → Hiển thị 6 sections
    └── Empty → Hiển thị EmptyState + CTA
```

---

## 🎨 Color Palette

```
MeuBeu Brand Colors
┌──────────────────────────────────────────────┐
│  Primary:    #8B5CF6  (Tím)                  │
│  PrimaryLight: #A78BFA                       │
│  PrimaryDark:  #6D28D9                       │
│                                              │
│  Secondary:  #F472B6  (Hồng)                 │
│  SecondaryLight: #F9A8D4                     │
│                                              │
│  Accent1:    #FB923C  (Cam)                  │
│  Accent2:    #EF4444  (Đỏ)                   │
│  Accent3:    #34D399  (Xanh mint)            │
│                                              │
│  Background: #FAFAFA                         │
│  Surface:    #FFFFFF                         │
│  TextPrimary: #1F2937                        │
│  TextSecondary: #6B7280                      │
└──────────────────────────────────────────────┘
```

---

## 📋 So sánh giải pháp vs Ảnh tham khảo

| Tính năng | Ảnh 1 (Duolingo) | Ảnh 2&3 (Dashboard) | MeuBeu (Giải pháp) |
|-----------|:---:|:---:|:---:|
| Streak Bar | ✅ | ❌ | ✅ **Nổi bật hơn** |
| Learning Path | ✅ | ❌ | ⚠️ Theo chủ đề |
| Spaced Repetition | ❌ | ✅ | ✅ **SM-2 Algorithm** |
| Stats Grid | ❌ | ✅ | ✅ **4 ô trực quan** |
| Topic Grid | ❌ | ❌ | ✅ **Mới** |
| Leaderboard | ✅ | ❌ | ✅ **Top 5 bạn bè** |
| Gamification | ✅✅ | ❌ | ✅ **Đầy đủ** |
| Daily Review | ❌ | ✅ | ✅ **Ưu tiên hàng đầu** |
| Bottom Nav | ✅ | ✅ | ✅ **4 tab** |
| Mascot | ✅ | ❌ | ✅ **Mèo MeuBeu** |

---

## 🚀 Kế hoạch triển khai

### Backend (Đã code xong — Phase 1)

| Endpoint | Status |
|----------|--------|
| `GET /api/dashboard` | ✅ Mở rộng với streak/xp/gems/level |
| `GET /api/dashboard/today-review` | ✅ Spaced repetition |
| `GET /api/dashboard/topic-progress` | ✅ Tiến độ theo chủ đề |
| `GET /api/dashboard/weekly-activity` | ✅ Heatmap 7 ngày |
| `POST /api/gamification/record-activity` | ✅ XP + Streak |
| `GET /api/gamification/achievements` | ✅ Thành tựu |
| `GET /api/gamification/leaderboard` | ✅ Bảng xếp hạng |
| `PUT /api/vocabularies/{id}/review` | ✅ SM-2 update |

### Frontend — Phase 2 (Cần code)

| Task | Widget | API |
|------|--------|-----|
| 1. DashboardData model | — | — |
| 2. DashboardService (mở rộng) | — | 4 API calls |
| 3. DashboardProvider | — | Future.wait 4 calls |
| 4. **StreakBar** widget | `widgets/streak_bar.dart` | GET /api/dashboard |
| 5. **ReviewCard** widget | `widgets/review_card.dart` | GET /api/dashboard/today-review |
| 6. **NewWordsCard** widget | `widgets/new_words_card.dart` | GET /api/vocabularies?limit=3 |
| 7. **StatsGrid** widget | `widgets/stats_grid.dart` | GET /api/dashboard |
| 8. **TopicGrid** widget | `widgets/topic_grid.dart` | GET /api/dashboard/topic-progress |
| 9. **LeaderboardPreview** widget | `widgets/leaderboard_preview.dart` | GET /api/gamification/leaderboard |
| 10. **DashboardScreen rewrite** | `screens/dashboard_screen.dart` | Tích hợp 6 sections |

---

## 📱 Mobile Layout (cuộn dọc)

```
┌──────────────────────────┐
│ 🔥 Streak Bar            │ ← Section 1
├──────────────────────────┤
│ 📖 Ôn tập hôm nay        │ ← Section 2 (CTA chính)
├──────────────────────────┤
│ 📘 Học từ mới            │ ← Section 3
├──────────────────────────┤
│ 📊 Tiến độ (4 stats)     │ ← Section 4
├──────────────────────────┤
│ 📂 Chủ đề từ vựng        │ ← Section 5
├──────────────────────────┤
│ 🏆 Bảng xếp hạng         │ ← Section 6
├──────────────────────────┤
│ 🏠  📚  🎯  👤          │ ← Bottom Nav
└──────────────────────────┘
```

---

## 💬 User Flow

```
Mở app
  │
  ├── Chưa login → Login / Register
  │
  └── Đã login → Dashboard
        │
        ├── Thấy Streak Bar → Động lực
        ├── Thấy Review Card → Ôn tập từ cũ (CTA #1)
        ├── Thấy New Words → Học từ mới (CTA #2)
        ├── Thấy Stats → Đánh giá tiến độ
        ├── Thấy Topics → Chọn chủ đề học
        └── Thấy Leaderboard → Cạnh tranh
```

---

## ✅ Tổng kết

| Khía cạnh | Giá trị |
|-----------|---------|
| 🎯 **Trải nghiệm** | Kết hợp Duolingo + Dashboard hiện đại |
| 🧠 **Khoa học** | Spaced Repetition (SM-2) giúp ghi nhớ lâu |
| 🎮 **Gamification** | Streak, XP, Level, Gems, Achievement |
| 📊 **Thông tin** | Stats, Topic Progress, Leaderboard |
| 🐱 **Thương hiệu** | Mèo MeuBeu — tím + hồng, thân thiện |
| ⚡ **Performance** | Future.wait load 4 API song song |
| 🔄 **States** | Loading → Error → Empty → Data (đầy đủ) |
