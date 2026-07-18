import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';

// ════════════════════════════════════════════════════════
// BOOKMARK SCREEN — Editorial Luxury
// ════════════════════════════════════════════════════════

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
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final innerPad = padding ?? const EdgeInsets.all(14);
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

// ─── Luxury pill button with trailing icon island ──────
class _LuxuryPill extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;

  const _LuxuryPill({
    required this.label,
    this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.fromLTRB(24, 10, 10, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

enum _WordTag { new_, learning, mastered }

class _BookmarkWord {
  final String id, word, ipa, meaning, tagLabel;
  final _WordTag tag;
  final bool isBookmarked;
  const _BookmarkWord({
    required this.id,
    required this.word,
    required this.ipa,
    required this.meaning,
    required this.tagLabel,
    required this.tag,
    required this.isBookmarked,
  });

  factory _BookmarkWord.fromVocabulary(Vocabulary v) {
    _WordTag tag;
    String tagLabel;
    if (v.reviewCount == 0) {
      tag = _WordTag.new_;
      tagLabel = 'Mới';
    } else if (v.reviewCount < 5) {
      tag = _WordTag.learning;
      tagLabel = 'Đang học';
    } else {
      tag = _WordTag.mastered;
      tagLabel = 'Đã thuộc';
    }
    return _BookmarkWord(
      id: v.id,
      word: v.word,
      ipa: v.pronunciation ?? '',
      meaning: v.meaning,
      tagLabel: tagLabel,
      tag: tag,
      isBookmarked: v.isBookmarked,
    );
  }
}

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _tabLabels = [
    'Tất cả',
    'Mới',
    'Đang học',
    'Đã thuộc',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VocabularyProvider>();
      if (provider.items.isEmpty) provider.fetchAll(limit: 200);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _WordTag? get _selectedTag {
    switch (_selectedTabIndex) {
      case 1:
        return _WordTag.new_;
      case 2:
        return _WordTag.learning;
      case 3:
        return _WordTag.mastered;
      default:
        return null;
    }
  }

  List<_BookmarkWord> get _filteredWords {
    final provider = context.read<VocabularyProvider>();
    return provider.bookmarked
        .map((v) => _BookmarkWord.fromVocabulary(v))
        .where((w) {
          if (_selectedTag != null && w.tag != _selectedTag) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!w.word.toLowerCase().contains(q) &&
                !w.meaning.toLowerCase().contains(q)) {
              return false;
            }
          }
          return true;
        })
        .toList();
  }

  int _countForTag(_WordTag? tag) {
    final provider = context.read<VocabularyProvider>();
    return provider.bookmarked.where((v) {
      final count = v.reviewCount;
      if (tag == null) return true;
      if (tag == _WordTag.new_) return count == 0;
      if (tag == _WordTag.learning) return count > 0 && count < 5;
      if (tag == _WordTag.mastered) return count >= 5;
      return true;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VocabularyProvider>();
    final isLoading = provider.isLoading && provider.items.isEmpty;
    final hasError = provider.errorMessage != null && provider.items.isEmpty;
    final isEmptyState =
        !provider.isLoading &&
        provider.errorMessage == null &&
        provider.items.isEmpty;
    // ponytail: bookmarkedCount unused, removed
    final screenW = MediaQuery.of(context).size.width;
    final isNarrow = screenW < 400;
    final hPad = isNarrow ? 20.0 : 44.0;

    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      body: SafeArea(
        child: _EntryAnimation(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Từ đã lưu',
                                style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                  color: AppColors.luxuryEspresso,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.luxuryBrown.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${provider.bookmarked.length}',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.luxuryBrown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Từ bạn đã đánh dấu để ôn lại sau',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppColors.luxuryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _LuxuryPill(
                      label: 'Ôn tập',
                      color: AppColors.luxuryBrown,
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => context.go('/flashcard'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ─── Search ───────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.luxuryEspresso,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.luxuryTextHint,
                      ),
                      hintText: 'Tìm từ đã lưu...',
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.luxuryTextHint,
                      ),
                      filled: true,
                      fillColor: AppColors.luxurySurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.luxuryBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.luxuryBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.luxuryBrown,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Tabs ─────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_tabLabels.length, (i) {
                      final isActive = i == _selectedTabIndex;
                      final tag = switch (i) {
                        1 => _WordTag.new_,
                        2 => _WordTag.learning,
                        3 => _WordTag.mastered,
                        _ => null,
                      };
                      final count = _countForTag(tag);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.luxuryEspresso
                                  : AppColors.luxurySurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? Colors.transparent
                                    : AppColors.luxuryBorder,
                              ),
                            ),
                            child: Text(
                              '${_tabLabels[i]} . $count',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? AppColors.luxurySurface
                                    : AppColors.luxuryText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Body ─────────────────────────────────
              Expanded(
                child: _buildBody(
                  isLoading,
                  hasError,
                  isEmptyState,
                  provider,
                  hPad,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    bool isLoading,
    bool hasError,
    bool isEmptyState,
    VocabularyProvider provider,
    double hPad,
  ) {
    if (isLoading) {
      return const SkeletonLoading(type: SkeletonType.grid, count: 8);
    }
    if (hasError) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchAll(limit: 200),
      );
    }
    if (isEmptyState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.luxuryBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 36,
                color: AppColors.luxuryBrown,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có từ vựng nào',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thêm từ mới để bắt đầu học tập nhé!',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.luxuryText,
              ),
            ),
            const SizedBox(height: 20),
            _LuxuryPill(
              label: 'Thêm từ mới',
              color: AppColors.luxuryBrown,
              icon: Icons.add_rounded,
              onPressed: () => context.push('/vocabulary/new'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredWords;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.bookmark_border,
              size: 56,
              color: AppColors.luxuryTextHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Không tìm thấy từ nào'
                  : 'Chưa có từ nào trong mục này',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.luxuryTextHint,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Text(
                  'Xóa bộ lọc',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.luxuryBrown,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildStampGrid(filtered, constraints.maxWidth, provider);
        },
      ),
    );
  }

  Widget _buildStampGrid(
    List<_BookmarkWord> words,
    double maxWidth,
    VocabularyProvider provider,
  ) {
    const spacing = 14.0;
    final crossAxisCount = maxWidth < 480
        ? 1
        : maxWidth < 760
        ? 2
        : maxWidth < 1100
        ? 3
        : 4;
    final itemWidth =
        (maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
    final rows = <Widget>[];
    for (var i = 0; i < words.length; i += crossAxisCount) {
      final rowEnd = (i + crossAxisCount).clamp(0, words.length);
      final rowItems = <Widget>[];
      for (var j = i; j < rowEnd; j++) {
        final word = words[j];
        rowItems.add(
          SizedBox(
            width: itemWidth,
            child: _WordStamp(
              word: word,
              onStarToggle: () {
                final vocab = provider.items.firstWhere(
                  (v) => v.id == word.id,
                  orElse: () => provider.items.first,
                );
                provider.toggleBookmark(vocab);
              },
            ),
          ),
        );
      }
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Row(
            children: List.generate(rowItems.length, (k) {
              return Padding(
                padding: EdgeInsets.only(
                  left: k == 0 ? 0 : spacing / 2,
                  right: k == rowItems.length - 1 ? 0 : spacing / 2,
                ),
                child: rowItems[k],
              );
            }),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

// ════════════════════════════════════════════════════════
// WORD STAMP — luxury style
// ════════════════════════════════════════════════════════

class _WordStamp extends StatelessWidget {
  final _BookmarkWord word;
  final VoidCallback onStarToggle;

  const _WordStamp({required this.word, required this.onStarToggle});

  @override
  Widget build(BuildContext context) {
    Color tagBg, tagFg, tagBorder;
    switch (word.tag) {
      case _WordTag.new_:
        tagBg = AppColors.luxuryGold.withValues(alpha: 0.08);
        tagFg = AppColors.luxuryGold;
        tagBorder = AppColors.luxuryGold.withValues(alpha: 0.20);
      case _WordTag.learning:
        tagBg = AppColors.luxuryBrown.withValues(alpha: 0.08);
        tagFg = AppColors.luxuryBrown;
        tagBorder = AppColors.luxuryBrown.withValues(alpha: 0.20);
      case _WordTag.mastered:
        tagBg = AppColors.luxuryGreen.withValues(alpha: 0.08);
        tagFg = AppColors.luxuryGreen;
        tagBorder = AppColors.luxuryGreen.withValues(alpha: 0.20);
    }

    final accentColor = word.isBookmarked
        ? AppColors.luxuryBrown
        : AppColors.luxuryEspresso;

    return _DoubleBezel(
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word.word,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 3),
              if (word.ipa.isNotEmpty)
                Text(
                  word.ipa,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.luxuryBrown.withValues(alpha: 0.7),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                word.meaning,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.luxuryText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tagBorder),
                ),
                child: Text(
                  word.tagLabel.toUpperCase(),
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: tagFg,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -2,
            right: -2,
            child: GestureDetector(
              onTap: onStarToggle,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: word.isBookmarked
                      ? AppColors.luxuryGold.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  word.isBookmarked ? Icons.star : Icons.star_border,
                  size: 18,
                  color: word.isBookmarked
                      ? AppColors.luxuryGold
                      : AppColors.luxuryTextHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
