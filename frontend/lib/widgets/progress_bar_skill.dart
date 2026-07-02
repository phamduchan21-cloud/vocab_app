import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

class ProgressBarSkill extends StatelessWidget {
  final List<SkillItem>? skills;
  final bool isLoading;
  final String? errorMessage;

  const ProgressBarSkill({
    super.key,
    this.skills,
    this.isLoading = false,
    this.errorMessage,
  });

  static const _skillMeta = {
    'vocabulary': {'emoji': '📚', 'label': 'Từ vựng'},
    'grammar': {'emoji': '📐', 'label': 'Ngữ pháp'},
    'listening': {'emoji': '🎧', 'label': 'Nghe'},
    'reading': {'emoji': '📖', 'label': 'Đọc'},
  };

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null || skills == null || skills!.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildContent();
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonLine(140, 20),
            const SizedBox(height: 12),
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _skeletonLine(double.infinity, 44),
            )),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine(double w, double h) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
  );

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
                const Text('📊', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Tiến độ từng kỹ năng',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: skills!.map((skill) {
                final meta = _skillMeta[skill.type] ?? {'emoji': '📚', 'label': skill.title};
                final percent = skill.accuracy;
                final color = percent >= 80
                    ? AppColors.accent3
                    : percent >= 50
                        ? AppColors.primary
                        : AppColors.accent2;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(meta['emoji'] as String, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 70,
                        child: Text(
                          meta['label'] as String,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            backgroundColor: AppColors.catLight,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${percent.toStringAsFixed(0)}%',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
