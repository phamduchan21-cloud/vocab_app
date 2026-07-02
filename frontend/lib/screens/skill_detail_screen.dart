import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_data.dart';

class SkillDetailScreen extends StatefulWidget {
  final String skillType;
  final String skillTitle;

  const SkillDetailScreen({
    super.key,
    required this.skillType,
    required this.skillTitle,
  });

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  static const _skillMeta = {
    'listening': {'emoji': '🎧', 'color': Color(0xFF8B5CF6), 'desc': 'Luyện nghe từ vựng và hội thoại TOPIK'},
    'reading': {'emoji': '📖', 'color': Color(0xFF34D399), 'desc': 'Luyện đọc đoạn văn và câu hỏi'},
    'vocabulary': {'emoji': '📝', 'color': Color(0xFFF472B6), 'desc': 'Học từ vựng theo chủ đề TOPIK'},
    'grammar': {'emoji': '📐', 'color': Color(0xFFFB923C), 'desc': 'Học cấu trúc ngữ pháp TOPIK'},
  };

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final meta = _skillMeta[widget.skillType] ?? {'emoji': '📚', 'color': AppColors.primary, 'desc': ''};
    final color = meta['color'] as Color;
    final emoji = meta['emoji'] as String;
    final desc = meta['desc'] as String;

    SkillItem? skill;
    if (dashboard.data != null) {
      for (final s in dashboard.data!.skills) {
        if (s.type == widget.skillType) {
          skill = s;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              widget.skillTitle,
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: color.withValues(alpha: 0.05),
        foregroundColor: color,
      ),
      body: _buildBody(skill, color, desc, emoji, context),
    );
  }

  Widget _buildBody(SkillItem? skill, Color color, String desc, String emoji, BuildContext context) {
    if (skill == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 64, color: color)),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu cho kỹ năng này',
              style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/quiz/play'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bắt đầu học'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  widget.skillTitle,
                  style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('🎯', '${skill.accuracy.toStringAsFixed(0)}%', 'Độ chính xác'),
                    _statItem('⭐', '${skill.xp}', 'XP'),
                    _statItem('📝', '${skill.completed}/${skill.total}', 'Bài đã làm'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Text('Bắt đầu học', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          _actionCard(context, '🎯', 'Luyện tập', 'Làm bài trắc nghiệm', () => context.go('/quiz/play')),
          const SizedBox(height: 10),

          if (widget.skillType == 'vocabulary')
            _actionCard(context, '📖', 'Học từ mới', 'Thêm từ vựng để học', () => context.go('/vocabulary/new')),

          if (widget.skillType == 'grammar')
            _actionCard(context, '📐', 'Học ngữ pháp', 'Xem bài học ngữ pháp', () => context.go('/quiz/play')),

          if (widget.skillType == 'listening')
            _actionCard(context, '🎧', 'Luyện nghe', 'Nghe và trả lời câu hỏi', () => context.go('/quiz/play')),

          if (widget.skillType == 'reading')
            _actionCard(context, '📖', 'Luyện đọc', 'Đọc đoạn văn và trả lời', () => context.go('/quiz/play')),

          const SizedBox(height: 24),

          // History
          Text('Lịch sử', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: AppColors.textHint),
                const SizedBox(height: 8),
                Text(
                  'Xem lịch sử học tập chi tiết',
                  style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/quiz/history'),
                  child: const Text('Xem lịch sử →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.nunito(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _actionCard(BuildContext context, String emoji, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(subtitle, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
