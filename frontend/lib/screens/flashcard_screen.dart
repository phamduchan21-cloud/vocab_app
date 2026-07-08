import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    setState(() => _isAutoPlaying = !_isAutoPlaying);
    if (_isAutoPlaying) {
      _startAutoPlay(deckLength);
    } else {
      _autoPlayTimer?.cancel();
    }
  }

  void _startAutoPlay(int deckLength) {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (!_isFlipped) {
        _toggleFlip();
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (_currentIndex > 0) _go(-1, deck.length);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (_currentIndex < deck.length - 1) _go(1, deck.length);
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): _toggleFlip,
        const SingleActivator(LogicalKeyboardKey.arrowDown): _toggleFlip,
        const SingleActivator(LogicalKeyboardKey.space): _toggleFlip,
        const SingleActivator(LogicalKeyboardKey.digit1): () => _handleReview(deck[_currentIndex], 1),
        const SingleActivator(LogicalKeyboardKey.digit2): () => _handleReview(deck[_currentIndex], 3),
        const SingleActivator(LogicalKeyboardKey.digit3): () => _handleReview(deck[_currentIndex], 5),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          flashcard.selectedTopic == 'all'
              ? 'Tất cả chủ đề'
              : flashcard.selectedTopic,
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: flashcard.shuffleEnabled ? AppColors.blue : AppColors.inkSoft,
            ),
            onPressed: () => flashcard.toggleShuffle(),
            tooltip: 'Xáo trộn',
          ),
          IconButton(
            icon: Icon(
              _isAutoPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
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
            // Topic bar + session stats
            _buildTopicBar(flashcard, deck.length),
            _buildSessionStats(flashcard),
            // Flashcard body
            Expanded(
              child: _buildBody(flashcard, deck),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            // Mastery ring
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                value: mastery,
                strokeWidth: 2.5,
                backgroundColor: AppColors.surfaceContainerHighest,
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
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: AppColors.inkSoft, size: 20),
            const SizedBox(width: 8),
            Text(
              '$displayCount thẻ',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45),
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
              fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 14, color: AppColors.blue.withValues(alpha: 0.2)),
          const SizedBox(width: 12),
          Text(
            'Chính xác: ${flashcard.sessionAccuracy}%',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600,
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
        subtitle: 'Thêm từ mới hoặc chọn chủ đề khác.',
        action: 'Mở danh sách từ',
        showCat: true,
      );
    }

    if (_currentIndex >= deck.length) _currentIndex = 0;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${deck.length}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(
                  _isAutoPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.inkSoft, size: 20,
                ),
                onPressed: () => _toggleAutoPlay(deck.length),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Flashcard — Stitch 4:3 aspect ratio with 3D flip
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
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
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

          const SizedBox(height: 16),

          // Review buttons — Stitch grid style
          if (!_isAutoPlaying) ...[
            _isFlipped
                ? _buildReviewButtons(cardItem)
                : Text(
                    'Chạm để lật thẻ',
                    style: GoogleFonts.workSans(
                      fontSize: 12, color: AppColors.textHint,
                    ),
                  ),
            const SizedBox(height: 12),

            // Navigation arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? () => _go(-1, deck.length) : null,
                  icon: Icon(Icons.chevron_left, color: AppColors.inkSoft),
                ),
                Text(
                  'Chạm để lật',
                  style: GoogleFonts.workSans(
                    fontSize: 12, color: AppColors.inkSoft.withValues(alpha: 0.6),
                  ),
                ),
                IconButton(
                  onPressed: _currentIndex < deck.length - 1 ? () => _go(1, deck.length) : null,
                  icon: Icon(Icons.chevron_right, color: AppColors.inkSoft),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewButtons(dynamic cardItem) {
    final buttons = [
      _ReviewButtonData('😵', 'Lại quên', 0, AppColors.danger, AppColors.dangerBg),
      _ReviewButtonData('🤔', 'Hơi khó', 2, AppColors.warning, AppColors.warningBg),
      _ReviewButtonData('😊', 'Nhớ rồi', 4, AppColors.success, AppColors.successBg),
      _ReviewButtonData('🔥', 'Dễ ợt', 5, AppColors.blue, AppColors.blueBg),
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
          : GridView.count(
              key: const ValueKey('review-buttons'),
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: buttons.map((b) => _buildReviewButton(cardItem, b)).toList(),
            ),
    );
  }

  Widget _buildReviewButton(dynamic item, _ReviewButtonData data) {
    return Material(
      color: data.bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _handleReview(item, data.quality),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: data.color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: GoogleFonts.workSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: data.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewButtonData {
  final String emoji;
  final String label;
  final int quality;
  final Color color;
  final Color bgColor;
  const _ReviewButtonData(this.emoji, this.label, this.quality, this.color, this.bgColor);
}

class _FlashcardItem {
  final String? id;
  final String word;
  final String meaning;
  final String? example;
  final String topic;

  _FlashcardItem({this.id, required this.word, required this.meaning, this.example, this.topic = 'general'});

  factory _FlashcardItem.fromDynamic(dynamic item) {
    if (item is Vocabulary) {
      return _FlashcardItem(
        id: item.id, word: item.word, meaning: item.meaning,
        example: item.example, topic: item.topic,
      );
    }
    return _FlashcardItem(
      word: item.word as String, meaning: item.meaning as String,
      example: item.example as String?, topic: item.topic as String? ?? 'general',
    );
  }
}

// ─── Front: word + speaker ────────────────────────────
class _FlashcardFront extends StatelessWidget {
  final _FlashcardItem cardItem;
  const _FlashcardFront({required this.cardItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHighest),
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
          // Topic badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              cardItem.topic,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            cardItem.word,
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(32),
            ),
            child: SpeakerButton(text: cardItem.word, size: 24, color: AppColors.blue),
          ),
          const SizedBox(height: 20),
          Text(
            'Chạm để lật thẻ',
            style: GoogleFonts.workSans(
              fontSize: 12, color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Back: meaning + example ──────────────────────────
class _FlashcardBack extends StatelessWidget {
  final _FlashcardItem cardItem;
  const _FlashcardBack({required this.cardItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cardItem.meaning,
                textAlign: TextAlign.center,
                style: GoogleFonts.workSans(
                  fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '/${cardItem.word.toLowerCase()}/',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 13, color: AppColors.onSurfaceVariant,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                child: Divider(height: 1),
              ),
              Text(
                cardItem.example?.isNotEmpty == true
                    ? '"${cardItem.example!}"'
                    : 'Chưa có câu ví dụ.',
                textAlign: TextAlign.center,
                style: GoogleFonts.workSans(
                  fontSize: 14, fontStyle: FontStyle.italic,
                  color: AppColors.inkSoft, height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
