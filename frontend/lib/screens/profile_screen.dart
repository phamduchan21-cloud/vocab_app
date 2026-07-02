import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _achievements = [];
  Map<String, dynamic>? _assessment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/dashboard')),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/gamification/achievements')),
      ]);
      if (results.every((r) => r.statusCode == 200)) {
        setState(() {
          _stats = json.decode(results[0].body);
          final achList = json.decode(results[1].body);
          _achievements = List<Map<String, dynamic>>.from(achList is List ? achList : []);
          _assessment = {
            'listening': 80, 'reading': 65, 'writing': 55, 'speaking': 40,
          };
          _isLoading = false;
        });
      } else { _mockData(); }
    } catch (_) { _mockData(); }
  }

  void _mockData() {
    setState(() {
      _isLoading = false;
      _stats = {'streak': 12, 'xp': 12450, 'gems': 2300, 'level': 15, 'level_title': '🌳 Cây lớn', 'vocab_count': 230, 'quiz_count': 45, 'correct_answers': 850, 'accuracy_rate': 70.8};
      _achievements = [
        {'achievement_key': 'streak_7', 'title': '🔥 7 Days Strong', 'icon': 'fire', 'unlocked_at': '2026-06-25'},
        {'achievement_key': 'word_50', 'title': '📚 50 Words', 'icon': 'books', 'unlocked_at': '2026-06-20'},
        {'achievement_key': 'first_quiz', 'title': '🎯 First Quiz', 'icon': 'star', 'unlocked_at': '2026-06-15'},
        {'achievement_key': 'perfect_week', 'title': '💪 Perfect Week', 'icon': 'fire'},
      ];
      _assessment = {'listening': 80, 'reading': 65, 'writing': 55, 'speaking': 40};
    });
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.accent3;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.accent1;
    return AppColors.accent2;
  }

  String _levelFromScore(double score) {
    if (score >= 80) return 'B2';
    if (score >= 65) return 'B1';
    if (score >= 50) return 'A2';
    return 'A1';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?.email ?? 'Người dùng';
    final username = (auth.user?.userMetadata?['username'] as String?) ?? email.split('@').first;

    return Scaffold(
      appBar: AppBar(
        title: Text('👤 Hồ sơ', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
        foregroundColor: const Color(0xFF8B5CF6),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(username, email),
                  const SizedBox(height: 20),
                  _buildAssessment(),
                  const SizedBox(height: 20),
                  _buildAchievements(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 20),
                  _buildLogout(context),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String username, String email) {
    final s = _stats;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(height: 12),
          Text(username, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(email, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 16),
          if (s != null) Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStat('🏆', '${s['level']}', s['level_title'] ?? ''),
              _headerStat('🔥', '${s['streak']}', 'Ngày'),
              _headerStat('⭐', '${s['xp']}', 'XP'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      Text(value, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: GoogleFonts.nunito(fontSize: 11, color: Colors.white70)),
    ]);
  }

  Widget _buildAssessment() {
    final a = _assessment;
    if (a == null) return const SizedBox.shrink();
    final skills = [
      {'key': 'listening', 'label': '🎧 Nghe', 'score': (a['listening'] ?? 0).toDouble()},
      {'key': 'reading', 'label': '📖 Đọc', 'score': (a['reading'] ?? 0).toDouble()},
      {'key': 'writing', 'label': '✍️ Viết', 'score': (a['writing'] ?? 0).toDouble()},
      {'key': 'speaking', 'label': '🗣️ Nói', 'score': (a['speaking'] ?? 0).toDouble()},
    ];
    final total = skills.fold(0.0, (sum, s) => sum + s['score']) / skills.length;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📊', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Đánh giá năng lực', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          ...skills.map((s) {
            final score = s['score'] as double;
            final color = _scoreColor(score);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 80, child: Text('${s['label']}', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: score / 100, backgroundColor: AppColors.catLight, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 60, child: Text('${score.toStringAsFixed(0)}% - ${_levelFromScore(score)}', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
              ]),
            );
          }),
          const SizedBox(height: 8),
          Center(child: Text('📈 Tổng: ${total.toStringAsFixed(0)}% — ${_levelFromScore(total)}', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Thành tựu (${_achievements.length})', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _achievements.map((a) {
              final unlocked = a['unlocked_at'] != null;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: unlocked ? AppColors.catLight : AppColors.catLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: unlocked ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(unlocked ? '✅' : '🔒', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(a['title'] ?? '', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: unlocked ? AppColors.textPrimary : AppColors.textHint)),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final s = _stats;
    if (s == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📈', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Thống kê', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          _statRow('📚 Từ vựng', '${s['vocab_count']}', 'từ'),
          _statRow('📝 Bài học', '${s['quiz_count']}', 'bài'),
          _statRow('✅ Câu đúng', '${s['correct_answers']}', 'câu'),
          _statRow('🔥 Streak', '${s['streak']}', 'ngày'),
          _statRow('💎 Gems', '${s['gems']}', 'gems'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary)),
        Text('$value $unit', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _buildLogout(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<AuthProvider>().logout();
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text('Đăng xuất', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent2,
          side: const BorderSide(color: AppColors.accent2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
