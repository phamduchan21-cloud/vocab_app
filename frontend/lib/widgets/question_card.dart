import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.options,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              question,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Options
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selected == option;
            final letter = String.fromCharCode(65 + index); // A, B, C, D

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.catLight
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      // Letter circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : Text(
                                  letter,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textHint,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Option text
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            option,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
