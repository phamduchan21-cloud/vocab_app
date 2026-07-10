import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

/// Editorial-luxury bottom sheet for selecting a study topic.
/// Double-bezel tiles with gold accent and playfair headings.
class FlashcardTopicSheet extends StatefulWidget {
  final List<String> topics;
  final Map<String, int> topicItemCount;
  final String selectedTopic;
  final ValueChanged<String> onTopicChanged;

  const FlashcardTopicSheet({
    super.key,
    required this.topics,
    required this.topicItemCount,
    required this.selectedTopic,
    required this.onTopicChanged,
  });

  /// Show the topic selection bottom sheet and return the selected topic.
  /// Returns `null` if the user dismisses without selecting.
  static Future<String?> show(BuildContext context, {
    required List<String> topics,
    required Map<String, int> topicItemCount,
    required String selectedTopic,
    required ValueChanged<String> onTopicChanged,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FlashcardTopicSheet(
        topics: topics,
        topicItemCount: topicItemCount,
        selectedTopic: selectedTopic,
        onTopicChanged: onTopicChanged,
      ),
    );
  }

  @override
  State<FlashcardTopicSheet> createState() => _FlashcardTopicSheetState();
}

class _FlashcardTopicSheetState extends State<FlashcardTopicSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredTopics {
    if (_searchQuery.isEmpty) {
      return ['all', ...widget.topics];
    }
    final q = _searchQuery.toLowerCase();
    return ['all', ...widget.topics.where((t) => t.toLowerCase().contains(q))];
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.topicItemCount.values.fold<int>(0, (a, b) => a + b);
    final filtered = _filteredTopics;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.luxuryBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Title ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Text(
                  'Chon chu de',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
                const Spacer(),
                Text(
                  '$totalItems the',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.luxuryText,
                  ),
                ),
              ],
            ),
          ),
          // ── Search ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.luxuryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tim chu de...',
                  hintStyle: GoogleFonts.nunito(color: AppColors.luxuryTextHint, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.luxuryTextHint, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.luxuryTextHint, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          // ── Topic grid ───────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Khong tim thay chu de phu hop',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.luxuryTextHint,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final topic = filtered[index];
                      final isSelected = topic == widget.selectedTopic;
                      final count = topic == 'all'
                          ? totalItems
                          : (widget.topicItemCount[topic] ?? 0);
                      final label = topic == 'all' ? 'Tat ca' : _topicLabel(topic);
                      // Emoji mapping for common topics
                      final emoji = _topicEmoji(topic);

                      return _TopicTile(
                        emoji: emoji,
                        label: label,
                        count: count,
                        isSelected: isSelected,
                        onTap: () {
                          widget.onTopicChanged(topic);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _topicEmoji(String topic) {
    const emojiMap = {
      'all': '📚',
      'greetings': '👋',
      'family': '👨‍👩‍👧‍👦',
      'numbers': '🔢',
      'daily': '☀️',
      'food': '🍕',
      'travel': '✈️',
      'shopping': '🛍️',
      'weather': '⛅',
      'health': '❤️',
      'work': '💼',
      'education': '📖',
      'entertainment': '🎬',
      'technology': '💻',
      'emotions': '😊',
      'society': '🌍',
    };
    final lower = topic.toLowerCase();
    for (final entry in emojiMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return '📖';
  }

  String _topicLabel(String topic) {
    const labels = {
      'family': 'Gia đình & Bạn bè',
      'travel': 'Du lịch',
      'work': 'Công việc & Nghề nghiệp',
      'food': 'Ẩm thực',
    };
    return labels[topic] ?? topic;
  }
}

class _TopicTile extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicTile({
    required this.emoji,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSelected ? AppColors.luxuryGold : AppColors.luxuryBrown;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.luxurySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.luxuryGold.withValues(alpha: 0.5)
                  : AppColors.luxuryBorder,
              width: 1.5,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isSelected
                    ? AppColors.luxuryGold.withValues(alpha: 0.2)
                    : AppColors.luxuryBorder.withValues(alpha: 0.4),
                width: 0.5,
              ),
              color: isSelected
                  ? AppColors.luxuryGold.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: activeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count the',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppColors.luxuryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
