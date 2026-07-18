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
import '../services/tts_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/flashcard_topic_sheet.dart';
import '../widgets/speaker_button.dart';

// ─── Entry animation (spring cubic) ────────────────────
class _EntryAnimation extends StatefulWidget {
  final Widget child;
  const _EntryAnimation({required this.child});

  @override
  State<_EntryAnimation> createState() => _EntryAnimationState();
}

class _EntryAnimationState extends State<_EntryAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Cubic(0.34, 1.56, 0.64, 1),
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Double-bezel card wrapper ─────────────────────────
class _DoubleBezel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const _DoubleBezel({
    required this.child,
    this.padding,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final innerPad = padding ?? const EdgeInsets.all(24);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.luxuryBorder, width: 1.2),
      ),
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - 2),
          border: Border.all(
            color: AppColors.luxuryBorder.withValues(alpha: 0.45),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 3),
          child: Padding(padding: innerPad, child: child),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// FlashcardScreen
// ════════════════════════════════════════════════════════

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
  Timer? _sessionTimer;
  int _secondsRemaining = 600;
  final TextEditingController _typingController = TextEditingController();
  bool _typingChecked = false;

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
      curve: const Cubic(0.42, 0.0, 0.58, 1.0),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FlashcardProvider>();
      final isStarterSession =
          GoRouterState.of(context).uri.queryParameters['starter'] == 'true';
      if (isStarterSession) {
        provider.configureSession(
          studyMode: FlashcardStudyMode.mixed,
          cardMode: FlashcardCardMode.random,
          sessionLimit: 5,
          sessionMinutes: 5,
        );
      }
      provider.loadDeck().then((_) {
        if (mounted) _startSessionTimer(provider.sessionMinutes);
      });
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _sessionTimer?.cancel();
    _typingController.dispose();
    TtsService.stop();
    _flipController.dispose();
    super.dispose();
  }

  void _startSessionTimer(int minutes) {
    _sessionTimer?.cancel();
    setState(() => _secondsRemaining = minutes * 60);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _showSessionSummary();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
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
      if (quality >= 4 && cardItem.reviewCount == 4 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tem thành thạo đã được đóng dấu hoàn chỉnh!'),
          ),
        );
      }
      final deck = flashcard.data;
      if (_currentIndex < deck.length - 1) {
        _go(1, deck.length);
      } else {
        await _showSessionSummary();
      }
    }
  }

  void _resetCard() {
    _isFlipped = false;
    _typingChecked = false;
    _typingController.clear();
    _flipController.reverse();
    final provider = context.read<FlashcardProvider>();
    final deck = provider.data;
    if (provider.cardMode == FlashcardCardMode.listening &&
        deck.isNotEmpty &&
        _currentIndex < deck.length) {
      TtsService.speak(_FlashcardItem.fromDynamic(deck[_currentIndex]).word);
    }
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
      if (!mounted) {
        timer.cancel();
        return;
      }
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

  Future<void> _openSessionSetup() async {
    final provider = context.read<FlashcardProvider>();
    var studyMode = provider.studyMode;
    var cardMode = provider.cardMode;
    var limit = provider.sessionLimit;
    var minutes = provider.sessionMinutes;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.84,
          ),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          decoration: const BoxDecoration(
            color: AppColors.luxurySurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.luxuryBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Chuẩn bị phiên học',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryEspresso,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Gợi ý: 70% từ cần ôn + 30% từ mới để nhớ lâu hơn.',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.luxuryText,
                ),
              ),
              const SizedBox(height: 20),
              _setupLabel('MỤC TIÊU'),
              Wrap(
                spacing: 8,
                children: [5, 10, 20, 30].map((value) {
                  return ChoiceChip(
                    label: Text('$value thẻ'),
                    selected: limit == value,
                    onSelected: (_) => setSheetState(() => limit = value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [5, 10, 15, 20].map((value) {
                  return ChoiceChip(
                    label: Text('$value phút'),
                    selected: minutes == value,
                    onSelected: (_) => setSheetState(() => minutes = value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _setupLabel('BỘ THẺ'),
              DropdownButtonFormField<FlashcardStudyMode>(
                initialValue: studyMode,
                items: const [
                  DropdownMenuItem(
                    value: FlashcardStudyMode.mixed,
                    child: Text('Trộn thông minh 70/30'),
                  ),
                  DropdownMenuItem(
                    value: FlashcardStudyMode.due,
                    child: Text('Chỉ thẻ đến hạn'),
                  ),
                  DropdownMenuItem(
                    value: FlashcardStudyMode.newWords,
                    child: Text('Chỉ từ mới'),
                  ),
                  DropdownMenuItem(
                    value: FlashcardStudyMode.weak,
                    child: Text('Từ hay quên'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setSheetState(() => studyMode = value);
                },
              ),
              const SizedBox(height: 18),
              _setupLabel('CÁCH GỢI NHỚ'),
              DropdownButtonFormField<FlashcardCardMode>(
                initialValue: cardMode,
                items: const [
                  DropdownMenuItem(
                    value: FlashcardCardMode.random,
                    child: Text('Đổi chiều ngẫu nhiên'),
                  ),
                  DropdownMenuItem(
                    value: FlashcardCardMode.wordFirst,
                    child: Text('Từ → nghĩa'),
                  ),
                  DropdownMenuItem(
                    value: FlashcardCardMode.meaningFirst,
                    child: Text('Nghĩa → từ'),
                  ),
                  DropdownMenuItem(
                    value: FlashcardCardMode.listening,
                    child: Text('Nghe → đoán từ'),
                  ),
                  DropdownMenuItem(
                    value: FlashcardCardMode.typing,
                    child: Text('Gõ để nhớ'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setSheetState(() => cardMode = value);
                },
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.local_post_office_rounded),
                label: const Text('Bắt đầu phiên'),
              ),
            ],
          ),
        ),
      ),
    );
    if (applied != true || !mounted) return;
    provider.configureSession(
      studyMode: studyMode,
      cardMode: cardMode,
      sessionLimit: limit,
      sessionMinutes: minutes,
    );
    setState(() {
      _currentIndex = 0;
      _resetCard();
    });
    _startSessionTimer(minutes);
  }

  Widget _setupLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: GoogleFonts.ibmPlexMono(
        fontSize: 9,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.luxuryBrown,
      ),
    ),
  );

  Future<void> _showSessionSummary() async {
    if (!mounted) return;
    _sessionTimer?.cancel();
    final provider = context.read<FlashcardProvider>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.verified_rounded,
          color: AppColors.luxuryGreen,
          size: 42,
        ),
        title: const Text('Đã đóng dấu phiên học'),
        content: Text(
          '${provider.sessionReviewed} thẻ đã ôn · '
          '${provider.sessionMastered} thẻ nhớ tốt · '
          '${provider.sessionNeedsReview} thẻ sẽ quay lại sớm.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/');
            },
            child: const Text('Về trang chủ'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await provider.loadDeck();
              if (!mounted) return;
              setState(() {
                _currentIndex = 0;
                _resetCard();
              });
              _startSessionTimer(provider.sessionMinutes);
            },
            child: const Text('Học phiên mới'),
          ),
        ],
      ),
    );
  }

  Future<void> _openNoteSheet(_FlashcardItem item) async {
    if (item.id == null) return;
    final controller = TextEditingController(text: item.personalNote);
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          22 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mẹo nhớ riêng · ${item.word}',
              style: GoogleFonts.playfairDisplay(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Ghi lại liên tưởng hoặc câu giúp bạn nhớ từ này.'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: hotel giống “hô-ten”...',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext, controller.text),
                child: const Text('Lưu ghi chú'),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (note == null || !mounted) return;
    final success = await context.read<FlashcardProvider>().updateNote(
      item.id,
      note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã lưu mẹo nhớ riêng.' : 'Không thể lưu ghi chú.',
        ),
      ),
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
        const SingleActivator(LogicalKeyboardKey.digit1): () {
          if (deck.isNotEmpty) _handleReview(deck[_currentIndex], 1);
        },
        const SingleActivator(LogicalKeyboardKey.digit2): () {
          if (deck.isNotEmpty) _handleReview(deck[_currentIndex], 3);
        },
        const SingleActivator(LogicalKeyboardKey.digit3): () {
          if (deck.isNotEmpty) _handleReview(deck[_currentIndex], 5);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.luxuryBg,
          appBar: AppBar(
            title: Text(
              flashcard.selectedTopic == 'all'
                  ? 'Tất cả chủ đề'
                  : flashcardTopicLabel(flashcard.selectedTopic),
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: AppColors.luxuryEspresso,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.luxuryEspresso,
              ),
              onPressed: () => context.go('/'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                color: AppColors.luxuryBrown,
                onPressed: _openSessionSetup,
                tooltip: 'Tùy chỉnh phiên học',
              ),
              IconButton(
                icon: const Icon(Icons.shuffle),
                color: flashcard.shuffleEnabled
                    ? AppColors.luxuryGold
                    : AppColors.luxuryTextHint,
                onPressed: () => flashcard.toggleShuffle(),
                tooltip: 'Xáo trộn',
              ),
              IconButton(
                icon: Icon(
                  _isAutoPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                color: _isAutoPlaying
                    ? AppColors.luxuryGold
                    : AppColors.luxuryTextHint,
                onPressed: deck.isEmpty
                    ? null
                    : () => _toggleAutoPlay(deck.length),
                tooltip: _isAutoPlaying ? 'Dừng tự động' : 'Tự động lật',
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
          body: SafeArea(
            child: _EntryAnimation(
              child: Column(
                children: [
                  _buildDueBanner(flashcard),
                  _buildTopicBar(flashcard, deck.length),
                  _buildSessionStats(flashcard),
                  Expanded(child: _buildBody(flashcard, deck)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueBanner(FlashcardProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: provider.dueCount > 0
            ? AppColors.luxuryGold.withValues(alpha: 0.10)
            : AppColors.luxuryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: provider.dueCount > 0
              ? AppColors.luxuryGold.withValues(alpha: 0.28)
              : AppColors.luxuryGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            provider.dueCount > 0
                ? Icons.schedule_rounded
                : Icons.task_alt_rounded,
            color: provider.dueCount > 0
                ? AppColors.luxuryGold
                : AppColors.luxuryGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              provider.dueCount > 0
                  ? 'Hôm nay có ${provider.dueCount} thẻ cần ôn'
                  : 'Bạn đã hoàn thành các thẻ đến hạn hôm nay',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.luxuryEspresso,
              ),
            ),
          ),
          TextButton(
            onPressed: _openSessionSetup,
            child: const Text('Thiết lập'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicBar(FlashcardProvider flashcard, int deckLength) {
    final topic = flashcard.selectedTopic;
    final label = topic == 'all' ? 'Tất cả chủ đề' : flashcardTopicLabel(topic);
    final totalItems = flashcard.topicItemCount.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final isAll = topic == 'all';
    final displayCount = isAll
        ? totalItems
        : (flashcard.topicItemCount[topic] ?? deckLength);
    final mastery = flashcard.getTopicMastery(topic);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: true,
      label: 'Chọn chủ đề: $label, $displayCount thẻ',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: _openTopicSheet,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: mastery,
                    strokeWidth: 2.5,
                    backgroundColor: AppColors.luxuryBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      mastery < 0.33
                          ? AppColors.luxuryDanger
                          : mastery < 0.66
                          ? AppColors.luxuryGold
                          : AppColors.luxuryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.luxuryEspresso,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.luxuryText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$displayCount thẻ',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.luxuryTextHint,
                  ),
                ),
              ],
            ),
          ),
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
        color: AppColors.luxuryBrown.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('\u{1F4CA}', style: GoogleFonts.nunito(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đã ôn ${flashcard.sessionReviewed} · Nhớ tốt ${flashcard.sessionMastered}',
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: AppColors.luxuryBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '🔥 ${flashcard.combo} · ${flashcard.sessionAccuracy}%',
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppColors.luxuryBrown,
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
        subtitle: 'Thêm từ mới hoặc chọn chủ đề khác.',
        action: 'Mở danh sách từ',
        showCat: true,
      );
    }

    if (_currentIndex >= deck.length) _currentIndex = 0;

    final item = deck[_currentIndex];
    final cardItem = _FlashcardItem.fromDynamic(item);
    final progress = (_currentIndex + 1) / deck.length;
    final cardMode = flashcard.cardMode;
    final meaningFirst =
        cardMode == FlashcardCardMode.meaningFirst ||
        cardMode == FlashcardCardMode.typing ||
        (cardMode == FlashcardCardMode.random &&
            (cardItem.word.hashCode + _currentIndex).isOdd);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.luxuryBrown.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${deck.length}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.luxuryBrown,
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
                    backgroundColor: AppColors.luxuryBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.luxuryBrown,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryBrown,
                ),
              ),
              IconButton(
                icon: Icon(
                  cardItem.personalNote?.isNotEmpty == true
                      ? Icons.sticky_note_2_rounded
                      : Icons.note_add_outlined,
                  color: cardItem.personalNote?.isNotEmpty == true
                      ? AppColors.luxuryBrown
                      : AppColors.luxuryTextHint,
                  size: 20,
                ),
                onPressed: cardItem.id == null
                    ? null
                    : () => _openNoteSheet(cardItem),
                tooltip: 'Ghi chú cá nhân',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
              IconButton(
                icon: Icon(
                  cardItem.isBookmarked
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: cardItem.isBookmarked
                      ? AppColors.luxuryGold
                      : AppColors.luxuryTextHint,
                  size: 21,
                ),
                onPressed: cardItem.id == null
                    ? null
                    : () => flashcard.toggleBookmark(cardItem.id),
                tooltip: 'Đánh dấu từ khó',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34),
              ),
              IconButton(
                icon: Icon(
                  _isAutoPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.luxuryText,
                  size: 20,
                ),
                onPressed: () => _toggleAutoPlay(deck.length),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (_isFlipped && details.primaryVelocity!.abs() > 300) {
                  _handleReview(cardItem, details.primaryVelocity! < 0 ? 0 : 5);
                  return;
                }
                if (details.primaryVelocity! < -300) {
                  if (_currentIndex < deck.length - 1) _go(1, deck.length);
                } else if (details.primaryVelocity! > 300) {
                  if (_currentIndex > 0) _go(-1, deck.length);
                }
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 500) {
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
                                  transform: Matrix4.identity()
                                    ..rotateY(math.pi),
                                  child: _FlashcardBack(
                                    cardItem: cardItem,
                                    meaningFirst: meaningFirst,
                                  ),
                                )
                              : _FlashcardFront(
                                  cardItem: cardItem,
                                  mode: cardMode,
                                  meaningFirst: meaningFirst,
                                  typingController: _typingController,
                                  typingChecked: _typingChecked,
                                  onTypingCheck: () {
                                    final typed = _typingController.text
                                        .trim()
                                        .toLowerCase();
                                    final correct =
                                        typed ==
                                        cardItem.word.trim().toLowerCase();
                                    setState(() => _typingChecked = true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        duration: const Duration(seconds: 1),
                                        content: Text(
                                          correct
                                              ? 'Chính xác · con tem đã được đóng dấu!'
                                              : 'Chưa đúng · đáp án là “${cardItem.word}”.',
                                        ),
                                      ),
                                    );
                                    _toggleFlip();
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (!_isAutoPlaying) ...[
            _isFlipped
                ? _buildReviewButtons(cardItem)
                : Text(
                    'Chạm để lật thẻ',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.luxuryTextHint,
                    ),
                  ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0
                      ? () => _go(-1, deck.length)
                      : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppColors.luxuryTextHint,
                  ),
                ),
                Text(
                  'Chạm để lật',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.luxuryTextHint.withValues(alpha: 0.6),
                  ),
                ),
                IconButton(
                  onPressed: _currentIndex < deck.length - 1
                      ? () => _go(1, deck.length)
                      : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: AppColors.luxuryTextHint,
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
    final buttons = [
      _ReviewButtonData(
        '😵',
        'Quên',
        '${_nextInterval(cardItem, 0)} ngày',
        0,
        AppColors.luxuryDanger,
        AppColors.luxuryDanger.withValues(alpha: 0.08),
      ),
      _ReviewButtonData(
        '🤔',
        'Khó',
        '${_nextInterval(cardItem, 3)} ngày',
        3,
        AppColors.luxuryGold,
        AppColors.luxuryGold.withValues(alpha: 0.08),
      ),
      _ReviewButtonData(
        '😊',
        'Nhớ',
        '${_nextInterval(cardItem, 4)} ngày',
        4,
        AppColors.luxuryGreen,
        AppColors.luxuryGreen.withValues(alpha: 0.08),
      ),
      _ReviewButtonData(
        '🔥',
        'Dễ',
        '${_nextInterval(cardItem, 5)} ngày',
        5,
        AppColors.luxuryBrown,
        AppColors.luxuryBrown.withValues(alpha: 0.08),
      ),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: const Cubic(0.34, 1.56, 0.64, 1),
      child: _isReviewing
          ? const Center(
              key: ValueKey('loading'),
              child: SizedBox(
                width: 20,
                height: 20,
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
              children: buttons
                  .map((b) => _buildReviewButton(cardItem, b))
                  .toList(),
            ),
    );
  }

  int _nextInterval(_FlashcardItem item, int quality) {
    if (quality < 3 || item.reviewCount == 0) return 1;
    if (item.reviewCount == 1) return 6;
    final nextEase = math.max(
      1.3,
      item.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)),
    );
    return math.max(1, (math.max(item.reviewInterval, 6) * nextEase).round());
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
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: data.color,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                data.interval,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 8,
                  color: data.color.withValues(alpha: 0.75),
                ),
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
  final String interval;
  final int quality;
  final Color color;
  final Color bgColor;
  const _ReviewButtonData(
    this.emoji,
    this.label,
    this.interval,
    this.quality,
    this.color,
    this.bgColor,
  );
}

class _FlashcardItem {
  final String? id;
  final String word;
  final String meaning;
  final String? example;
  final String? pronunciation;
  final String? personalNote;
  final String topic;
  final int reviewCount;
  final int reviewInterval;
  final double easeFactor;
  final int timesCorrect;
  final int timesWrong;
  final bool isBookmarked;

  _FlashcardItem({
    this.id,
    required this.word,
    required this.meaning,
    this.example,
    this.pronunciation,
    this.personalNote,
    this.topic = 'general',
    this.reviewCount = 0,
    this.reviewInterval = 0,
    this.easeFactor = 2.5,
    this.timesCorrect = 0,
    this.timesWrong = 0,
    this.isBookmarked = false,
  });

  factory _FlashcardItem.fromDynamic(dynamic item) {
    if (item is Vocabulary) {
      return _FlashcardItem(
        id: item.id,
        word: item.word,
        meaning: item.meaning,
        example: item.example,
        pronunciation: item.pronunciation,
        personalNote: item.personalNote,
        topic: item.topic,
        reviewCount: item.reviewCount,
        reviewInterval: item.reviewInterval,
        easeFactor: item.easeFactor,
        timesCorrect: item.timesCorrect,
        timesWrong: item.timesWrong,
        isBookmarked: item.isBookmarked,
      );
    }
    return _FlashcardItem(
      word: item.word as String,
      meaning: item.meaning as String,
      example: item.example as String?,
      pronunciation: item.pronunciation as String?,
      topic: item.topic as String? ?? 'general',
    );
  }
}

// ─── Front: word + speaker ────────────────────────────
class _FlashcardFront extends StatelessWidget {
  final _FlashcardItem cardItem;
  final FlashcardCardMode mode;
  final bool meaningFirst;
  final TextEditingController typingController;
  final bool typingChecked;
  final VoidCallback onTypingCheck;

  const _FlashcardFront({
    required this.cardItem,
    required this.mode,
    required this.meaningFirst,
    required this.typingController,
    required this.typingChecked,
    required this.onTypingCheck,
  });

  @override
  Widget build(BuildContext context) {
    return _DoubleBezel(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.luxuryBrown.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              cardItem.topic,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.luxuryBrown,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (mode == FlashcardCardMode.listening) ...[
            const Icon(
              Icons.graphic_eq_rounded,
              size: 46,
              color: AppColors.luxuryBrown,
            ),
            const SizedBox(height: 8),
            Text(
              'Nghe và đoán từ',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
            const SizedBox(height: 14),
            SpeakerButton(
              text: cardItem.word,
              size: 42,
              color: AppColors.luxuryBrown,
            ),
          ] else ...[
            Text(
              meaningFirst ? cardItem.meaning : cardItem.word,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
            if (!meaningFirst && mode != FlashcardCardMode.typing) ...[
              const SizedBox(height: 14),
              Text(
                cardItem.pronunciation ?? '',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  color: AppColors.luxuryText,
                ),
              ),
              SpeakerButton(
                text: cardItem.word,
                size: 32,
                color: AppColors.luxuryBrown,
              ),
            ],
          ],
          if (mode == FlashcardCardMode.typing) ...[
            const SizedBox(height: 16),
            TextField(
              controller: typingController,
              textAlign: TextAlign.center,
              enabled: !typingChecked,
              onSubmitted: (_) => onTypingCheck(),
              decoration: const InputDecoration(
                hintText: 'Gõ từ tiếng Anh...',
                prefixIcon: Icon(Icons.keyboard_rounded),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: typingChecked ? null : onTypingCheck,
              child: const Text('Kiểm tra'),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Chạm để lật con tem',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.luxuryTextHint,
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
  final bool meaningFirst;
  const _FlashcardBack({required this.cardItem, required this.meaningFirst});

  @override
  Widget build(BuildContext context) {
    return _DoubleBezel(
      borderRadius: 20,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            meaningFirst ? cardItem.word : cardItem.meaning,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryEspresso,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cardItem.pronunciation?.isNotEmpty == true
                ? cardItem.pronunciation!
                : '/${cardItem.word.toLowerCase()}/',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.luxuryText,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Divider(height: 1, color: AppColors.luxuryBorder),
          ),
          _HighlightedExample(cardItem: cardItem),
          if (cardItem.personalNote?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              '✎ ${cardItem.personalNote}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryBrown,
              ),
            ),
          ],
          if (cardItem.timesWrong > cardItem.timesCorrect) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.luxuryDanger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Từ này bạn hay quên · ưu tiên ôn lại',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryDanger,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightedExample extends StatelessWidget {
  final _FlashcardItem cardItem;

  const _HighlightedExample({required this.cardItem});

  @override
  Widget build(BuildContext context) {
    final example = cardItem.example;
    if (example == null || example.isEmpty) {
      return Text(
        'Chưa có câu ví dụ.',
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: AppColors.luxuryTextHint,
        ),
      );
    }
    final lower = example.toLowerCase();
    final word = cardItem.word.toLowerCase();
    final index = lower.indexOf(word);
    final baseStyle = GoogleFonts.nunito(
      fontSize: 14,
      fontStyle: FontStyle.italic,
      color: AppColors.luxuryText,
      height: 1.5,
    );
    if (index < 0) {
      return Text('“$example”', textAlign: TextAlign.center, style: baseStyle);
    }
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: '“${example.substring(0, index)}'),
          TextSpan(
            text: example.substring(index, index + cardItem.word.length),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.luxuryBrown,
              backgroundColor: AppColors.luxuryGold.withValues(alpha: 0.16),
            ),
          ),
          TextSpan(text: '${example.substring(index + cardItem.word.length)}”'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
