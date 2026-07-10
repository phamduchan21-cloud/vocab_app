import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/vocabulary_provider.dart';
import '../models/vocabulary.dart';
import '../widgets/vocab_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/app_drawer.dart';

class VocabularyListScreen extends StatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocabularyProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, Vocabulary vocab) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Xoá từ vựng',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        content: Text(
          'Bạn có chắc muốn xoá từ "${vocab.word}"?',
          style: GoogleFonts.nunito(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Huỷ', style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<VocabularyProvider>().delete(vocab.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Xoá', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocabProvider = context.watch<VocabularyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ vựng'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vocabulary/new'),
        backgroundColor: AppColors.rose,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search + Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm từ vựng...',
                      hintStyle: GoogleFonts.nunito(color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textHint),
                              onPressed: () {
                                _searchController.clear();
                                vocabProvider.setSearch('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      vocabProvider.setSearch(value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('Tất cả', vocabProvider.selectedTopic == 'all', () => vocabProvider.setTopic('all')),
                      ...vocabProvider.topics.map((topic) => _buildFilterChip(topic, vocabProvider.selectedTopic == topic, () => vocabProvider.setTopic(topic))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: _buildBody(context, vocabProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.primaryGradient : null,
            color: selected ? null : AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label == 'all' ? 'Tất cả' : label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VocabularyProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const SkeletonLoading(type: SkeletonType.list, count: 6);
    }

    if (provider.errorMessage != null && provider.items.isEmpty) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchAll(),
      );
    }

    final displayItems = provider.filtered;

    if (displayItems.isEmpty) {
      if (provider.searchQuery.isNotEmpty || provider.selectedTopic != 'all') {
        return EmptyStateWidget(
          icon: Icons.search_off,
          title: 'Không tìm thấy từ vựng phù hợp',
          subtitle: 'Thử thay đổi từ khoá hoặc chủ đề',
          showCat: true,
        );
      }
      return EmptyStateWidget(
        title: 'Chưa có từ vựng nào',
        subtitle: 'Thêm từ đầu tiên để bắt đầu học nhé!',
        action: 'Thêm từ đầu tiên',
        onAction: () => context.push('/vocabulary/new'),
        showCat: true,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchAll(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 80),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final vocab = displayItems[index];
          return VocabCard(
            vocab: vocab,
            onEdit: () => context.push('/vocabulary/${vocab.id}/edit'),
            onDelete: () => _confirmDelete(context, vocab),
          );
        },
      ),
    );
  }
}
