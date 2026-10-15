// lib/core/widgets/scroll_animations.dart

import 'package:flutter/material.dart';

// =====================================================
// Fade In + Slide Up (لما العنصر يدخل الشاشة)
// =====================================================
class FadeInOnScroll extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;

  const FadeInOnScroll({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 50),
  });

  @override
  State<FadeInOnScroll> createState() => _FadeInOnScrollState();
}

class _FadeInOnScrollState extends State<FadeInOnScroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    if (_hasAnimated) return;
    _hasAnimated = true;
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ScrollDetector(
      onVisible: _triggerAnimation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: _slide.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// =====================================================
// Scale In (لما العنصر يدخل الشاشة)
// =====================================================
class ScaleInOnScroll extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const ScaleInOnScroll({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.delay = Duration.zero,
  });

  @override
  State<ScaleInOnScroll> createState() => _ScaleInOnScrollState();
}

class _ScaleInOnScrollState extends State<ScaleInOnScroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    if (_hasAnimated) return;
    _hasAnimated = true;
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ScrollDetector(
      onVisible: _triggerAnimation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// =====================================================
// Count Up (عد الأرقام من 0)
// =====================================================
class CountUpOnScroll extends StatefulWidget {
  final int end;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  const CountUpOnScroll({
    super.key,
    required this.end,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<CountUpOnScroll> createState() => _CountUpOnScrollState();
}

class _CountUpOnScrollState extends State<CountUpOnScroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.end.toDouble(),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    if (_hasAnimated) return;
    _hasAnimated = true;
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return _ScrollDetector(
      onVisible: _triggerAnimation,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final value = _animation.value.toInt();
          return Text(
            '${widget.prefix}$value${widget.suffix}',
            style: widget.style,
          );
        },
      ),
    );
  }
}

// =====================================================
// Helper: يكتشف لما الـ widget يدخل الشاشة
// =====================================================
class _ScrollDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onVisible;

  const _ScrollDetector({
    required this.child,
    required this.onVisible,
  });

  @override
  State<_ScrollDetector> createState() => _ScrollDetectorState();
}

class _ScrollDetectorState extends State<_ScrollDetector> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    final context = _key.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    // لو العنصر داخل الشاشة (أو قريب منها)
    if (position.dy < screenHeight * 0.85) {
      widget.onVisible();
    } else {
      // نستنى ونشوف تاني
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _check();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}
