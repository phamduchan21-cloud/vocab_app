import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app.dart';
import '../config/api_config.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _lessons = [];
  List<dynamic> _grammarParts = [];
  List<dynamic> _textbooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/vocabularies/lessons')),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/vocabularies/grammar')),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/vocabularies/advanced')),
      ]);
      if (results.every((r) => r.statusCode == 200)) {
        setState(() {
          _lessons = json.decode(results[0].body)['lessons'];
          _grammarParts = json.decode(results[1].body)['parts'];
          _textbooks = json.decode(results[2].body)['textbooks'];
          _isLoading = false;
        });
      } else { _mockData(); }
    } catch (_) { _mockData(); }
  }

  void _mockData() {
    setState(() {
      _isLoading = false;
      _lessons = List.generate(15, (i) => {
        'id': i + 1, 'title': 'Bài ${i + 1}', 'icon': '📚', 'count': 30, 'description': 'Chủ đề bài ${i + 1}'
      });
      _grammarParts = [
        {'part': 1, 'title': 'Cơ bản', 'icon': '📗'},
        {'part': 2, 'title': 'Trung cấp', 'icon': '📘'},
        {'part': 3, 'title': 'Nâng cao', 'icon': '📕'},
      ];
      _textbooks = [
        {'id': 'cambridge', 'title': 'Cambridge', 'icon': '📘'},
        {'id': 'ielts', 'title': 'IELTS', 'icon': '🎯'},
        {'id': 'toeic', 'title': 'TOEIC', 'icon': '💼'},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📝 Học tập', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFFF472B6).withValues(alpha: 0.05),
        foregroundColor: const Color(0xFFF472B6),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF472B6),
          labelColor: const Color(0xFFF472B6),
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: '📖 Từ vựng'),
            Tab(text: '📐 Ngữ pháp'),
            Tab(text: '📚 Nâng cao'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVocabTab(),
                _buildGrammarTab(),
                _buildAdvancedTab(),
              ],
            ),
    );
  }

  // ─── TAB 1: TỪ VỰNG ────────────────────────────────────────

  Widget _buildVocabTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📚 15 bài từ vựng', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Học từ vựng theo chủ đề từ cơ bản đến nâng cao', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: _lessons.length,
            itemBuilder: (_, i) {
              final lesson = _lessons[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: const Color(0xFFF472B6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('${lesson['id']}', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFF472B6)))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson['title'] ?? '', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('${lesson['count'] ?? 0} từ', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textHint),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: NGỮ PHÁP ────────────────────────────────────────

  Widget _buildGrammarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📐 3 phần ngữ pháp', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Từ cơ bản đến nâng cao, 28 bài học', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...(_grammarParts.map((part) {
            final colors = [const Color(0xFF34D399), const Color(0xFFF472B6), const Color(0xFF8B5CF6)];
            final color = colors[(_grammarParts.indexOf(part) % colors.length)];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(part['icon'] ?? '📗', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Text('Phần ${part['part']}: ${part['title']}', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (part['lessons'] != null)
                    ...(part['lessons'] as List).map((l) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(child: Text(l, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)))),
                      ]),
                    )),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  // ─── TAB 3: NÂNG CAO ────────────────────────────────────────

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📚 Giáo trình nâng cao', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Luyện thi chứng chỉ quốc tế', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: _textbooks.length,
            itemBuilder: (_, i) {
              final book = _textbooks[i];
              final colors = [const Color(0xFF3B82F6), const Color(0xFFF472B6), const Color(0xFF34D399), const Color(0xFFFB923C), const Color(0xFF8B5CF6), const Color(0xFFEF4444), const Color(0xFF14B8A6)];
              final color = colors[i % colors.length];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(book['icon'] ?? '📘', style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(book['title'] ?? '', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
                    if (book['levels'] != null) Text('${book['levels']} cấp độ', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
