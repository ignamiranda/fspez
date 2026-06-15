import 'package:flutter/material.dart';

/// A tappable media tile used in post detail for images and galleries.
class PostMediaTile extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isVideo;

  const PostMediaTile({
    super.key,
    required this.imageUrl,
    required this.onTap,
    this.badgeText,
    this.isVideo = false,
  });

  @override
  State<PostMediaTile> createState() => _PostMediaTileState();
}

class _PostMediaTileState extends State<PostMediaTile> {
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

  @override
  void didUpdateWidget(PostMediaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
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
    super.dispose();
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

  bool get _isLongImage {
    final size = _imageSize;
    if (size == null || size.width == 0) return false;
    return size.width / size.height < _longImageAspectRatioThreshold;
  }

  @override
  Widget build(BuildContext context) {
    if (_imageSize == null && !_errored) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          height: 180,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final theme = Theme.of(context);
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isLongImage && !widget.isVideo)
              Image.network(
                widget.imageUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final total = loadingProgress.expectedTotalBytes?.toDouble();
                  final progress = total != null
                      ? loadingProgress.cumulativeBytesLoaded / total
                      : null;
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                        value: progress,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (widget.isVideo)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            if (_isLongImage && !widget.isVideo)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Long image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (widget.badgeText != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        widget.badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_errored)
              const Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 48),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GestureDetector(onTap: widget.onTap, child: child),
    );
  }
}
