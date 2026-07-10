# 📱 Tổng quan các màn hình & Widget

> App: **Học Từ Vựng** (Vocabulary Learning App)  
> Stack: Flutter · FastAPI · Supabase  
> Cập nhật: 2026-07-08

---

## 🖥 Danh sách màn hình (Screens)

### 1. `SplashScreen` — Màn hình chào
| | |
|---|---|
| **File** | `splash_screen.dart` |
| **Route** | `/splash` |
| **Chức năng** | Logo app + animation fade-in/slide-up trên gradient. Tự động chuyển sang `/onboard` hoặc `/login` sau ~1.2s. |
| **Dùng** | `CatWidget`, `AppTheme.primaryGradient` |

---

### 2. `OnboardingScreen` — Hướng dẫn & khảo sát
| | |
|---|---|
| **File** | `onboarding_screen.dart` |
| **Route** | `/onboard` |
| **Chức năng** | 9 trang PageView (1 chào + 8 câu hỏi): xác định mục tiêu, trình độ, sở thích của người dùng. Có progress dots, bounce animation con mèo. Sau đó chuyển sang `/login`. |
| **Dùng** | `CatWidget` |

---

### 3. `LoginScreen` — Đăng nhập
| | |
|---|---|
| **File** | `login_screen.dart` |
| **Route** | `/login` |
| **Chức năng** | Form email + password, validation, gradient nền. Nhấn đăng nhập → gọi `AuthProvider.login()` → chuyển về `/`. |
| **Dùng** | `AuthProvider` |

---

### 4. `RegisterScreen` — Đăng ký
| | |
|---|---|
| **File** | `register_screen.dart` |
| **Route** | `/register` |
| **Chức năng** | Form username + email + password + confirm password. Gọi `AuthProvider.register()`. Có nút chuyển sang Login. |
| **Dùng** | `AuthProvider` |

---

### 5. `DashboardScreen` — Trang chủ
| | |
|---|---|
| **File** | `dashboard_screen.dart` |
| **Route** | `/` |
| **Chức năng** | Trang tổng quan chính:
- **Stats bar:** Level, điểm, streak
- **Daily task card:** Nhiệm vụ hằng ngày
- **Topic grid:** Grid chủ đề từ vựng
- **Leaderboard preview:** Bảng xếp hạng
- **Weekly chart:** Biểu đồ hoạt động tuần
- **Weekly challenge:** Thử thách tuần (nếu có)
- **Special offer:** Ưu đãi (nếu có)
- Bottom nav tương ứng 5 tab (Home, Quiz, Flashcard, Test, Profile)
- Responsive layout (sidebar trên desktop, bottom nav trên mobile)
|
| **Provider** | `DashboardProvider`, `TopicProvider`, `AuthProvider`, `ProfileProvider` |
| **Widgets** | `HeroStatsBar`, `DailyTaskCard`, `TopicGrid`, `LeaderboardPreview`, `WeeklyChart`, `AppBottomNav` |

---

### 6. `TopicBrowserScreen` — Khoá từ vựng
| | |
|---|---|
| **File** | `topic_browser_screen.dart` |
| **Route** | `/topics` |
| **Chức năng** | Duyệt danh sách chủ đề / khoá học từ vựng. Có search. Nhấn vào → chi tiết chủ đề. |
| **Provider** | `TopicProvider` |

---

### 7. `TopicDetailScreen` — Chi tiết chủ đề
| | |
|---|---|
| **File** | `topic_detail_screen.dart` |
| **Route** | `/topic/:lessonId` |
| **Chức năng** | Hiển thị danh sách từ vựng theo bài học (lessonId: 1-15 map từ greetings → society). Mỗi từ có: từ, IPA, nghĩa, ví dụ. Nút speaker đọc từ. Nút "Làm quiz" chuyển sang `/quiz`. |
| **Provider** | `TopicProvider`, `QuizProvider` |
| **Service** | `VocabularyService` |
| **Widgets** | `SpeakerButton` |

---

### 8. `QuizListScreen` — Danh sách quiz
| | |
|---|---|
| **File** | `quiz_list_screen.dart` |
| **Route** | `/quiz` |
| **Chức năng** | Chọn:
- **Kỹ năng:** Tất cả / Từ vựng / Ngữ pháp / Đọc hiểu / Nghe hiểu
- **Số câu hỏi** (slider)
- **Chủ đề** (bottom sheet)
- Nút "Bắt đầu" → gọi `QuizProvider.generateQuiz()` → sang `/quiz/play`
|
| **Provider** | `QuizProvider`, `DashboardProvider` |

---

### 9. `QuizPlayScreen` — Làm quiz
| | |
|---|---|
| **File** | `quiz_play_screen.dart` |
| **Route** | `/quiz/play` |
| **Chức năng** | Trắc nghiệm nhiều lựa chọn:
- Timer 60s mỗi câu
- Thanh progress (câu hiện tại / tổng số)
- Chọn đáp án → highlight đúng/sai ngay
- Tự động chuyển câu sau khi chọn
- Hết giờ → tự động chuyển
- Fallback questions nếu API lỗi
|
| **Provider** | `QuizProvider` |

---

### 10. `QuizResultScreen` — Kết quả quiz
| | |
|---|---|
| **File** | `quiz_result_screen.dart` |
| **Route** | `/quiz/result/:id` |
| **Chức năng** | Postmark score animation, điểm số, đáp án đúng/sai, nút "Làm lại" và "Về danh sách". |
| **Provider** | `QuizProvider` |
| **Widgets** | `PostmarkPainter` |

---

### 11. `QuizHistoryScreen` — Lịch sử quiz
| | |
|---|---|
| **File** | `quiz_history_screen.dart` |
| **Route** | `/quiz/history` |
| **Chức năng** | Danh sách các bài quiz đã làm: ngày giờ, số câu đúng/tổng, điểm %. Phân trang (page-based). Pull-to-refresh. |
| **Provider** | `QuizProvider` |
| **Widgets** | `LoadingWidget`, `EmptyStateWidget`, `ErrorStateWidget` |

---

### 12. `MockTestScreen` — Mini-test
| | |
|---|---|
| **File** | `mock_test_screen.dart` |
| **Route** | `/test` |
| **Chức năng** | Chọn cấp độ (Beginner / Intermediate / Advanced) → vào làm test. Hiển thị lịch sử test đã làm (dạng thẻ). |
| **Provider** | `MockTestProvider` |

---

### 13. `MockTestPlayScreen` — Làm mini-test
| | |
|---|---|
| **File** | `mock_test_play_screen.dart` |
| **Route** | `/test/play?level=...&topic=...` |
| **Chức năng** | Bài thi thử:
- Timer 240s (4 phút)
- Nhiều câu hỏi dạng trắc nghiệm
- Review trước khi nộp
- Tự động chấm điểm sau khi nộp
- Tính điểm %, đếm đúng/sai
|
| **Dùng** | `MockTestService`, `ProfileProvider` |

---

### 14. `MockTestResultScreen` — Kết quả mini-test
| | |
|---|---|
| **File** | `mock_test_result_screen.dart` |
| **Route** | nhận `MockTestResult` object |
| **Chức năng** | Score circle (postmark style), xếp loại (A-F), trình độ tiếng Anh (A1-C2). Chi tiết đáp án đúng/sai cho từng câu. |
| **Widgets** | `PostmarkPainter`, `PostmarkScore` |

---

### 15. `FlashcardScreen` — Flashcard học từ
| | |
|---|---|
| **File** | `flashcard_screen.dart` |
| **Route** | `/flashcard` |
| **Chức năng** | 
- Lật thẻ qua animation (flip card)
- Swipe qua lại giữa các thẻ
- **Auto-play:** tự động chạy tuần tự
- Đánh dấu **Đã thuộc** / **Chưa thuộc**
- Chọn **chủ đề/bộ thẻ** qua bottom sheet
- Keyboard shortcuts (phím tắt)
- Bộ đếm: từ đã học / tổng số
- Speaker đọc từ
|
| **Provider** | `FlashcardProvider` |
| **Widgets** | `FlashcardTopicSheet`, `SpeakerButton` |

---

### 16. `VocabularyListScreen` — Danh sách từ vựng
| | |
|---|---|
| **File** | `vocabulary_list_screen.dart` |
| **Route** | `/vocabulary` |
| **Chức năng** | Danh sách tất cả từ vựng (dạng `VocabCard`). Search từ. Xoá từ (có confirm dialog). Nút FAB → thêm từ mới. |
| **Provider** | `VocabularyProvider` |
| **Widgets** | `VocabCard`, `AppDrawer` |

---

### 17. `VocabularyFormScreen` — Thêm / Sửa từ vựng
| | |
|---|---|
| **File** | `vocabulary_form_screen.dart` |
| **Route** | `/vocabulary/add` hoặc `/vocabulary/edit/:id` |
| **Chức năng** | Form thêm/sửa từ: từ (word), nghĩa (meaning), ví dụ (example), chủ đề (topic dropdown + custom topic). Validation. Load dữ liệu cũ nếu edit mode. |
| **Provider** | `VocabularyProvider` |

---

### 18. `BookmarkScreen` — Từ đã bookmark
| | |
|---|---|
| **File** | `bookmark_screen.dart` |
| **Route** | `/bookmark` |
| **Chức năng** | Danh sách từ đã lưu (bookmark). **3 tab filter:** Mới / Đang học / Đã thuộc (dựa trên `reviewCount`). Search từ. Swipe để xoá. |
| **Provider** | `VocabularyProvider` (indirect) |

---

### 19. `ProgressScreen` — Tiến độ
| | |
|---|---|
| **File** | `progress_screen.dart` |
| **Route** | `/progress` |
| **Chức năng** | 
- **Quiz average:** Điểm trung bình các bài quiz
- **Bar chart:** Biểu đồ hoạt động theo ngày trong tuần (T2-CN)
- **Topic stats:** Thống kê từ vựng theo chủ đề
- Pull-to-refresh
|
| **Provider** | `DashboardProvider`, `ProfileProvider`, `QuizProvider` |

---

### 20. `ProfileScreen` — Hồ sơ học tập
| | |
|---|---|
| **File** | `profile_screen.dart` |
| **Route** | `/profile` |
| **Chức năng** | 4 tab:
| | |
|---|---|
| **Tổng quan** | Avatar, tên, email, level, streak, điểm, recent quizzes |
| **Tiến độ** | Weekly activity chart, topic progress |
| **Huy hiệu** | Danh sách thành tích / huy hiệu đã đạt |
| **Tài khoản** | Thông tin cá nhân, chỉnh sửa profile sheet |
| Nút **Nhận thưởng streak** (claim streak reward) |
| **Provider** | `AuthProvider`, `DashboardProvider`, `ProfileProvider` |

---

### 21. `AIChatScreen` — Chat với AI (Meu)
| | |
|---|---|
| **File** | `ai_chat_screen.dart` |
| **Route** | `/ai-chat` |
| **Chức năng** | Chat với trợ lý AI "Meu". Hỗ trợ:
- Giải thích từ vựng
- Ví dụ câu
- Phân biệt từ dễ nhầm
- Ngữ pháp cơ bản
- Tin nhắn chat UI (bubbles), loading state
|
| **Dùng** | `AIService`, `ApiService` |

---

## 🧩 Danh sách Widget dùng chung

| Widget | File | Chức năng |
|--------|------|-----------|
| `AppBottomNav` | `app_bottom_nav.dart` | Bottom navigation 5 tab (Home, Quiz, Flashcard, Test, Profile) |
| `AppDrawer` | `app_drawer.dart` | Navigation drawer |
| `CatWidget` | `cat_widget.dart` | Mascot con mèo hoạt hình (dùng ở Splash, Onboarding) |
| `DailyTaskCard` | `daily_task_card.dart` | Thẻ nhiệm vụ hằng ngày (Dashboard) |
| `EmptyStateWidget` | `empty_state_widget.dart` | Trạng thái rỗng (không có dữ liệu) |
| `ErrorStateWidget` | `error_state_widget.dart` | Trạng thái lỗi + nút thử lại |
| `FlashcardTopicSheet` | `flashcard_topic_sheet.dart` | Bottom sheet chọn chủ đề cho flashcard |
| `HeroStatsBar` | `hero_stats_bar.dart` | Thanh thống kê (Level, Điểm, Streak) |
| `LeaderboardPreview` | `leaderboard_preview.dart` | Preview bảng xếp hạng |
| `LoadingWidget` | `loading_widget.dart` | Loading spinner |
| `PostmarkPainter` | `postmark_painter.dart` | Custom painter con dấu postmark |
| `PostmarkScore` | `postmark_score.dart` | Widget điểm dạng con dấu |
| `SpeakerButton` | `speaker_button.dart` | Nút đọc to từ vựng (TTS) |
| `TopicGrid` | `topic_grid.dart` | Grid danh sách chủ đề từ vựng |
| `VocabCard` | `vocab_card.dart` | Card hiển thị từ vựng |
| `WeeklyChart` | `weekly_chart.dart` | Biểu đồ hoạt động hàng tuần |

---

## 🔄 Luồng điều hướng chính

```
SplashScreen
  → OnboardingScreen (nếu lần đầu)
    → LoginScreen
      → RegisterScreen (nếu chưa có tài khoản)
        → DashboardScreen (/)

DashboardScreen (/)
  ├── TopicBrowserScreen (/topics)
  │     └── TopicDetailScreen (/topic/:lessonId)
  ├── QuizListScreen (/quiz)
  │     ├── QuizPlayScreen (/quiz/play)
  │     │     └── QuizResultScreen (/quiz/result/:id)
  │     └── QuizHistoryScreen (/quiz/history)
  ├── FlashcardScreen (/flashcard)
  ├── MockTestScreen (/test)
  │     ├── MockTestPlayScreen (/test/play)
  │     │     └── MockTestResultScreen
  ├── ProfileScreen (/profile)
  │     ├── ProgressScreen (/progress)
  │     └── BookmarkScreen (/bookmark)
  ├── VocabularyListScreen (/vocabulary)
  │     └── VocabularyFormScreen (/vocabulary/add, /vocabulary/edit/:id)
  └── AIChatScreen (/ai-chat)
```
