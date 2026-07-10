import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/mock_test.dart';
import '../providers/mock_test_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';

// ═════════════════════════════════════════════════════════════════════════
// MOCK TEST HISTORY — Candy Style
// ═════════════════════════════════════════════════════════════════════════

class MockTestHistoryScreen extends StatefulWidget {
  const MockTestHistoryScreen({super.key});

  @override
  State<MockTestHistoryScreen> createState() => _MockTestHistoryScreenState();
}

class _MockTestHistoryScreenState extends State<MockTestHistoryScreen> {
  int _page = 1;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MockTestProvider>().loadHistory(page: 1, limit: 50);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final prov = context.read<MockTestProvider>();
    if (_isLoadingMore || prov.history.length >= prov.historyTotal) return;
    _isLoadingMore = true;
    _page++;
    await prov.loadHistory(page: _page, limit: 20);
    _isLoadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MockTestProvider>();
    final isLoading = prov.isLoading && prov.history.isEmpty;
    final hasError = prov.errorMessage != null && prov.history.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Lịch sử mini-test',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.ink)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.3,
        actions: [
          if (prov.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${prov.historyTotal} bài',
                    style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.rose)),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          await prov.loadHistory(page: 1, limit: 50);
        },
        child: _buildBody(isLoading, hasError, prov),
      ),
    );
  }

  Widget _buildBody(bool isLoading, bool hasError, MockTestProvider prov) {
    if (isLoading) return const SkeletonLoading(type: SkeletonType.list, count: 6);
    if (hasError) return ErrorStateWidget(message: prov.errorMessage!, onRetry: () => prov.loadHistory(page: 1, limit: 50));
    if (prov.history.isEmpty) {
      return const EmptyStateWidget(
        title: 'Chưa có bài kiểm tra nào',
        subtitle: 'Làm bài mini-test đầu tiên nhé!',
        showCat: false,
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Stats summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.rose.withValues(alpha: 0.08), AppColors.rose.withValues(alpha: 0.02)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.rose.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppColors.rose, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tổng quan', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('${prov.historyTotal} bài kiểm tra',
                    style: GoogleFonts.nunito(fontSize: 12, color: AppColors.inkSoft)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${_avgScore(prov.history)}%',
                    style: GoogleFonts.ibmPlexMono(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.rose)),
                Text('TB', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.inkSoft)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // List header
        Row(
          children: [
            Text('Tất cả bài kiểm tra',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 12),
        // Items
        ...prov.history.map((item) => _buildHistoryItem(item)),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
          ),
      ],
    );
  }

  int _avgScore(List<MockTestHistoryItem> items) {
    if (items.isEmpty) return 0;
    final total = items.fold<double>(0, (sum, i) => sum + i.scorePercent);
    return (total / items.length).round();
  }

  Widget _buildHistoryItem(MockTestHistoryItem item) {
    final gradeColor = item.grade == 'A'
        ? AppColors.success
        : item.grade == 'B'
            ? AppColors.rose
            : item.grade == 'C'
                ? AppColors.warning
                : AppColors.danger;
    final levelLabel = item.testLevel == 'beginner'
        ? 'Cơ bản'
        : item.testLevel == 'intermediate'
            ? 'Trung cấp'
            : 'Nâng cao';
    final dateStr = item.completedAt != null
        ? '${item.completedAt!.day}/${item.completedAt!.month}/${item.completedAt!.year} ${item.completedAt!.hour.toString().padLeft(2, '0')}:${item.completedAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradeColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(width: 46, height: 46, child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: item.scorePercent / 100, strokeWidth: 3.5,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
            ),
            Center(child: Text('${item.scorePercent.round()}%',
                style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: gradeColor))),
          ])),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _tag(levelLabel, AppColors.rose.withValues(alpha: 0.08), AppColors.rose),
              const SizedBox(width: 6),
              _tag('Hạng ${item.grade}', gradeColor.withValues(alpha: 0.10), gradeColor),
            ]),
            const SizedBox(height: 6),
            Text('${item.correctAnswers}/${item.totalQuestions} câu đúng',
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
            Text(dateStr, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.inkSoft)),
          ])),
          Container(
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () => context.go('/mock-test/play/${item.testLevel}'),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: AppColors.rose,
              tooltip: 'Làm lại',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.ibmPlexMono(fontSize: 9, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
