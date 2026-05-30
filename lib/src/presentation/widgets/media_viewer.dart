import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen media overlay with pinch-to-zoom, gallery swipe, and video playback.
///
/// Supports:
/// - Single image: one full-screen zoomable image
/// - Gallery: swipe left/right between multiple images
/// - Video: playback with play/pause, seek, auto-plays on open
/// - Image+video mixed: video as first page, then gallery images
/// - Pinch-to-zoom via [InteractiveViewer] (images only)
/// - Double-tap to zoom in/out (images only)
/// - Tap to toggle chrome (close button + page indicator)
class MediaViewer extends StatefulWidget {
  final List<String> imageUrls;
  final String? videoUrl;
  final int initialIndex;
  final bool isNsfw;
  final bool isSpoiler;
  final bool initiallyRevealed;

  const MediaViewer({
    super.key,
    required this.imageUrls,
    this.videoUrl,
    this.initialIndex = 0,
    this.isNsfw = false,
    this.isSpoiler = false,
    this.initiallyRevealed = false,
  });

  int get _pageCount => (videoUrl != null ? 1 : 0) + imageUrls.length;

  /// Push the viewer as a full-screen route.
  static Future<void> show(
    BuildContext context, {
    required List<String> imageUrls,
    String? videoUrl,
    int initialIndex = 0,
    bool isNsfw = false,
    bool isSpoiler = false,
    bool initiallyRevealed = false,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => MediaViewer(
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          initialIndex: initialIndex,
          isNsfw: isNsfw,
          isSpoiler: isSpoiler,
          initiallyRevealed: initiallyRevealed,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _chromeVisible = true;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget._pageCount - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _revealed = widget.initiallyRevealed || !widget.isNsfw && !widget.isSpoiler;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  void _reveal() => setState(() => _revealed = true);

  void _close() => Navigator.of(context).pop();

  bool get _hasVideo => widget.videoUrl != null;

  /// Returns the image page index (accounts for video page 0 offset).
  int _imagePageIndex(int pageIndex) => _hasVideo ? pageIndex - 1 : pageIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main media page view
          ImageFiltered(
            imageFilter: !_revealed
                ? ImageFilter.blur(sigmaX: 18, sigmaY: 18)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: IgnorePointer(
              ignoring: !_revealed,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget._pageCount,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  if (_hasVideo && index == 0) {
                    return _VideoPage(
                      videoUrl: widget.videoUrl!,
                      onTap: _toggleChrome,
                    );
                  }
                  final imageIndex = _imagePageIndex(index);
                  return _ZoomableImagePage(
                    imageUrl: widget.imageUrls[imageIndex],
                    onTap: _toggleChrome,
                  );
                },
              ),
            ),
          ),

          if (!_revealed)
            Positioned.fill(
              child: GestureDetector(
                onTap: _reveal,
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isNsfw)
                            _SensitivePill(
                              label: 'NSFW',
                              color: Colors.redAccent,
                            ),
                          if (widget.isNsfw && widget.isSpoiler)
                            const SizedBox(width: 6),
                          if (widget.isSpoiler)
                            _SensitivePill(
                              label: 'Spoiler',
                              color: Colors.amber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap to reveal',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Chrome overlay
          if (_chromeVisible) ...[
            // Top close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: _ChromeButton(
                icon: Icons.close,
                onTap: _close,
              ),
            ),

            // Bottom page indicator
            if (widget._pageCount > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: _PageIndicator(
                  currentIndex: _currentIndex,
                  count: widget._pageCount,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// A video player page with basic playback controls.
class _VideoPage extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onTap;

  const _VideoPage({required this.videoUrl, required this.onTap});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _errored = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(_VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _initialized = false;
      _errored = false;
      _initPlayer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
      _controller.play();
      _controller.addListener(_onControllerUpdate);
    } catch (_) {
      if (mounted) setState(() => _errored = true);
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    // Rebuild for position/progress updates when controls are visible
    if (_showControls) setState(() {});
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _seekTo(double position) {
    _controller.seekTo(Duration(seconds: position.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    if (_errored) {
      return const Center(
        child:
            Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
      );
    }

    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
          strokeWidth: 2,
        ),
      );
    }

    final duration = _controller.value.duration;
    final position = _controller.value.position;
    final isPlaying = _controller.value.isPlaying;
    final progress = duration.inSeconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () {
        widget.onTap();
        setState(() => _showControls = !_showControls);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player — AspectRatio prevents stretching
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Play/pause overlay (fades in/out with chrome)
          if (_chromeVisible) ...[
            // Large play/pause button in center
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

            // Seek bar at the bottom
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 48,
              child: _VideoSeekBar(
                progress: progress,
                position: position,
                duration: duration,
                onSeek: _seekTo,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _chromeVisible {
    // Use the parent's chrome visibility via onTap toggling
    // We manage our own _showControls which follows chrome visibility
    return _showControls;
  }
}

/// Seek bar with position label, track, and duration label.
class _VideoSeekBar extends StatelessWidget {
  final double progress;
  final Duration position;
  final Duration duration;
  final ValueChanged<double> onSeek;

  const _VideoSeekBar({
    required this.progress,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _formatDuration(position),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: onSeek,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(duration),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

/// A single zoomable image page within the media viewer.
class _ZoomableImagePage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const _ZoomableImagePage({
    required this.imageUrl,
    required this.onTap,
  });

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage> {
  final _transformationController = TransformationController();
  bool _errored = false;

  @override
  void didUpdateWidget(_ZoomableImagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _transformationController.value = Matrix4.identity();
      _errored = false;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale > 1.1) {
      _transformationController.value = Matrix4.identity();
    } else {
      final size = MediaQuery.of(context).size;
      final center = Offset(size.width / 2, size.height / 2);
      // ignore: deprecated_member_use
      final newMatrix = Matrix4.identity()
        ..translate(center.dx, center.dy) // ignore: deprecated_member_use
        ..scale(3.0) // ignore: deprecated_member_use
        ..translate(-center.dx, -center.dy);
      _transformationController.value = newMatrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 5.0,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        child: Center(
          child: _errored
              ? const Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 48)
              : Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final total =
                        loadingProgress.expectedTotalBytes?.toDouble();
                    final progress = total != null
                        ? loadingProgress.cumulativeBytesLoaded / total
                        : null;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        value: progress,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _errored = true);
                    });
                    return const Icon(Icons.broken_image_outlined,
                        color: Colors.white38, size: 48);
                  },
                ),
        ),
      ),
    );
  }
}

/// A small semi-transparent circle button for chrome actions.
class _ChromeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ChromeButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Dot-based page indicator showing current position in a gallery.
class _PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _PageIndicator({
    required this.currentIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < count; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == currentIndex ? 8 : 6,
                height: i == currentIndex ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == currentIndex ? Colors.white : Colors.white38,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SensitivePill extends StatelessWidget {
  final String label;
  final Color color;

  const _SensitivePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
