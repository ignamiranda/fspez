import 'dart:async';
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
/// - Drag down to dismiss (images only, when not zoomed)
/// - Zoom state disables gallery swipe
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
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
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
  double _dragOffset = 0;
  bool _anyPageZoomed = false;
  Timer? _chromeTimer;

  static const _chromeAutoHideDuration = Duration(seconds: 4);
  static const _dismissThreshold = 150.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget._pageCount - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _revealed = widget.initiallyRevealed || !widget.isNsfw && !widget.isSpoiler;
    _startChromeTimer();
  }

  @override
  void dispose() {
    _chromeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startChromeTimer() {
    _chromeTimer?.cancel();
    _chromeTimer = Timer(_chromeAutoHideDuration, () {
      if (mounted && _chromeVisible) setState(() => _chromeVisible = false);
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) _startChromeTimer();
  }

  void _reveal() => setState(() => _revealed = true);

  void _close() => Navigator.of(context).pop();

  void _onDismissUpdate(double delta) {
    if (_hasVideo && _currentIndex == 0) return;
    setState(() => _dragOffset = (_dragOffset + delta).clamp(0.0, 400.0));
  }

  void _onDismissEnd() {
    if (_dragOffset > _dismissThreshold) {
      _close();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  bool get _hasVideo => widget.videoUrl != null;

  /// Returns the image page index (accounts for video page 0 offset).
  int _imagePageIndex(int pageIndex) => _hasVideo ? pageIndex - 1 : pageIndex;

  @override
  Widget build(BuildContext context) {
    final dismissProgress = (_dragOffset / _dismissThreshold).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Opacity(
          opacity: 1.0 - dismissProgress * 0.4,
          child: Stack(
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
                    physics: _anyPageZoomed
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
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
                        onDragUpdate: _onDismissUpdate,
                        onDragEnd: _onDismissEnd,
                        onZoomChanged: (zoomed) {
                          if (mounted) setState(() => _anyPageZoomed = zoomed);
                        },
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
                                const _SensitivePill(
                                  label: 'NSFW',
                                  color: Colors.redAccent,
                                ),
                              if (widget.isNsfw && widget.isSpoiler)
                                const SizedBox(width: 6),
                              if (widget.isSpoiler)
                                const _SensitivePill(
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
        ),
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
                  decoration: const BoxDecoration(
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
            data: const SliderThemeData(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
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
  final ValueChanged<double>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final ValueChanged<bool>? onZoomChanged;
  const _ZoomableImagePage({
    required this.imageUrl,
    required this.onTap,
    this.onDragUpdate,
    this.onDragEnd,
    this.onZoomChanged,
  });

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage> {
  final _transformationController = TransformationController();
  Offset? _doubleTapDownPosition;
  bool _isZoomed = false;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _imageSize;
  String? _resolvedImageUrl;
  bool _errored = false;

  static const double _longImageAspectRatioThreshold = 0.25;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedImageUrl != widget.imageUrl) {
      _resolveImageSize();
    }
  }

  void _resolveImageSize() {
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }

    _imageSize = null;
    _resolvedImageUrl = widget.imageUrl;
    final provider = NetworkImage(widget.imageUrl);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      },
      onError: (_, __) {
        if (mounted) setState(() => _errored = true);
      },
    );
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  @override
  void didUpdateWidget(_ZoomableImagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _transformationController.value = Matrix4.identity();
      _imageSize = null;
      _resolvedImageUrl = null;
      _errored = false;
      _resolveImageSize();
    }
  }

  @override
  void dispose() {
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }
    _transformationController.dispose();
    super.dispose();
  }

  bool get _isLongImage {
    final size = _imageSize;
    if (size == null || size.width == 0) return false;
    return size.width / size.height < _longImageAspectRatioThreshold;
  }

  void _updateZoomState() {
    final zoomed = _transformationController.value.getMaxScaleOnAxis() > 1.1;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
      widget.onZoomChanged?.call(zoomed);
    }
  }

  void _onDoubleTap() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale > 1.1) {
      _transformationController.value = Matrix4.identity();
      _updateZoomState();
    } else {
      final tapPos = _doubleTapDownPosition ??
          Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2,
          );
      final newMatrix = Matrix4.identity()
        ..translateByDouble(tapPos.dx, tapPos.dy, 0, 1.0)
        ..scaleByDouble(3.0, 3.0, 3.0, 1.0)
        ..translateByDouble(-tapPos.dx, -tapPos.dy, 0, 1.0);
      _transformationController.value = newMatrix;
      _updateZoomState();
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _updateZoomState();
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    _updateZoomState();

    if (!_isLongImage &&
        details.pointerCount == 1 &&
        !_isZoomed) {
      final dy = details.focalPointDelta.dy;
      if (dy > 0) {
        widget.onDragUpdate?.call(dy);
      }
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    widget.onDragEnd?.call();
    if (!_isZoomed) {
      _transformationController.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageSize == null && !_errored) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
          strokeWidth: 2,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (d) => _doubleTapDownPosition = d.localPosition,
      onDoubleTap: _onDoubleTap,
      child: _isLongImage ? _buildLongImage(context) : _buildZoomableImage(),
    );
  }

  Widget _buildZoomableImage() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 5.0,
      boundaryMargin:
          _isZoomed ? const EdgeInsets.all(double.infinity) : EdgeInsets.zero,
      onInteractionStart: _onInteractionStart,
      onInteractionUpdate: _onInteractionUpdate,
      onInteractionEnd: _onInteractionEnd,
      child: Center(
        child: _errored
            ? const Icon(Icons.broken_image_outlined,
                color: Colors.white38, size: 48)
            : Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final total = loadingProgress.expectedTotalBytes?.toDouble();
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
    );
  }

  Widget _buildLongImage(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 5.0,
          boundaryMargin: _isZoomed
              ? const EdgeInsets.all(double.infinity)
              : EdgeInsets.zero,
          onInteractionStart: _onInteractionStart,
          onInteractionUpdate: _onInteractionUpdate,
          onInteractionEnd: _onInteractionEnd,
          child: Center(
            child: _errored
                ? const Icon(Icons.broken_image_outlined,
                    color: Colors.white38, size: 48)
                : Image.network(
                    widget.imageUrl,
                    width: constraints.maxWidth,
                    fit: BoxFit.fitWidth,
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
        );
      },
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
