import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/mini_test_questions.dart';
import '../models/mock_test.dart';
import '../providers/mock_test_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<MockTestProvider>();
      prov.loadAvailableTopics();
      prov.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MockTestProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
      appBar: AppBar(
        title: Text(
          'Mini-test',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
        children: [
          // ── Step 1: Select Level ──────────────────────────
          Text(
            'Chọn cấp độ',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              fontSize: 19,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kiểm tra tổng hợp kiến thức từ vựng của bạn',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 20),

          _buildLevelCard(
            context,
            emoji: '🌱',
            title: 'Cơ bản',
            description: '10 câu trắc nghiệm · 15 phút',
            subtitle: 'Phù hợp cho người mới bắt đầu',
            borderColor: AppColors.success.withValues(alpha: 0.35),
            isSelected: prov.selectedLevel == 'beginner',
            onTap: () => prov.setLevel('beginner'),
          ),
          const SizedBox(height: 14),
          _buildLevelCard(
            context,
            emoji: '🌿',
            title: 'Trung cấp',
            description: '20 câu trắc nghiệm · 30 phút',
            subtitle: 'Dành cho trình độ trung cấp',
            borderColor: AppColors.warning.withValues(alpha: 0.35),
            isSelected: prov.selectedLevel == 'intermediate',
            onTap: () => prov.setLevel('intermediate'),
          ),
          const SizedBox(height: 14),
          _buildLevelCard(
            context,
            emoji: '🔥',
            title: 'Nâng cao',
            description: '30 câu trắc nghiệm · 45 phút',
            subtitle: 'Dành cho trình độ nâng cao',
            borderColor: AppColors.danger.withValues(alpha: 0.35),
            isSelected: prov.selectedLevel == 'advanced',
            onTap: () => prov.setLevel('advanced'),
          ),

          const SizedBox(height: 24),

          // ── Step 2: Topic selection ───────────────────────
          if (prov.availableTopics.isNotEmpty) ...[
            Text(
              'Chọn chủ đề (tuỳ chọn)',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTopicChip('Tất cả', prov.selectedTopic == null,
                    () => prov.setTopic(null)),
                ...prov.availableTopics.map((topic) {
                  final display = MiniTestBank.displayName(topic) ?? topic;
                  return _buildTopicChip(
                    display,
                    prov.selectedTopic == topic,
                    () => prov.setTopic(topic),
                  );
                }),
              ],
            ),
            const SizedBox(height: 18),
          ],

          // ── Start button ──────────────────────────────────
          ElevatedButton.icon(
            onPressed: () {
              final topic = prov.selectedTopic;
              final queryParams = topic != null ? '?topic=$topic' : '';
              context.go('/mock-test/play/${prov.selectedLevel}$queryParams');
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
                'Bắt đầu kiểm tra ${prov.selectedLevel == 'beginner' ? 'cơ bản' : prov.selectedLevel == 'intermediate' ? 'trung cấp' : 'nâng cao'}'),
          ),

          const SizedBox(height: 36),

          // ── History section ───────────────────────────────

          // Progress chart (show only if 2+ history entries)
          if (prov.history.length >= 2) ...[
            _MockTestProgressChart(history: prov.history),
            const SizedBox(height: 22),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, size: 16, color: AppColors.rose),
                ),
                const SizedBox(width: 10),
                Text(
                  'Lịch sử kiểm tra',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.ink,
                  ),
                ),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${prov.history.length} bài',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                if (prov.history.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.go('/mock-test/history'),
                    child: Text('Xem tất cả',
                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.rose)),
                  ),
                ],
              ]),
            ],
          ),
          const SizedBox(height: 14),

          if (prov.isLoading && prov.history.isEmpty)
            const SkeletonLoading(type: SkeletonType.list, count: 3)
          else if (prov.errorMessage != null && prov.history.isEmpty)
            ErrorStateWidget(
              message: prov.errorMessage!,
              onRetry: () => prov.loadHistory(),
            )
          else if (prov.history.isEmpty)
            const EmptyStateWidget(
              title: 'Chưa có bài kiểm tra nào',
              subtitle: 'Làm một bài kiểm tra để xem kết quả tại đây.',
              showCat: false,
            )
          else
            ...prov.history.take(10).map((item) => _buildHistoryItem(item)),
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String description,
    required String subtitle,
    required Color borderColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.rose.withValues(alpha: 0.10) : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.rose : AppColors.ink.withValues(alpha: 0.14),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.rose.withValues(alpha: 0.10) : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.10),
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textHint,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.rose : AppColors.inkSoft,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label == 'Tất cả' ? label : label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.rose,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.rose : AppColors.ink.withValues(alpha: 0.12),
      ),
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: selected ? Colors.white : AppColors.inkSoft,
      ),
    );
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
        ? '${item.completedAt!.day}/${item.completedAt!.month}/${item.completedAt!.year} ${item.completedAt!.hour}:${item.completedAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gradeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: item.scorePercent / 100,
                  strokeWidth: 3,
                  backgroundColor: AppColors.surfaceSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                ),
                Center(
                  child: Text(
                    '${item.scorePercent.round()}%',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        levelLabel.toUpperCase(),
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Hạng ${item.grade}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: gradeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.correctAnswers}/${item.totalQuestions} câu đúng',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          // Retry button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: () => context.go(
                '/mock-test/play/${item.testLevel}',
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: AppColors.rose,
              tooltip: 'Làm lại',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple progress chart showing score trend over last mock tests.
class _MockTestProgressChart extends StatelessWidget {
  final List<MockTestHistoryItem> history;

  const _MockTestProgressChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final display = history.take(10).toList()..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
    if (display.length < 2) return const SizedBox.shrink();

    final maxScore = display.fold<double>(0, (max, item) => item.scorePercent > max ? item.scorePercent : max);
    final chartMax = (maxScore > 20 ? maxScore : 100).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Xu hướng điểm số',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScoreChartPainter(
                scores: display.map((e) => e.scorePercent).toList(),
                maxY: chartMax,
                color: AppColors.rose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  final List<double> scores;
  final double maxY;
  final Color color;

  _ScoreChartPainter({
    required this.scores,
    required this.maxY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (scores.length - 1);

    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / maxY * size.height * 0.85) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((scores.length - 1) * stepX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / maxY * size.height * 0.85) - 4;
      canvas.drawCircle(Offset(x, y), 3.5, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter old) => old.scores != scores || old.maxY != maxY;
}
