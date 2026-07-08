import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../models/vocabulary.dart';
import 'speaker_button.dart';

class VocabCard extends StatelessWidget {
  final Vocabulary vocab;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VocabCard({super.key, required this.vocab, this.onEdit, this.onDelete});

  Color get _topicColor {
    final topicColors = {
      'general': AppColors.blue,
      'giao tiếp': AppColors.warning,
      'du lịch': AppColors.success,
      'công việc': AppColors.blue,
      'học tập': AppColors.warning,
    };
    return topicColors[vocab.topic.toLowerCase()] ?? AppColors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.ink.withValues(alpha: 0.10),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar letter
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _topicColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    vocab.word.isNotEmpty ? vocab.word[0].toUpperCase() : '?',
                    style: GoogleFonts.workSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Word + meaning
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vocab.word,
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vocab.meaning,
                      style: GoogleFonts.workSans(
                        color: AppColors.inkSoft,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Topic badge + actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vocab.topic.isNotEmpty && vocab.topic != 'general')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _topicColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vocab.topic,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          color: _topicColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (onEdit != null) ...[
                    SpeakerButton(text: vocab.word, size: 26),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppColors.inkSoft,
                      onPressed: onEdit,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppColors.danger,
                      onPressed: onDelete,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
