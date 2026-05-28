import 'package:flutter/material.dart';

/// Full-screen media overlay with pinch-to-zoom and gallery swipe.
///
/// Supports:
/// - Single image: displays one full-screen zoomable image
/// - Gallery: swipe left/right between multiple images
/// - Pinch-to-zoom via [InteractiveViewer]
/// - Double-tap to zoom in/out
/// - Tap to toggle chrome (close button + page counter)
class MediaViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const MediaViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  /// Push the viewer as a full-screen route.
  static Future<void> show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            MediaViewer(imageUrls: imageUrls, initialIndex: initialIndex),
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main image page view
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) => _ZoomableImagePage(
              imageUrl: widget.imageUrls[index],
              onTap: _toggleChrome,
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
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: _PageIndicator(
                  currentIndex: _currentIndex,
                  count: widget.imageUrls.length,
                ),
              ),
          ],
        ],
      ),
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
                    // After first build, mark errored so InteractiveViewer
                    // still works (allows panning around the error icon).
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
