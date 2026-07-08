import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';

enum _WordTag { new_, learning, mastered }

class _BookmarkWord {
  final String id, word, ipa, meaning, tagLabel;
  final _WordTag tag;
  const _BookmarkWord({
    required this.id, required this.word, required this.ipa,
    required this.meaning, required this.tagLabel, required this.tag,
  });

  factory _BookmarkWord.fromVocabulary(Vocabulary v) {
    _WordTag tag;
    String tagLabel;
    if (v.reviewCount == 0) {
      tag = _WordTag.new_; tagLabel = 'Mới';
    } else if (v.reviewCount < 5) {
      tag = _WordTag.learning; tagLabel = 'Đang học';
    } else {
      tag = _WordTag.mastered; tagLabel = 'Đã thuộc';
    }
    return _BookmarkWord(
      id: v.id, word: v.word, ipa: v.pronunciation ?? '',
      meaning: v.meaning, tagLabel: tagLabel, tag: tag,
    );
  }
}

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final Set<String> _bookmarkedIds = {};
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _tabLabels = ['Tất cả', 'Mới', 'Đang học', 'Đã thuộc'];

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
      case 1: return _WordTag.new_;
      case 2: return _WordTag.learning;
      case 3: return _WordTag.mastered;
      default: return null;
    }
  }

  List<_BookmarkWord> get _filteredWords {
    final provider = context.read<VocabularyProvider>();
    return provider.items
        .map((v) => _BookmarkWord.fromVocabulary(v))
        .where((w) {
          if (_selectedTag != null && w.tag != _selectedTag) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!w.word.toLowerCase().contains(q) && !w.meaning.toLowerCase().contains(q)) return false;
          }
          return true;
        })
        .toList();
  }

  int _countForTag(_WordTag? tag) {
    final provider = context.read<VocabularyProvider>();
    return provider.items.where((v) {
      final count = v.reviewCount;
      if (tag == null) return true;
      if (tag == _WordTag.new_) return count == 0;
      if (tag == _WordTag.learning) return count > 0 && count < 5;
      if (tag == _WordTag.mastered) return count >= 5;
      return true;
    }).length;
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (_bookmarkedIds.contains(id)) { _bookmarkedIds.remove(id); } else { _bookmarkedIds.add(id); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VocabularyProvider>();
    final isLoading = provider.isLoading && provider.items.isEmpty;
    final hasError = provider.errorMessage != null && provider.items.isEmpty;
    final isEmptyState = !provider.isLoading && provider.errorMessage == null && provider.items.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top bar
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width < 400 ? 20 : 44,
              36,
              MediaQuery.of(context).size.width < 400 ? 20 : 44,
              0,
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Từ đã lưu', style: GoogleFonts.workSans(fontWeight: FontWeight.w600, fontSize: 27, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Text('${provider.items.length} từ bạn đã đánh dấu để ôn lại sau',
                      style: GoogleFonts.workSans(fontSize: 15, color: AppColors.inkSoft)),
                ]),
              ),
              const SizedBox(width: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/flashcard'),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text('Ôn tập ngay →', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20), elevation: 0,
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Search + tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 20 : 44),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.workSans(fontSize: 14, color: AppColors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18, color: AppColors.inkSoft),
                    hintText: 'Tìm từ đã lưu...',
                    hintStyle: GoogleFonts.workSans(fontSize: 14, color: AppColors.textHint),
                    filled: true, fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabLabels.length, (i) {
                    final isActive = i == _selectedTabIndex;
                    final tag = switch (i) { 1 => _WordTag.new_, 2 => _WordTag.learning, 3 => _WordTag.mastered, _ => null };
                    final count = _countForTag(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.ink : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Text('${_tabLabels[i]} · $count',
                              style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isActive ? const Color(0xFFEDE6D3) : AppColors.inkSoft)),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 22),

          // Body
          Expanded(child: _buildBody(isLoading, hasError, isEmptyState, provider)),
        ]),
      ),
    );
  }

  Widget _buildBody(bool isLoading, bool hasError, bool isEmptyState, VocabularyProvider provider) {
    if (isLoading) return const SkeletonLoading(type: SkeletonType.grid, count: 8);
    if (hasError) return ErrorStateWidget(message: provider.errorMessage!, onRetry: () => provider.fetchAll(limit: 200));
    if (isEmptyState) {
      return EmptyStateWidget(
        icon: Icons.bookmark_border, title: 'Chưa có từ vựng nào',
        subtitle: 'Thêm từ mới để bắt đầu học và ôn tập.',
        action: 'Thêm từ mới', onAction: () => context.push('/vocabulary/new'), showCat: false,
      );
    }
    final filtered = _filteredWords;
    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.bookmark_border,
              size: 56, color: AppColors.inkSoft.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(_searchQuery.isNotEmpty ? 'Không tìm thấy từ nào' : 'Chưa có từ nào',
              style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                child: Text('Xoá bộ lọc', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue))),
          ],
        ]),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width < 400 ? 20 : 44, 0,
          MediaQuery.of(context).size.width < 400 ? 20 : 44, 60),
      child: LayoutBuilder(builder: (context, constraints) {
        return _buildStampGrid(filtered, constraints.maxWidth);
      }),
    );
  }

  Widget _buildStampGrid(List<_BookmarkWord> words, double maxWidth) {
    const spacing = 14.0;
    final crossAxisCount = maxWidth < 500 ? 3 : 4;
    final itemWidth = (maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
    final rows = <Widget>[];
    for (var i = 0; i < words.length; i += crossAxisCount) {
      final rowEnd = (i + crossAxisCount).clamp(0, words.length);
      final rowItems = <Widget>[];
      for (var j = i; j < rowEnd; j++) {
        rowItems.add(SizedBox(width: itemWidth, child: _WordStamp(word: words[j], isStarred: _bookmarkedIds.contains(words[j].id), onStarToggle: () => _toggleBookmark(words[j].id))));
      }
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: Row(children: List.generate(rowItems.length, (k) {
          return Padding(padding: EdgeInsets.only(left: k == 0 ? 0 : spacing / 2, right: k == rowItems.length - 1 ? 0 : spacing / 2), child: rowItems[k]);
        })),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

// SkeletonLoading moved to widgets/loading_widget.dart — use from there

class _WordStamp extends StatelessWidget {
  final _BookmarkWord word;
  final bool isStarred;
  final VoidCallback onStarToggle;
  const _WordStamp({required this.word, required this.isStarred, required this.onStarToggle});

  @override
  Widget build(BuildContext context) {
    Color tagBg, tagFg;
    switch (word.tag) {
      case _WordTag.new_: tagBg = AppColors.warningBg; tagFg = AppColors.warning; break;
      case _WordTag.learning: tagBg = AppColors.blueBg; tagFg = AppColors.blue; break;
      case _WordTag.mastered: tagBg = AppColors.successBg; tagFg = AppColors.success; break;
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.ink.withValues(alpha: 0.22), strokeWidth: 1.5,
                dashLength: 6, gapLength: 4, borderRadius: 10,
              ),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(word.word, style: GoogleFonts.workSans(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(word.ipa, style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.blue)),
          const SizedBox(height: 8),
          Text(word.meaning, style: GoogleFonts.workSans(fontSize: 13, color: AppColors.inkSoft)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(20)),
            child: Text(word.tagLabel.toUpperCase(), style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.6, color: tagFg)),
          ),
        ]),
        Positioned(top: -2, right: -2, child: GestureDetector(
          onTap: onStarToggle,
          child: Icon(isStarred ? Icons.star : Icons.star_border, size: 20,
              color: isStarred ? AppColors.warning : AppColors.ink.withValues(alpha: 0.22)),
        )),
      ]),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color; final double strokeWidth, dashLength, gapLength, borderRadius;
  _DashedBorderPainter({required this.color, this.strokeWidth = 1.5, this.dashLength = 6, this.gapLength = 4, this.borderRadius = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth || oldDelegate.dashLength != dashLength || oldDelegate.gapLength != gapLength;
}
