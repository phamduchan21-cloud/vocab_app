import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats? stats;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const StatsGrid({
    super.key,
    this.stats,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null || stats == null) return const SizedBox.shrink();
    if (stats!.vocabCount == 0) return const SizedBox.shrink();
    return _buildContent();
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final s = stats!;
    final levelTitle = s.levelTitle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
        children: [
          _StatBox(
            emoji: '📚',
            value: '${s.vocabCount}',
            label: 'Tổng từ',
            color: const Color(0xFF8B5CF6),
          ),
          _StatBox(
            emoji: '🧠',
            value: '${s.vocabCount > 0 ? (s.accuracyRate / 100 * s.vocabCount).round() : 0}',
            label: 'Đã thuộc',
            color: const Color(0xFF34D399),
          ),
          _StatBox(
            emoji: '📈',
            value: '${s.accuracyRate.toStringAsFixed(0)}%',
            label: 'Chính xác',
            color: const Color(0xFFF472B6),
          ),
          _StatBox(
            emoji: '🏆',
            value: levelTitle.split(' ').last,
            label: 'Level ${s.level}',
            color: const Color(0xFFFB923C),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
