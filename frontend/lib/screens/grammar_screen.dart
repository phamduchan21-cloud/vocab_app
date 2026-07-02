import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  // Mock data — sẽ thay bằng API sau
  final List<GrammarLesson> _lessons = [
    GrammarLesson(level: 'TOPIK 1', title: '-은/는', description: 'Tiểu chủ đề', example: '저는 학생입니다.', translated: 'Tôi là học sinh.'),
    GrammarLesson(level: 'TOPIK 1', title: '-이/가', description: 'Tiểu từ chủ ngữ', example: '가방이 있어요.', translated: 'Có cái cặp.'),
    GrammarLesson(level: 'TOPIK 1', title: '-을/를', description: 'Tiểu từ tân ngữ', example: '밥을 먹어요.', translated: 'Ăn cơm.'),
    GrammarLesson(level: 'TOPIK 2', title: '-아/어서', description: 'Vì nên', example: '바빠서 못 가요.', translated: 'Vì bận nên không đi được.'),
    GrammarLesson(level: 'TOPIK 2', title: '-고 싶다', description: 'Muốn', example: '한국에 가고 싶어요.', translated: 'Tôi muốn đi Hàn Quốc.'),
    GrammarLesson(level: 'TOPIK 2', title: '-는 중이다', description: 'Đang làm gì', example: '공부하는 중이에요.', translated: 'Đang học bài.'),
  ];

  String _selectedLevel = 'Tất cả';
  final List<String> _levels = ['Tất cả', 'TOPIK 1', 'TOPIK 2'];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedLevel == 'Tất cả'
        ? _lessons
        : _lessons.where((l) => l.level == _selectedLevel).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '📐 Ngữ pháp',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFFB923C).withValues(alpha: 0.05),
        foregroundColor: const Color(0xFFFB923C),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _levels.map((level) {
                final isActive = _selectedLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(level, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600)),
                    selected: isActive,
                    onSelected: (_) => setState(() => _selectedLevel = level),
                    selectedColor: const Color(0xFFFB923C),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: isActive ? const Color(0xFFFB923C) : AppColors.textHint.withValues(alpha: 0.3)),
                  ),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📐', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text('Chưa có bài học', style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildLessonCard(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(GrammarLesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFB923C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lesson.level,
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFB923C)),
                ),
              ),
              const Spacer(),
              Icon(Icons.volume_up_rounded, size: 18, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lesson.title,
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            lesson.description,
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.catLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.example,
                  style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.translated,
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/quiz/play'),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text('Luyện tập', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFB923C),
                side: const BorderSide(color: Color(0xFFFB923C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GrammarLesson {
  final String level;
  final String title;
  final String description;
  final String example;
  final String translated;

  GrammarLesson({
    required this.level,
    required this.title,
    required this.description,
    required this.example,
    required this.translated,
  });
}
