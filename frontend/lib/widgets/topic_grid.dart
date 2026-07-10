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
        baseColor: AppColors.luxuryBorder,
        highlightColor: AppColors.luxurySurface,
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
              'Danh muc chu de',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.luxuryEspresso,
              ),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'Xem tat ca →',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.luxuryGold,
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
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.luxurySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.luxuryBorder.withValues(alpha: 0.4), width: 0.5),
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
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.luxuryEspresso,
                    ),
                  ),
                  Text(
                    '${topic.total} tu · ${topic.masteryPercent.round()}%',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: AppColors.luxuryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
