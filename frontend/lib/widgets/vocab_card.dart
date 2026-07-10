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
      'general': AppColors.luxuryBrown,
      'giao tiếp': AppColors.luxuryGold,
      'du lich': AppColors.luxuryGreen,
      'cong viec': AppColors.luxuryBrownLight,
      'hoc tap': AppColors.luxuryGold,
    };
    return topicColors[vocab.topic.toLowerCase()] ?? AppColors.luxuryBrown;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.luxuryBorder.withValues(alpha: 0.4), width: 0.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Avatar letter
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _topicColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      vocab.word.isNotEmpty ? vocab.word[0].toUpperCase() : '?',
                      style: GoogleFonts.playfairDisplay(
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
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.luxuryEspresso,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vocab.meaning,
                        style: GoogleFonts.nunito(
                          color: AppColors.luxuryText,
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
                          style: GoogleFonts.nunito(
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
                        color: AppColors.luxuryText,
                        onPressed: onEdit,
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.luxuryDanger,
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
      ),
    );
  }
}
