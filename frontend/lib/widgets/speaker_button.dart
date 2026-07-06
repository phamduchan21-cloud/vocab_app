import 'dart:async';
import 'package:flutter/material.dart';
import '../app.dart';
import '../services/tts_service.dart';

/// A small speaker icon button that reads the given [text] aloud.
class SpeakerButton extends StatefulWidget {
  final String text;
  final double size;
  final Color? color;

  const SpeakerButton({
    super.key,
    required this.text,
    this.size = 28,
    this.color,
  });

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends State<SpeakerButton>
    with TickerProviderStateMixin {
  AnimationController? _animController;
  Animation<double>? _pulseAnim;
  bool _isSpeaking = false;
  Timer? _stopTimer;

  @override
  void dispose() {
    _stopTimer?.cancel();
    _animController?.dispose();
    super.dispose();
  }

  void _speak() {
    if (_isSpeaking) {
      TtsService.stop();
      _stopAnimation();
      return;
    }

    // Dispose old controller before creating new one
    _animController?.dispose();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController!, curve: Curves.easeInOut),
    );
    _animController!.repeat(reverse: true);
    setState(() => _isSpeaking = true);

    TtsService.speak(widget.text);

    // Auto-stop after estimated duration
    _stopTimer?.cancel();
    _stopTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _stopAnimation();
    });
  }

  void _stopAnimation() {
    _stopTimer?.cancel();
    _animController?.stop();
    _animController?.reset();
    setState(() => _isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!TtsService.isSupported) return const SizedBox.shrink();

    final color = widget.color ?? AppColors.blue;

    return AnimatedBuilder(
      animation: _pulseAnim ?? kAlwaysCompleteAnimation,
      builder: (context, child) => Transform.scale(
        scale: _isSpeaking ? (_pulseAnim?.value ?? 1.0) : 1.0,
        child: child,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: IconButton(
          onPressed: _speak,
          icon: Icon(
            _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
            size: widget.size * 0.7,
            color: _isSpeaking ? color : color.withValues(alpha: 0.7),
          ),
          padding: EdgeInsets.zero,
          tooltip: _isSpeaking ? 'Đang phát...' : 'Nghe phát âm',
          splashRadius: widget.size * 0.5,
        ),
      ),
    );
  }
}
