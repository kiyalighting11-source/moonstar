// lib/core/theme/animated_gradient_background.dart

import 'package:flutter/material.dart';

import 'app_theme.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    // 🎨 Palettes
    final lightGradient = [
      const Color(0xFF6A1B9A),
      const Color(0xFF9C4DCC),
      const Color(0xFF00ACC1),
      const Color(0xFF7E57C2),
      const Color(0xFF6A1B9A),
    ];

    // ⭐ Dark — ألوان أعمق وأغنى
    final darkGradient = [
      const Color(0xFF0A0E14), // أسود عميق
      const Color(0xFF1A0B2E), // بنفسجي داكن
      const Color(0xFF0D2530), // سماوي داكن
      const Color(0xFF1A0B2E), // بنفسجي داكن
      const Color(0xFF0A0E14), // أسود عميق
    ];

    final colors = isDark ? darkGradient : lightGradient;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1) Gradient الأساسي
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                  stops: _buildStops(t, colors.length),
                ),
              ),
            ),

            // 2) Blob بنفسجي (يمين فوق)
            Positioned(
              top: -80 + (t * 60),
              right: -80 + (t * 80),
              child: _buildBlob(
                size: 320,
                color: isDark
                    ? const Color(0xFF6A1B9A).withValues(alpha: 0.35)
                    : const Color(0xFF9C4DCC).withValues(alpha: 0.35),
              ),
            ),

            // 3) Blob سماوي (يسار تحت)
            Positioned(
              bottom: -100 + ((1 - t) * 70),
              left: -100 + ((1 - t) * 90),
              child: _buildBlob(
                size: 400,
                color: isDark
                    ? const Color(0xFF00ACC1).withValues(alpha: 0.22)
                    : const Color(0xFF00ACC1).withValues(alpha: 0.25),
              ),
            ),

            // 4) Blob بنفسجي فاتح (وسط)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4 +
                  (t * 100) -
                  ((t * t) * 100),
              left: MediaQuery.of(context).size.width * 0.5 +
                  ((1 - t) * 80) -
                  100,
              child: _buildBlob(
                size: 260,
                color: isDark
                    ? const Color(0xFF9C4DCC).withValues(alpha: 0.18)
                    : const Color(0xFF7E57C2).withValues(alpha: 0.2),
              ),
            ),

            // 5) Overlay خفيف
            Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
            ),

            // 6) المحتوى
            widget.child,
          ],
        );
      },
    );
  }

  List<double> _buildStops(double t, int count) {
    final stops = <double>[];
    for (int i = 0; i < count; i++) {
      final base = i / (count - 1);
      final shift = ((t - 0.5) * 0.2);
      stops.add((base + shift).clamp(0.0, 1.0));
    }
    return stops;
  }

  Widget _buildBlob({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
