import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

class SkillGrid extends StatelessWidget {
  final List<SkillItem>? skills;
  final bool isLoading;
  final String? errorMessage;
  final void Function(String type, String title)? onSkillTap;

  const SkillGrid({
    super.key,
    this.skills,
    this.isLoading = false,
    this.errorMessage,
    this.onSkillTap,
  });

  // 4 tính năng chính — tập trung vào từ vựng
  static const _items = [
    {'key': 'vocabulary', 'emoji': '📝', 'title': 'Từ vựng', 'desc': 'Học từ mới', 'color': Color(0xFFF472B6)},
    {'key': 'flashcard', 'emoji': '🃏', 'title': 'Flashcard', 'desc': 'Ôn tập SM-2', 'color': Color(0xFF8B5CF6)},
    {'key': 'quiz', 'emoji': '✏️', 'title': 'Quiz', 'desc': 'Kiểm tra nhanh', 'color': Color(0xFF34D399)},
    {'key': 'achievement', 'emoji': '🏆', 'title': 'Thành tựu', 'desc': 'Cột mốc', 'color': Color(0xFFFB923C)},
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null) return const SizedBox.shrink();
    return _buildContent();
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: List.generate(4, (_) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Tính năng',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: _items.map((item) {
              final color = item['color'] as Color;
              final emoji = item['emoji'] as String;
              final title = item['title'] as String;
              final desc = item['desc'] as String;
              final key = item['key'] as String;

              return GestureDetector(
                onTap: () => onSkillTap?.call(key, title),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        desc,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
