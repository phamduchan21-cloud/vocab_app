import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

/// Widget flashcard có hiệu ứng lật thẻ và vuốt trái/phải.
///
/// - Tap vào thẻ → lật mặt (từ → nghĩa + ví dụ)
/// - Vuốt phải → "Đã thuộc" (quality 4-5)
/// - Vuốt trái → "Cần ôn lại" (quality 1-2)
/// - Gọi callback `onReview` để cập nhật SM-2 lên backend
class FlashcardWidget extends StatefulWidget {
  final String id;
  final String word;
  final String meaning;
  final String? example;
  final String? pronunciation;
  final int index;
  final int total;
  final Future<void> Function(String id, int quality)? onReview;

  const FlashcardWidget({
    super.key,
    required this.id,
    required this.word,
    required this.meaning,
    this.example,
    this.pronunciation,
    required this.index,
    required this.total,
    this.onReview,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Counter
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${widget.index + 1} / ${widget.total}',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Flashcard
        GestureDetector(
          onTap: () {
            if (!_isAnimating) {
              setState(() => _isFlipped = !_isFlipped);
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(animation.value * 3.14159),
                child: child,
              );
            },
            child: _isFlipped ? _buildBack() : _buildFront(),
          ),
        ),

        const SizedBox(height: 24),

        // Buttons
        if (_isFlipped) _buildActionButtons(),
      ],
    );
  }

  Widget _buildFront() {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFAF5FF), Color(0xFFFFFFFF)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Hint text
          Text(
            'Nhấn để lật thẻ',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),

          // Word
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.word,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Pronunciation (if available)
          if (widget.pronunciation != null)
            Text(
              widget.pronunciation!,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),

          const SizedBox(height: 40),

          // Tap hint
          Icon(
            Icons.touch_app_rounded,
            size: 28,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Meaning
          Text(
            widget.meaning,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Pronunciation (if available)
          if (widget.pronunciation != null)
            Text(
              widget.pronunciation!,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),

          if (widget.pronunciation != null) const SizedBox(height: 20),

          // Example
          if (widget.example != null && widget.example!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.catLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"${widget.example}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // "Cần ôn lại" — vuốt trái
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _handleReview(1),
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: Text(
                  'Cần ôn lại',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent1,
                  side: BorderSide(color: AppColors.accent1.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // "Đã thuộc" — vuốt phải
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _handleReview(4),
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: Text(
                  'Đã thuộc',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent3,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReview(int quality) async {
    setState(() => _isAnimating = true);
    if (widget.onReview != null) {
      await widget.onReview!(widget.id, quality);
    }
    if (mounted) {
      setState(() {
        _isFlipped = false;
        _isAnimating = false;
      });
    }
  }
}
