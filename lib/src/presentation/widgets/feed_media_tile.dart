import 'package:flutter/material.dart';

/// A tappable media preview tile used in the feed for images and galleries.
///
/// Caps preview height only when the image aspect ratio is more extreme than
/// 16:9 (landscape) or 9:16 (portrait). Images within that range display at
/// their full natural height, uncapped.
class FeedMediaTile extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String? badgeText;
  final IconData? badgeIcon;

  /// Maximum height applied only when the image ratio exceeds 16:9 or 9:16.
  final double maxHeight;

  const FeedMediaTile({
    super.key,
    required this.imageUrl,
    required this.onTap,
    this.badgeText,
    this.badgeIcon,
    this.maxHeight = 240,
  });

  @override
  State<FeedMediaTile> createState() => _FeedMediaTileState();
}

class _FeedMediaTileState extends State<FeedMediaTile> {
  Size? _naturalSize;

  late final ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = NetworkImage(widget.imageUrl);
    _resolveDimensions();
  }

  @override
  void didUpdateWidget(FeedMediaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _imageProvider = NetworkImage(widget.imageUrl);
      _naturalSize = null;
      _resolveDimensions();
    }
  }

  void _resolveDimensions() {
    final stream = _imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener(
        (info, _) {
          if (mounted) {
            final img = info.image;
            setState(() {
              _naturalSize = Size(img.width.toDouble(), img.height.toDouble());
            });
          }
        },
        onError: (_, __) {
          // dimensions unknown — render with default maxHeight cap
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final effectiveMaxHeight = _computeMaxHeight(availableWidth);

            final child = ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image(
                      image: _imageProvider,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    if (widget.badgeText != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.badgeIcon != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(widget.badgeIcon,
                                      color: Colors.white, size: 14),
                                ),
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
                  ],
                ),
              ),
            );

            return child;
          },
        ),
      ),
    );
  }

  /// Computes the effective maxHeight for the image container.
  ///
  /// - Before the image resolves: cap at [widget.maxHeight] (safe default).
  /// - Extreme aspect ratios (>16:9 or <9:16): cap at [widget.maxHeight].
  /// - Normal aspect ratios (within [9/16, 16/9]): compute the natural display
  ///   height from [availableWidth] and the image's aspect ratio, and use that
  ///   as the cap so the image renders at full natural height.
  double _computeMaxHeight(double availableWidth) {
    // Guard against degenerate or unbounded widths during initial layout.
    if (availableWidth <= 0 || !availableWidth.isFinite) {
      return widget.maxHeight;
    }
    if (_naturalSize == null) return widget.maxHeight;

    final ratio = _naturalSize!.width / _naturalSize!.height;
    const minRatio = 9.0 / 16.0; // portrait
    const maxRatio = 16.0 / 9.0; // landscape

    if (ratio >= minRatio && ratio <= maxRatio) {
      // Normal aspect ratio: display at natural height.
      // Compute naturalHeight = availableWidth / ratio, then clamp between
      // the default maxHeight (lower bound) and a generous maximum
      // (availableWidth / minRatio ≈ 1.78× availableWidth) to prevent
      // extremely tall images from displacing too much feed content.
      final naturalHeight = availableWidth / ratio;
      return naturalHeight.clamp(widget.maxHeight, availableWidth / minRatio);
    }

    // Extreme aspect ratio: cap at the configured maxHeight.
    return widget.maxHeight;
  }
}
