import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cat_widget.dart';

class SolAssistantOverlay extends StatefulWidget {
  const SolAssistantOverlay({
    super.key,
    required this.child,
    required this.routeInformation,
    required this.onOpenChat,
  });

  final Widget child;
  final ValueListenable<RouteInformation> routeInformation;
  final Future<void> Function() onOpenChat;

  @override
  State<SolAssistantOverlay> createState() => _SolAssistantOverlayState();
}

class _SolAssistantOverlayState extends State<SolAssistantOverlay>
    with SingleTickerProviderStateMixin {
  static const _mascotSize = 78.0;
  static const _pageMargin = 14.0;
  static const _hiddenRoutes = {
    '/splash',
    '/login',
    '/register',
    '/onboarding',
    '/setup',
    '/ai-chat',
  };

  late final AnimationController _orbitController;
  Offset? _position;
  bool _showHint = true;
  bool _hovering = false;
  bool _dragging = false;
  bool _chatOpen = false;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    widget.routeInformation.addListener(_onRouteChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        media?.disableAnimations == true || media?.accessibleNavigation == true;
    if (reduceMotion) {
      _orbitController.stop();
      _orbitController.value = 0;
    } else if (!_orbitController.isAnimating) {
      _orbitController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SolAssistantOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeInformation != widget.routeInformation) {
      oldWidget.routeInformation.removeListener(_onRouteChanged);
      widget.routeInformation.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    widget.routeInformation.removeListener(_onRouteChanged);
    _orbitController.dispose();
    super.dispose();
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  bool _isVisible(String path) {
    if (_hiddenRoutes.contains(path)) return false;
    if (path.startsWith('/quiz/play')) return false;
    if (path.startsWith('/mock-test/play')) return false;
    return true;
  }

  Offset _clampPosition(Offset value, Size size, EdgeInsets padding) {
    final minX = padding.left + _pageMargin;
    final maxX = math.max(minX, size.width - _mascotSize - _pageMargin);
    final minY = padding.top + _pageMargin;
    final maxY = math.max(
      minY,
      size.height - padding.bottom - _mascotSize - 82,
    );
    return Offset(value.dx.clamp(minX, maxX), value.dy.clamp(minY, maxY));
  }

  void _moveMascot(DragUpdateDetails details, Size size, EdgeInsets padding) {
    setState(() {
      final current = _position ?? Offset.zero;
      _position = _clampPosition(current + details.delta, size, padding);
    });
  }

  Future<void> _openChat() async {
    if (_dragging || _chatOpen) return;
    setState(() => _chatOpen = true);
    try {
      await widget.onOpenChat();
    } finally {
      if (mounted) setState(() => _chatOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.routeInformation.value.uri.path;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final padding = MediaQuery.paddingOf(context);
        final fallback = Offset(
          size.width - _mascotSize - 20,
          size.height - padding.bottom - _mascotSize - 105,
        );
        final position = _clampPosition(_position ?? fallback, size, padding);
        final bubbleWidth = math.min(330.0, size.width - 28).toDouble();
        final bubbleLeft = (position.dx + _mascotSize - bubbleWidth)
            .clamp(
              _pageMargin,
              math.max(_pageMargin, size.width - bubbleWidth - _pageMargin),
            )
            .toDouble();
        final showBelow = position.dy < padding.top + 135;
        final bubbleTop = showBelow
            ? position.dy + _mascotSize + 10
            : position.dy - 116;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (!_chatOpen && _isVisible(path)) ...[
              if (_showHint)
                Positioned(
                  left: bubbleLeft,
                  top: bubbleTop,
                  width: bubbleWidth,
                  child: _AssistantHint(
                    pointsDown: !showBelow,
                    onClose: () => setState(() => _showHint = false),
                    onOpen: _openChat,
                  ),
                ),
              Positioned(
                left: position.dx,
                top: position.dy,
                width: _mascotSize,
                height: _mascotSize,
                child: MouseRegion(
                  cursor: _dragging
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab,
                  onEnter: (_) => setState(() => _hovering = true),
                  onExit: (_) => setState(() => _hovering = false),
                  child: Semantics(
                    button: true,
                    label:
                        'Trợ lý AI Sol. Kéo để di chuyển, chạm để trò chuyện.',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openChat,
                      onPanStart: (_) => setState(() => _dragging = true),
                      onPanUpdate: (details) =>
                          _moveMascot(details, size, padding),
                      onPanEnd: (_) => setState(() => _dragging = false),
                      onPanCancel: () => setState(() => _dragging = false),
                      child: AnimatedScale(
                        scale: _hovering || _dragging ? 1.08 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: RepaintBoundary(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _orbitController,
                                builder: (context, _) => CustomPaint(
                                  size: const Size.square(_mascotSize),
                                  painter: _SolOrbitPainter(
                                    progress: _orbitController.value,
                                  ),
                                ),
                              ),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xF21A2745),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF55D9EA,
                                    ).withValues(alpha: 0.50),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF55D9EA,
                                      ).withValues(alpha: 0.20),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                                child: const CatWidget(
                                  size: 58,
                                  expression: CatExpression.talking,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 3,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFC857),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 11,
                                    color: Color(0xFF091326),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AssistantHint extends StatelessWidget {
  const _AssistantHint({
    required this.pointsDown,
    required this.onClose,
    required this.onOpen,
  });

  final bool pointsDown;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(17),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(18, 15, 42, 15),
              decoration: BoxDecoration(
                color: const Color(0xF51B2742),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFF55D9EA).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đang vướng ở đâu?',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFFF4F7FF),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Sol có thể giải thích từ, cho ví dụ và luyện cùng bạn. Chạm để trò chuyện.',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFFB3BED9),
                      height: 1.35,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 7,
            top: 7,
            child: IconButton(
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
              iconSize: 17,
              color: const Color(0xFFB3BED9),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            right: 29,
            top: pointsDown ? null : -6,
            bottom: pointsDown ? -6 : null,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2742),
                  border: Border(
                    right: BorderSide(
                      color: const Color(0xFF55D9EA).withValues(alpha: 0.18),
                    ),
                    bottom: BorderSide(
                      color: const Color(0xFF55D9EA).withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolOrbitPainter extends CustomPainter {
  const _SolOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final orbit = Rect.fromCenter(
      center: center,
      width: size.width - 5,
      height: size.height * 0.54,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.30);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawOval(
      orbit,
      Paint()
        ..color = const Color(0xFF55D9EA).withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final angle = progress * math.pi * 2;
    final satellite = Offset(
      center.dx + math.cos(angle) * orbit.width / 2,
      center.dy + math.sin(angle) * orbit.height / 2,
    );
    canvas.drawCircle(satellite, 3.8, Paint()..color = const Color(0xFFFFC857));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SolOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
