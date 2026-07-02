import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📝 Kiểm tra từ vựng', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Chọn cấp độ', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildLevelCard(
            context,
            emoji: '🌱',
            title: 'Cơ bản',
            desc: '10 câu trắc nghiệm · 15 phút\nPhù hợp cho người mới bắt đầu',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go('/mock-test/play/beginner'),
          ),
          const SizedBox(height: 12),
          _buildLevelCard(
            context,
            emoji: '🌿',
            title: 'Trung cấp',
            desc: '20 câu trắc nghiệm · 30 phút\nDành cho trình độ trung cấp',
            color: const Color(0xFF34D399),
            onTap: () => context.go('/mock-test/play/intermediate'),
          ),
          const SizedBox(height: 12),
          _buildLevelCard(
            context,
            emoji: '🔥',
            title: 'Nâng cao',
            desc: '30 câu trắc nghiệm · 45 phút\nDành cho trình độ nâng cao',
            color: const Color(0xFFF472B6),
            onTap: () => context.go('/mock-test/play/advanced'),
          ),
          const SizedBox(height: 32),
          Text('Lịch sử kiểm tra', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _buildHistoryItem(context, 'Cơ bản', '90%', 'A', '02/07/2026'),
          _buildHistoryItem(context, 'Trung cấp', '75%', 'B', '01/07/2026'),
          _buildHistoryItem(context, 'Nâng cao', '60%', 'C', '30/06/2026'),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, {required String emoji, required String title, required String desc, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String level, String score, String grade, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.catLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(level, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Điểm: $score', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Xếp loại: $grade · $date', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: score.contains('8') || score.contains('9')
                  ? AppColors.accent3.withValues(alpha: 0.1)
                  : AppColors.accent1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(grade, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold,
              color: score.contains('8') || score.contains('9') ? AppColors.accent3 : AppColors.accent1)),
          ),
        ],
      ),
    );
  }
}
