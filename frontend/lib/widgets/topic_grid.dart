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
    'greetings': '👋',
    'family': '👨‍👩‍👧‍👦',
    'numbers': '🔢',
    'daily': '🌅',
    'food': '🍜',
    'travel': '✈️',
    'shopping': '🛒',
    'weather': '⛅',
    'health': '💪',
    'work': '💼',
    'education': '🎓',
    'entertainment': '🎮',
    'technology': '💻',
    'emotions': '😊',
    'society': '🌍',
  };

  String _emojiFor(String topic) {
    final key = topic.toLowerCase().trim();
    return _topicEmojis.entries
        .firstWhere(
          (e) => key.contains(e.key),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceSubtle,
        highlightColor: AppColors.surface,
        child: Row(
          children: List.generate(4, (_) => Expanded(
            child: Container(
              height: 72,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final displayTopics = topics!.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '📂  Danh mục chủ đề',
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'Xem tất cả →',
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayTopics.map((topic) => _TopicChip(
            emoji: _emojiFor(topic.topic),
            topic: topic,
            onTap: () => onTopicTap?.call(topic.topic),
          )).toList(),
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String emoji;
  final TopicProgressItem topic;
  final VoidCallback? onTap;

  const _TopicChip({required this.emoji, required this.topic, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topic.topic.length > 10
                      ? '${topic.topic.substring(0, 10)}..'
                      : topic.topic,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${topic.total} từ · ${topic.masteryPercent.round()}%',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
