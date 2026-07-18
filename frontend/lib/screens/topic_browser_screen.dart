import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/topic_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

class TopicBrowserScreen extends StatefulWidget {
  const TopicBrowserScreen({super.key});

  @override
  State<TopicBrowserScreen> createState() => _TopicBrowserScreenState();
}

class _TopicBrowserScreenState extends State<TopicBrowserScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopicProvider>().loadTopics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicProv = context.watch<TopicProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Khám phá chủ đề',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Học theo ngữ cảnh',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chọn một chủ đề gần gũi để ghi nhớ tự nhiên hơn.',
                      style: GoogleFonts.nunito(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 18),
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
                          hintText: 'Tìm chủ đề từ vựng...',
                          hintStyle: GoogleFonts.nunito(
                            color: AppColors.textHint,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textHint,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppColors.textHint,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    topicProv.setSearch('');
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          topicProv.setSearch(value);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Body
          Expanded(child: _buildBody(context, topicProv)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TopicProvider provider) {
    if (provider.isLoading && provider.topics.isEmpty) {
      return const SkeletonLoading(type: SkeletonType.grid, count: 6);
    }

    if (provider.errorMessage != null && provider.topics.isEmpty) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.loadTopics(),
      );
    }

    final displayTopics = provider.filteredTopics;

    if (displayTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.inkSoft),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy chủ đề phù hợp',
              style: GoogleFonts.nunito(fontSize: 16, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                provider.setSearch('');
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Xóa tìm kiếm'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 540
                ? 2
                : constraints.maxWidth < 820
                ? 3
                : 4;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 2 ? 0.95 : 1.05,
              ),
              itemCount: displayTopics.length,
              itemBuilder: (context, index) {
                final topic = displayTopics[index];
                return _TopicCard(
                  icon: topic.icon,
                  title: topic.title,
                  count: topic.count,
                  onTap: () => context.push('/topics/${topic.lessonId}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  const _TopicCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $count từ',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count từ',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
