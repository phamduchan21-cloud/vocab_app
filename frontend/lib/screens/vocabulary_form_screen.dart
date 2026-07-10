import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/loading_widget.dart';

class VocabularyFormScreen extends StatefulWidget {
  final String? id;

  const VocabularyFormScreen({super.key, this.id});

  @override
  State<VocabularyFormScreen> createState() => _VocabularyFormScreenState();
}

class _VocabularyFormScreenState extends State<VocabularyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();
  String _selectedTopic = 'general';
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _showCustomTopic = false;
  final _customTopicController = TextEditingController();

  final _topics = ['general', 'giao tiếp', 'du lịch', 'công việc', 'học tập'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.id != null;
    if (_isEditMode) {
      _loadVocabulary();
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _customTopicController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<VocabularyProvider>();
      final vocab = provider.items.where((v) => v.id == widget.id).firstOrNull;
      if (vocab != null) {
        _wordController.text = vocab.word;
        _meaningController.text = vocab.meaning;
        _exampleController.text = vocab.example ?? '';
        _selectedTopic = vocab.topic;
        if (!_topics.contains(vocab.topic)) {
          _showCustomTopic = true;
          _customTopicController.text = vocab.topic;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể tải thông tin từ vựng'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final provider = context.read<VocabularyProvider>();
      final topic = _showCustomTopic
          ? _customTopicController.text.trim()
          : _selectedTopic;
      final data = {
        'word': _wordController.text.trim(),
        'meaning': _meaningController.text.trim(),
        'example': _exampleController.text.trim(),
        'topic': topic.isEmpty ? 'general' : topic,
      };

      if (_isEditMode) {
        await provider.update(widget.id!, data);
      } else {
        await provider.add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Cập nhật thành công' : 'Thêm từ vựng thành công'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.rose,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể lưu từ vựng. Vui lòng thử lại.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.accent2,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa từ' : 'Thêm từ mới'),
        centerTitle: true,
      ),
      body: _isLoading && _isEditMode && _wordController.text.isEmpty
          ? const SkeletonLoading(type: SkeletonType.form)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Word
                    TextFormField(
                      controller: _wordController,
                      decoration: const InputDecoration(
                        labelText: 'Từ vựng *',
                        hintText: 'Nhập từ cần học',
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập từ vựng' : null,
                    ),
                    const SizedBox(height: 16),
                    // Meaning
                    TextFormField(
                      controller: _meaningController,
                      decoration: const InputDecoration(
                        labelText: 'Nghĩa *',
                        hintText: 'Nhập nghĩa của từ',
                        prefixIcon: Icon(Icons.translate),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập nghĩa' : null,
                    ),
                    const SizedBox(height: 16),
                    // Example
                    TextFormField(
                      controller: _exampleController,
                      decoration: const InputDecoration(
                        labelText: 'Ví dụ',
                        hintText: 'Nhập câu ví dụ (không bắt buộc)',
                        prefixIcon: Icon(Icons.format_quote),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Topic selector
                    const Text('Chủ đề', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._topics.map((topic) => GestureDetector(
                          onTap: () => setState(() {
                            _showCustomTopic = false;
                            _selectedTopic = topic;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: !_showCustomTopic && _selectedTopic == topic
                                  ? AppTheme.primaryGradient
                                  : null,
                              color: !_showCustomTopic && _selectedTopic == topic
                                  ? null
                                  : AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              topic == 'general' ? 'Tổng hợp' : topic,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: !_showCustomTopic && _selectedTopic == topic
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: !_showCustomTopic && _selectedTopic == topic
                                    ? Colors.white
                                    : AppColors.inkSoft,
                              ),
                            ),
                          ),
                        )),
                        // Custom topic button
                        GestureDetector(
                          onTap: () => setState(() => _showCustomTopic = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _showCustomTopic ? AppColors.surfaceSubtle : AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: _showCustomTopic
                                  ? Border.all(color: AppColors.rose, width: 2)
                                  : null,
                            ),
                            child: Text(
                              _showCustomTopic ? 'Nhập chủ đề...' : 'Thêm mới +',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _showCustomTopic ? AppColors.rose : AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showCustomTopic) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customTopicController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập chủ đề của bạn',
                          prefixIcon: Icon(Icons.edit),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppTheme.primaryButtonGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.rose.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isEditMode ? 'Cập nhật' : 'Lưu từ vựng'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
