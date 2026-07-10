import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

enum SkeletonType { list, grid, card, form, quiz }

class SkeletonLoading extends StatelessWidget {
  final SkeletonType type;
  final int count;

  const SkeletonLoading({
    super.key,
    this.type = SkeletonType.list,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.luxuryBorder,
      highlightColor: AppColors.luxurySurface,
      child: _buildByType(),
    );
  }

  Widget _buildByType() {
    switch (type) {
      case SkeletonType.list:
        return Column(
          children: List.generate(count, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _skeletonCard(72),
          )),
        );
      case SkeletonType.grid:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: List.generate(count, (_) => _skeletonCard(100)),
          ),
        );
      case SkeletonType.card:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _skeletonCard(120),
        );
      case SkeletonType.form:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
          ),
        );
      case SkeletonType.quiz:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(height: 24, width: 200, decoration: _boxDecoration()),
              const SizedBox(height: 20),
              Container(height: 60, decoration: _boxDecoration()),
              const SizedBox(height: 16),
              ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(height: 52, decoration: _boxDecoration()),
              )),
            ],
          ),
        );
    }
  }

  Widget _skeletonCard(double height) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 120, decoration: _boxDecoration()),
                const SizedBox(height: 8),
                Container(height: 12, width: 80, decoration: _boxDecoration()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.luxuryBrown,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: GoogleFonts.nunito(fontSize: 16, color: AppColors.luxuryText),
            ),
          ],
        ],
      ),
    );
  }
}
