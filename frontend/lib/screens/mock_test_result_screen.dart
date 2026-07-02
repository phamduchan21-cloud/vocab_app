import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../models/mock_test.dart';

class MockTestResultScreen extends StatelessWidget {
  final MockTestResult result;

  const MockTestResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(result.predictedLevel);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả thi thử', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score circle
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [levelColor, levelColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: levelColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.scorePercent.toStringAsFixed(0)}%',
                      style: GoogleFonts.nunito(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      result.predictedLevel,
                      style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dự đoán cấp độ TOPIK',
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  _statItem('📝', '${result.totalQuestions}', 'Tổng câu'),
                  Container(width: 1, height: 40, color: AppColors.textHint.withValues(alpha: 0.3)),
                  _statItem('✅', '${result.correctAnswers}', 'Đúng'),
                  Container(width: 1, height: 40, color: AppColors.textHint.withValues(alpha: 0.3)),
                  _statItem('❌', '${result.totalQuestions - result.correctAnswers}', 'Sai'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Level info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: levelColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text('🏆', style: TextStyle(fontSize: 40, color: levelColor)),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn đạt trình độ ${result.predictedLevel}',
                    style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLevelDescription(result.predictedLevel),
                    style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: Text('Về trang chủ', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text('Làm lại', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    final num = int.tryParse(level.replaceAll('급', '')) ?? 1;
    if (num >= 5) return const Color(0xFF8B5CF6);
    if (num >= 3) return const Color(0xFF34D399);
    return const Color(0xFFFB923C);
  }

  String _getLevelDescription(String level) {
    final num = int.tryParse(level.replaceAll('급', '')) ?? 1;
    switch (num) {
      case 6: return 'Trình độ cao cấp — Có thể giao tiếp trôi chảy trong mọi tình huống.';
      case 5: return 'Trình độ cao cấp — Có thể sử dụng tiếng Hàn thành thạo trong công việc.';
      case 4: return 'Trình độ trung cấp — Có thể giao tiếp tương đối tốt trong cuộc sống.';
      case 3: return 'Trình độ trung cấp — Có thể giao tiếp cơ bản trong sinh hoạt hàng ngày.';
      case 2: return 'Trình độ sơ cấp — Có thể giao tiếp đơn giản trong các tình huống quen thuộc.';
      default: return 'Trình độ sơ cấp — Bắt đầu làm quen với tiếng Hàn.';
    }
  }
}
