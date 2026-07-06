import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/vocabulary.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/flashcard_topic_sheet.dart';
import '../widgets/speaker_button.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isReviewing = false;
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;

  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadDeck();
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
  }

  void _go(int step, int total) {
    setState(() {
      _currentIndex = (_currentIndex + step).clamp(0, total - 1);
      _resetCard();
    });
  }

  Future<void> _handleReview(dynamic item, int quality) async {
    setState(() => _isReviewing = true);
    final flashcard = context.read<FlashcardProvider>();
    final cardItem = _FlashcardItem.fromDynamic(item);
    final success = await flashcard.reviewWord(cardItem.id, quality);
    setState(() => _isReviewing = false);
    if (success) {
      final deck = flashcard.data;
      if (_currentIndex < deck.length - 1) {
        _go(1, deck.length);
      } else {
        setState(() {
          _currentIndex = 0;
          _resetCard();
        });
      }
    }
  }

  void _resetCard() {
    _isFlipped = false;
    _flipController.reverse();
  }

  void _toggleAutoPlay(int deckLength) {
    setState(() {
      _isAutoPlaying = !_isAutoPlaying;
    });
    if (_isAutoPlaying) {
      _startAutoPlay(deckLength);
    } else {
      _autoPlayTimer?.cancel();
    }
  }

  void _startAutoPlay(int deckLength) {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isFlipped) {
        _toggleFlip();
        // After flip animation, wait 2s then advance
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (!mounted || !_isAutoPlaying) return;
          if (_currentIndex < deckLength - 1) {
            _go(1, deckLength);
          } else {
            _toggleAutoPlay(deckLength);
          }
        });
      }
    });
  }

  void _openTopicSheet() {
    final flashcard = context.read<FlashcardProvider>();
    FlashcardTopicSheet.show(
      context,
      topics: flashcard.topics,
      topicItemCount: flashcard.topicItemCount,
      selectedTopic: flashcard.selectedTopic,
      onTopicChanged: (topic) async {
        _currentIndex = 0;
        _resetCard();
        await flashcard.setTopic(topic);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flashcard = context.watch<FlashcardProvider>();
    final deck = flashcard.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Flashcard theo chủ đề',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/'),
        ),
        actions: [
          // Shuffle toggle
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: flashcard.shuffleEnabled ? AppColors.blue : AppColors.inkSoft,
            ),
            onPressed: () => flashcard.toggleShuffle(),
            tooltip: 'Xáo trộn',
          ),
          // Auto-play toggle
          IconButton(
            icon: Icon(
              _isAutoPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
              color: _isAutoPlaying ? AppColors.blue : AppColors.inkSoft,
            ),
            onPressed: () => _toggleAutoPlay(deck.length),
            tooltip: _isAutoPlaying ? 'Dừng tự động' : 'Tự động lật',
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
      body: SafeArea(
        child: Column(
          children: [
            // ── Topic bar (compact) ──────────────────────
            _buildTopicBar(flashcard, deck.length),
            // ── Session stats ────────────────────────────
            _buildSessionStats(flashcard),
            // ── Card body ────────────────────────────────
            Expanded(
              child: _buildBody(flashcard, deck),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicBar(FlashcardProvider flashcard, int deckLength) {
    final topic = flashcard.selectedTopic;
    final label = topic == 'all' ? 'Tất cả chủ đề' : topic;
    final totalItems = flashcard.topicItemCount.values.fold<int>(0, (a, b) => a + b);
    final isAll = topic == 'all';
    final displayCount = isAll ? totalItems : (flashcard.topicItemCount[topic] ?? deckLength);
    final mastery = flashcard.getTopicMastery(topic);

    return GestureDetector(
      onTap: _openTopicSheet,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          children: [
            // Progress ring for current topic
            SizedBox(
              width: 26, height: 26,
              child: CircularProgressIndicator(
                value: mastery,
                strokeWidth: 2.5,
                backgroundColor: AppColors.surfaceSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(
                  mastery < 0.33 ? AppColors.danger
                      : mastery < 0.66 ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.workSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: AppColors.inkSoft, size: 20),
            const SizedBox(width: 8),
            Text(
              '$displayCount thẻ',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                color: AppColors.ink.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStats(FlashcardProvider flashcard) {
    if (flashcard.sessionReviewed == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('📊', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            'Hôm nay: ${flashcard.sessionReviewed} thẻ',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              color: AppColors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 14, color: AppColors.blue.withValues(alpha: 0.2)),
          const SizedBox(width: 12),
          Text(
            'Chính xác: ${flashcard.sessionAccuracy}%',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              color: AppColors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(FlashcardProvider flashcard, List<dynamic> deck) {
    if (flashcard.isLoading && deck.isEmpty) {
      return const SkeletonLoading(type: SkeletonType.card);
    }

    if (flashcard.errorMessage != null && deck.isEmpty) {
      return ErrorStateWidget(
        message: flashcard.errorMessage!,
        onRetry: () => flashcard.loadDeck(),
      );
    }

    if (deck.isEmpty) {
      return const EmptyStateWidget(
        title: 'Chưa có từ vựng cho flashcard',
        subtitle: 'Thêm từ mới hoặc chọn chủ đề khác để bắt đầu ôn tập.',
        action: 'Mở danh sách từ',
        showCat: true,
      );
    }

    if (_currentIndex >= deck.length) {
      _currentIndex = 0;
    }

    final item = deck[_currentIndex];
    final cardItem = _FlashcardItem.fromDynamic(item);
    final progress = (_currentIndex + 1) / deck.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                '${_currentIndex + 1}/${deck.length}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Flashcard with swipe
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -300) {
                  if (_currentIndex < deck.length - 1) _go(1, deck.length);
                } else if (details.primaryVelocity! > 300) {
                  if (_currentIndex > 0) _go(-1, deck.length);
                }
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
                  context.go('/');
                }
              },
              child: Center(
                child: GestureDetector(
                  onTap: _toggleFlip,
                  child: SizedBox(
                    width: 380,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value * math.pi;
                        final isBack = _flipAnimation.value >= 0.5;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: isBack
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(math.pi),
                                  child: _FlashcardBack(cardItem: cardItem),
                                )
                              : _FlashcardFront(cardItem: cardItem),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Review buttons
          if (!_isAutoPlaying) ...[
            const SizedBox(height: 8),
            _buildReviewButtons(cardItem),
            const SizedBox(height: 12),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentIndex > 0 ? () => _go(-1, deck.length) : null,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                    label: const Text('Trước'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentIndex < deck.length - 1
                        ? () => _go(1, deck.length)
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    label: const Text('Sau'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewButtons(dynamic cardItem) {
    if (!_isFlipped) {
      return Center(
        child: Text(
          'Chạm vào thẻ để lật mặt',
          style: GoogleFonts.workSans(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
      );
    }

    final buttons = [
      _ReviewButtonData('😵', 'Lại quên', 0, AppColors.danger),
      _ReviewButtonData('🤔', 'Hơi khó', 2, AppColors.warning),
      _ReviewButtonData('😊', 'Nhớ rồi', 4, AppColors.blue),
      _ReviewButtonData('🔥', 'Dễ ợt', 5, AppColors.success),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isReviewing
          ? const Center(
              key: ValueKey('loading'),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Wrap(
              key: const ValueKey('review-buttons'),
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: buttons.map((b) => _buildReviewButton(cardItem, b)).toList(),
            ),
    );
  }

  Widget _buildReviewButton(dynamic item, _ReviewButtonData data) {
    return SizedBox(
      width: 90,
      child: OutlinedButton(
        onPressed: () => _handleReview(item, data.quality),
        style: OutlinedButton.styleFrom(
          foregroundColor: data.color,
          side: BorderSide(color: data.color.withValues(alpha: 0.5)),
          backgroundColor: data.color.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              data.label,
              style: GoogleFonts.workSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review button data class ───────────────────────────────

class _ReviewButtonData {
  final String emoji;
  final String label;
  final int quality;
  final Color color;

  const _ReviewButtonData(this.emoji, this.label, this.quality, this.color);
}

// ─── Flashcard item model ─────────────────────────────────

class _FlashcardItem {
  final String? id;
  final String word;
  final String meaning;
  final String? example;
  final String topic;

  _FlashcardItem({
    this.id,
    required this.word,
    required this.meaning,
    this.example,
    this.topic = 'general',
  });

  factory _FlashcardItem.fromDynamic(dynamic item) {
    if (item is Vocabulary) {
      return _FlashcardItem(
        id: item.id,
        word: item.word,
        meaning: item.meaning,
        example: item.example,
        topic: item.topic,
      );
    }
    final word = item.word as String;
    final meaning = item.meaning as String;
    final example = item.example as String?;
    final topic = item.topic as String? ?? 'general';
    return _FlashcardItem(word: word, meaning: meaning, example: example, topic: topic);
  }
}

// ─── Card Front ───────────────────────────────────────────

class _FlashcardFront extends StatelessWidget {
  final _FlashcardItem cardItem;

  const _FlashcardFront({required this.cardItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              cardItem.topic,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  cardItem.word,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.workSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SpeakerButton(
                text: cardItem.word,
                size: 32,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Lật thẻ để xem nghĩa và ví dụ',
            style: GoogleFonts.workSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Back ────────────────────────────────────────────

class _FlashcardBack extends StatelessWidget {
  final _FlashcardItem cardItem;

  const _FlashcardBack({required this.cardItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardItem.meaning,
            style: GoogleFonts.workSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            cardItem.example?.isNotEmpty == true
                ? cardItem.example!
                : 'Chưa có câu ví dụ cho từ này.',
            style: GoogleFonts.workSans(
              fontSize: 15,
              height: 1.5,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
