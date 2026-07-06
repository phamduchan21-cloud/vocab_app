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
          'Khó từ vựng',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
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
                  hintText: 'Tim chủ de từ vựng...',
                  hintStyle: GoogleFonts.workSans(color: AppColors.textHint),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textHint),
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
              style: GoogleFonts.workSans(
                fontSize: 16,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
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
    return Material(
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
                  color: AppColors.blueBg,
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
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count từ',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
