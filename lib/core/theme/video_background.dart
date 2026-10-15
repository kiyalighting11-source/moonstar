// lib/core/theme/video_background.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'app_theme.dart';

/// Background فيديو — مع Overlay عشان النص يبان
class VideoBackground extends StatefulWidget {
  final Widget child;
  final String assetPath;
  final bool showOverlay;
  final double overlayOpacity;

  const VideoBackground({
    super.key,
    required this.child,
    required this.assetPath,
    this.showOverlay = true,
    this.overlayOpacity = 0.6,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.assetPath);

      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      await _controller.play();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('⚠️ Video failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;
    if (state == AppLifecycleState.paused) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    // لون احتياطي لو الفيديو فشل
    final fallbackGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF0F1115), const Color(0xFF38006B)]
          : [const Color(0xFFF0F2F8), const Color(0xFF9C4DCC)],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) الفيديو
        if (_isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(gradient: fallbackGradient),
            child: _hasError
                ? const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white24,
                      size: 60,
                    ),
                  )
                : null,
          ),

        // 2) Overlay (عشان النص يبان)
        if (widget.showOverlay)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: widget.overlayOpacity),
                        Colors.black
                            .withValues(alpha: widget.overlayOpacity * 0.7),
                        Colors.black.withValues(alpha: widget.overlayOpacity),
                      ]
                    : [
                        Colors.black
                            .withValues(alpha: widget.overlayOpacity * 0.5),
                        Colors.black
                            .withValues(alpha: widget.overlayOpacity * 0.3),
                        Colors.black
                            .withValues(alpha: widget.overlayOpacity * 0.5),
                      ],
              ),
            ),
          ),

        // 3) المحتوى
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
