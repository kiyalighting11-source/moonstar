// lib/core/theme/animated_background.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Background ديناميكي — blobs متحركة + Gradient
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool showBlobs;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.showBlobs = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    // 🎨 ألوان الـ blobs
    final blobColors = isDark
        ? [
            const Color(0xFF6A1B9A).withValues(alpha: 0.5),
            const Color(0xFF00ACC1).withValues(alpha: 0.4),
            const Color(0xFFFFB300).withValues(alpha: 0.25),
          ]
        : [
            const Color(0xFF9C4DCC).withValues(alpha: 0.35),
            const Color(0xFF00ACC1).withValues(alpha: 0.25),
            const Color(0xFFFFB300).withValues(alpha: 0.2),
          ];

    // ⭐ الخلفية حسب الوضع (مش شفافة)
    final backgroundColor =
        isDark ? const Color(0xFF0F1115) : const Color(0xFFF0F2F8);

    return Container(
      // ⭐ لون أساسي كـ fallback
      color: backgroundColor,
      child: Stack(
        children: [
          // Gradient layer
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0F1115),
                          const Color(0xFF1A1030),
                          const Color(0xFF0F1115),
                        ]
                      : [
                          const Color(0xFFF0F2F8),
                          const Color(0xFFF8F0FF),
                          const Color(0xFFF0F2F8),
                        ],
                ),
              ),
            ),
          ),

          // الـ blobs المتحركة
          if (widget.showBlobs)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _BlobsPainter(
                      progress: _controller.value,
                      colors: blobColors,
                    ),
                  );
                },
              ),
            ),

          // المحتوى
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _BlobsPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _BlobsPainter({
    required this.progress,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;

    // Blob 1 (يسار فوق)
    _drawBlob(
      canvas,
      center: Offset(
        size.width * (0.2 + 0.1 * math.sin(t)),
        size.height * (0.15 + 0.05 * math.cos(t)),
      ),
      radius: size.width * 0.55,
      color: colors[0],
    );

    // Blob 2 (يمين تحت)
    _drawBlob(
      canvas,
      center: Offset(
        size.width * (0.85 + 0.1 * math.cos(t * 1.3)),
        size.height * (0.8 + 0.05 * math.sin(t * 1.3)),
      ),
      radius: size.width * 0.6,
      color: colors[1],
    );

    // Blob 3 (وسط)
    _drawBlob(
      canvas,
      center: Offset(
        size.width * (0.5 + 0.15 * math.sin(t * 0.7)),
        size.height * (0.5 + 0.1 * math.cos(t * 0.7)),
      ),
      radius: size.width * 0.45,
      color: colors[2],
    );
  }

  void _drawBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
