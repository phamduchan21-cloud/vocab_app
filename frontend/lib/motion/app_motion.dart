import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum MotionPageKind { mainTab, detail, auth, modal, result }

class AppMotion {
  const AppMotion._();

  static const springCurve = Cubic(0.34, 1.32, 0.64, 1);
  static const standardCurve = Cubic(0.22, 1, 0.36, 1);

  static bool reduced(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  static Page<T> page<T>({
    required GoRouterState state,
    required Widget child,
    required MotionPageKind kind,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: _duration(kind),
      reverseTransitionDuration: _reverseDuration(kind),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AppMotionTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          kind: kind,
          child: child,
        );
      },
    );
  }

  static Duration _duration(MotionPageKind kind) {
    return switch (kind) {
      MotionPageKind.mainTab => const Duration(milliseconds: 260),
      MotionPageKind.detail => const Duration(milliseconds: 330),
      MotionPageKind.auth => const Duration(milliseconds: 320),
      MotionPageKind.modal => const Duration(milliseconds: 360),
      MotionPageKind.result => const Duration(milliseconds: 420),
    };
  }

  static Duration _reverseDuration(MotionPageKind kind) {
    return switch (kind) {
      MotionPageKind.mainTab => const Duration(milliseconds: 220),
      MotionPageKind.detail => const Duration(milliseconds: 280),
      MotionPageKind.auth => const Duration(milliseconds: 260),
      MotionPageKind.modal => const Duration(milliseconds: 300),
      MotionPageKind.result => const Duration(milliseconds: 320),
    };
  }
}

class AppMotionTransition extends StatelessWidget {
  const AppMotionTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.kind,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final MotionPageKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;

    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppMotion.standardCurve,
      reverseCurve: Curves.easeInCubic,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    return switch (kind) {
      MotionPageKind.mainTab => _mainTab(incoming, outgoing),
      MotionPageKind.detail => _detail(incoming, outgoing),
      MotionPageKind.auth => _auth(incoming, outgoing),
      MotionPageKind.modal => _modal(incoming, outgoing),
      MotionPageKind.result => _result(incoming, outgoing),
    };
  }

  Widget _mainTab(Animation<double> incoming, Animation<double> outgoing) {
    final exitScale = Tween<double>(begin: 1, end: 0.992).animate(outgoing);
    final exitOpacity = Tween<double>(begin: 1, end: 0.90).animate(outgoing);
    final enterScale = Tween<double>(begin: 0.985, end: 1).animate(incoming);

    return FadeTransition(
      opacity: incoming,
      child: ScaleTransition(
        scale: enterScale,
        child: FadeTransition(
          opacity: exitOpacity,
          child: ScaleTransition(scale: exitScale, child: child),
        ),
      ),
    );
  }

  Widget _detail(Animation<double> incoming, Animation<double> outgoing) {
    final enterOffset = Tween<Offset>(
      begin: const Offset(0.055, 0),
      end: Offset.zero,
    ).animate(incoming);
    final exitOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.025, 0),
    ).animate(outgoing);
    final exitOpacity = Tween<double>(begin: 1, end: 0.92).animate(outgoing);

    return SlideTransition(
      position: enterOffset,
      child: FadeTransition(
        opacity: incoming,
        child: SlideTransition(
          position: exitOffset,
          child: FadeTransition(opacity: exitOpacity, child: child),
        ),
      ),
    );
  }

  Widget _auth(Animation<double> incoming, Animation<double> outgoing) {
    final enterOffset = Tween<Offset>(
      begin: const Offset(0.045, 0.012),
      end: Offset.zero,
    ).animate(incoming);
    final exitOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.02, 0),
    ).animate(outgoing);

    return SlideTransition(
      position: enterOffset,
      child: FadeTransition(
        opacity: incoming,
        child: SlideTransition(position: exitOffset, child: child),
      ),
    );
  }

  Widget _modal(Animation<double> incoming, Animation<double> outgoing) {
    final enterOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(incoming);
    final exitScale = Tween<double>(begin: 1, end: 0.99).animate(outgoing);

    return SlideTransition(
      position: enterOffset,
      child: FadeTransition(
        opacity: incoming,
        child: ScaleTransition(scale: exitScale, child: child),
      ),
    );
  }

  Widget _result(Animation<double> incoming, Animation<double> outgoing) {
    final enterScale = Tween<double>(
      begin: 0.965,
      end: 1,
    ).animate(CurvedAnimation(parent: animation, curve: AppMotion.springCurve));
    final enterOffset = Tween<Offset>(
      begin: const Offset(0, 0.018),
      end: Offset.zero,
    ).animate(incoming);
    final exitOpacity = Tween<double>(begin: 1, end: 0.88).animate(outgoing);

    return FadeTransition(
      opacity: incoming,
      child: SlideTransition(
        position: enterOffset,
        child: ScaleTransition(
          scale: enterScale,
          child: FadeTransition(opacity: exitOpacity, child: child),
        ),
      ),
    );
  }
}

class AirmailStampReveal extends StatefulWidget {
  const AirmailStampReveal({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 170),
  });

  final Widget child;
  final Duration delay;

  @override
  State<AirmailStampReveal> createState() => _AirmailStampRevealState();
}

class _AirmailStampRevealState extends State<AirmailStampReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scale = Tween<double>(begin: 0.84, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.springCurve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
