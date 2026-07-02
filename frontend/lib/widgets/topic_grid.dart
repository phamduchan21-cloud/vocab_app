import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../app.dart';
import '../models/dashboard_data.dart';

class TopicGrid extends StatelessWidget {
  final List<TopicProgressItem>? topics;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onSeeAll;
  final void Function(String topic)? onTopicTap;

  const TopicGrid({
    super.key,
    this.topics,
    this.isLoading = false,
    this.errorMessage,
    this.onSeeAll,
    this.onTopicTap,
  });

  static const _topicEmojis = {
    'general': '📚',
    'du lịch': '🌍',
    'công việc': '💼',
    'ẩm thực': '🍜',
    'y tế': '🏥',
    'học tập': '🎓',
    'gia đình': '🏠',
    'giải trí': '🎬',
    'sức khỏe': '💪',
  };

  String _emojiFor(String topic) {
    return _topicEmojis.entries
        .firstWhere(
          (e) => topic.toLowerCase().contains(e.key),
          orElse: () => MapEntry(topic, '📚'),
        )
        .value;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (errorMessage != null || topics == null || topics!.isEmpty) {
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
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
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
    final displayTopics = topics!.take(8).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📂', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Danh mục chủ đề',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Xem tất cả →'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayTopics.length,
            itemBuilder: (context, index) {
              final topic = displayTopics[index];
              return _TopicCell(
                emoji: _emojiFor(topic.topic),
                topic: topic,
                onTap: () => onTopicTap?.call(topic.topic),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopicCell extends StatelessWidget {
  final String emoji;
  final TopicProgressItem topic;
  final VoidCallback? onTap;

  const _TopicCell({
    required this.emoji,
    required this.topic,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
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
              topic.topic.length > 5
                  ? '${topic.topic.substring(0, 5)}..'
                  : topic.topic,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${topic.total} từ',
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${topic.masteryPercent.toStringAsFixed(0)}%',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: topic.masteryPercent >= 70
                    ? AppColors.accent3
                    : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
