import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../models/vocabulary.dart';

class VocabCard extends StatelessWidget {
  final Vocabulary vocab;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VocabCard({super.key, required this.vocab, this.onEdit, this.onDelete});

  Color get _topicColor {
    final topicColors = {
      'general': AppColors.primary,
      'giao tiếp': AppColors.secondary,
      'du lịch': AppColors.accent1,
      'công việc': AppColors.catPurple,
      'học tập': AppColors.catPink,
    };
    return topicColors[vocab.topic.toLowerCase()] ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar letter
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_topicColor, _topicColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    vocab.word.isNotEmpty ? vocab.word[0].toUpperCase() : '?',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vocab.meaning,
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _topicColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vocab.topic,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: _topicColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.catLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.primary,
                        onPressed: onEdit,
                        splashRadius: 20,
                      ),
                    ),
                  ],
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppColors.accent2,
                      onPressed: onDelete,
                      splashRadius: 20,
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
