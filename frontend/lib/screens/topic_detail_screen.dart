import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/topic_data.dart';
import '../providers/topic_provider.dart';
import '../providers/quiz_provider.dart';
import '../services/vocabulary_service.dart';
import '../widgets/speaker_button.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

class TopicDetailScreen extends StatefulWidget {
  final String lessonId;

  const TopicDetailScreen({super.key, required this.lessonId});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  String? _topicName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final topicProv = context.read<TopicProvider>();
      final topic = topicProv.topics
          .where((t) => t.lessonId.toString() == widget.lessonId)
          .firstOrNull;
      if (topic != null) {
        _topicName = topic.title;
      }

      // Map lesson ID to topic name
      final lessonTopicMap = {
        '1': 'greetings',
        '2': 'family',
        '3': 'numbers',
        '4': 'daily',
        '5': 'food',
        '6': 'travel',
        '7': 'shopping',
        '8': 'weather',
        '9': 'health',
        '10': 'work',
        '11': 'education',
        '12': 'entertainment',
        '13': 'technology',
        '14': 'emotions',
        '15': 'society',
      };
      final topicKey = lessonTopicMap[widget.lessonId] ?? widget.lessonId;
      _topicName ??= topicKey;
      topicProv.loadVocabByTopic(topic: topicKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final topicProv = context.watch<TopicProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _topicName ?? 'Từ vựng chủ đề',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          // Action buttons
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.ink.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${topicProv.vocabItems.length} từ trong bài',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Nghe, đọc ví dụ rồi kiểm tra ngay.',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final quiz = context.read<QuizProvider>();
                          quiz.setTopic(_topicName?.toLowerCase() ?? '');
                          context.go('/quiz/play');
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(
                          'Bắt đầu quiz',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Body
          Expanded(child: _buildBody(topicProv)),
        ],
      ),
    );
  }

  Widget _buildBody(TopicProvider provider) {
    if (provider.isLoading && provider.vocabItems.isEmpty) {
      return const SkeletonLoading(type: SkeletonType.list, count: 8);
    }

    if (provider.errorMessage != null && provider.vocabItems.isEmpty) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () =>
            provider.loadVocabByTopic(topic: _topicName?.toLowerCase() ?? ''),
      );
    }

    final items = provider.vocabItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 52,
              color: AppColors.inkSoft,
            ),
            const SizedBox(height: 14),
            Text(
              'Chủ đề này chưa có từ vựng',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy quay lại và chọn một chủ đề khác.',
              style: GoogleFonts.nunito(color: AppColors.inkSoft),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _VocabCardTile(item: item, onAdd: () => _addToMyVocab(item));
          },
        ),
      ),
    );
  }

  Future<void> _addToMyVocab(SeedVocabItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final vocabService = context.read<VocabularyService>();
      await vocabService.create({
        'word': item.word,
        'meaning': item.meaning,
        'example': item.example ?? '',
        'topic': item.topic,
      });
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã thêm "${item.word}" vào từ vựng của bạn'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể thêm từ: ${item.word}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _VocabCardTile extends StatelessWidget {
  final SeedVocabItem item;
  final VoidCallback onAdd;

  const _VocabCardTile({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.word,
                            style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SpeakerButton(text: item.word, size: 24),
                      ],
                    ),
                    if (item.pronunciation != null)
                      Text(
                        item.pronunciation!,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      item.meaning,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: AppColors.rose,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.rose,
                tooltip: 'Thêm vào từ của tôi',
              ),
            ],
          ),
          if (item.example != null && item.example!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.example!,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
