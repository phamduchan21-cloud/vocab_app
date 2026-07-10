import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AIService(context.read<ApiService>());
    _messages.add(_ChatMessage(
      text: 'Chào bạn! 👋 Tôi là Meu, trợ lý AI học tiếng Anh.\n\n'
          'Bạn có thể hỏi tôi về:\n'
          '• 📖 Giải thích từ vựng\n'
          '• 📝 Ví dụ câu\n'
          '• 🔄 Phân biệt từ dễ nhầm\n'
          '• 📚 Ngữ pháp cơ bản\n\n'
          'Bạn muốn học gì hôm nay? 🎯',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();
    _messageController.clear();

    try {
      final result = await _aiService.chat(message: text.trim());
      final reply = result['reply'] as String? ?? 'Xin lỗi, tôi chưa có câu trả lời.';
      final suggestions = (result['suggestions'] as List?)?.map((s) => s.toString()).toList() ?? <String>[];
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false, suggestions: suggestions));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: '❌ Xin lỗi, AI hiện không khả dụng. Vui lòng thử lại sau.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          // Avatar with online status (Stitch style)
          Stack(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Meu - Trợ lý AI', style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.ink)),
            Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
              const SizedBox(width: 4),
              Text(_isLoading ? 'Đang suy nghĩ...' : 'Online',
                  style: GoogleFonts.nunito(fontSize: 11, color: _isLoading ? AppColors.warning : AppColors.success)),
            ]),
          ]),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/'),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: Column(children: [
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _MessageBubble(message: msg, onSuggestionTap: (s) => _sendMessage(s));
                  },
                ),
        ),
        // Loading
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Text('Meu đang trả lời...', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.inkSoft)),
            ]),
          ),
        // Input — Stitch glassmorphism
        _buildInput(),
      ]),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Suggestion chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              _buildSuggestionChip('Giải thích thêm'),
              const SizedBox(width: 6),
              _buildSuggestionChip('Cho ví dụ'),
              const SizedBox(width: 6),
              _buildSuggestionChip('Từ tiếp theo'),
            ]),
          ),
          // Input bar
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Hỏi Meu về từ vựng...',
                        hintStyle: GoogleFonts.nunito(color: AppColors.textHint, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.ink),
                      maxLines: 3, minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) => _sendMessage(v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, size: 20, color: AppColors.inkSoft),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.rose,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => _sendMessage(_messageController.text),
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 44, height: 44,
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () => _sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(label, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.onSurfaceVariant)),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String> suggestions;
  _ChatMessage({required this.text, required this.isUser, this.suggestions = const []});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final ValueChanged<String> onSuggestionTap;
  const _MessageBubble({required this.message, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        // Date divider (only for first message or AI welcome)
        Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bot avatar
            if (!message.isUser) ...[
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.rose.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: message.isUser ? AppColors.rose : AppColors.surface,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight: message.isUser ? const Radius.circular(4) : null,
                      bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                    ),
                    border: message.isUser ? null : Border.all(color: AppColors.surfaceContainerHighest),
                    boxShadow: message.isUser ? null : [BoxShadow(color: AppColors.ink.withValues(alpha: 0.04), blurRadius: 8)],
                  ),
                  child: Text(message.text, style: GoogleFonts.nunito(
                    fontSize: 14, height: 1.5,
                    color: message.isUser ? Colors.white : AppColors.ink,
                  )),
                ),
                const SizedBox(height: 4),
                // Timestamp
                Text('12:00', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.inkSoft)),
              ]),
            ),
            if (message.isUser) const SizedBox(width: 8),
          ],
        ),
        // Suggestion chips
        if (!message.isUser && message.suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Wrap(spacing: 8, runSpacing: 6, children: message.suggestions.map((s) => InkWell(
              onTap: () => onSuggestionTap(s),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(s, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.rose, fontWeight: FontWeight.w500)),
              ),
            )).toList()),
          ),
        ],
      ]),
    );
  }
}
