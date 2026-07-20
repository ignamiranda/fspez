import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'video_playback_coordinator.dart';

/// Fraction of the widget that must be visible to trigger auto-play.
const _kVideoVisibilityThreshold = 0.5;

/// An inline video player that auto-plays muted when mostly visible in the
/// viewport, pauses when scrolled out, and shows mute/unmute + play/pause
/// overlays.
class InlineVideoPlayer extends StatefulWidget {
  final String postKey;
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VideoPlaybackCoordinator videoPlaybackCoordinator;

  const InlineVideoPlayer({
    super.key,
    required this.postKey,
    required this.videoUrl,
    required this.videoPlaybackCoordinator,
    this.thumbnailUrl,
    this.onTap,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _errored = false;
  bool _isPlaying = false;
  bool _isMuted = true;
  double _lastVisibleFraction = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(_onControllerUpdate);
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      if (_lastVisibleFraction > _kVideoVisibilityThreshold) {
        _play();
      }
      // Do NOT auto-play immediately — visibility will trigger playback.
    } catch (_) {
      if (mounted) setState(() => _errored = true);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      widget.videoPlaybackCoordinator.deactivate(_controller!);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final nowPlaying = _controller?.value.isPlaying ?? false;
    if (_isPlaying != nowPlaying) {
      setState(() => _isPlaying = nowPlaying);
      // If the video ended naturally, ensure the manager knows it's done.
      if (!nowPlaying && _controller != null) {
        widget.videoPlaybackCoordinator.deactivate(_controller!);
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _lastVisibleFraction = info.visibleFraction;
    if (!_initialized || _controller == null) return;
    final visible = info.visibleFraction > _kVideoVisibilityThreshold;
    if (visible && !_isPlaying) {
      _play();
    } else if (!visible && _isPlaying) {
      _pause();
    }
  }

  void _play() {
    if (_controller == null) return;
    // If video reached the end, seek to beginning before replaying.
    final value = _controller!.value;
    if (value.isCompleted) {
      _controller!.seekTo(Duration.zero);
    }
    widget.videoPlaybackCoordinator.activate(_controller!);
    _controller!.setVolume(_isMuted ? 0 : 1);
    if (mounted) setState(() => _isPlaying = true);
  }

  void _pause() {
    if (_controller == null) return;
    widget.videoPlaybackCoordinator.deactivate(_controller!);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    final newMuted = !_isMuted;
    _controller!.setVolume(newMuted ? 0 : 1);
    if (mounted) setState(() => _isMuted = newMuted);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_errored) {
      child = widget.thumbnailUrl != null
          ? Image.network(
              widget.thumbnailUrl!,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          : const SizedBox.shrink();
    } else if (!_initialized || _controller == null) {
      child = widget.thumbnailUrl != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  widget.thumbnailUrl!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ],
            )
          : const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
    } else {
      child = Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          // Overlay controls at the bottom-right
          Positioned(
            bottom: 8,
            right: 8,
            child: VideoControlRow(
              isPlaying: _isPlaying,
              isMuted: _isMuted,
              onTogglePlayPause: _togglePlayPause,
              onToggleMute: _toggleMute,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: VisibilityDetector(
        key: ValueKey('inline_video_${widget.postKey}_${widget.videoUrl}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: GestureDetector(onTap: widget.onTap, child: child),
      ),
    );
  }
}

/// Small row of control buttons for inline video (play/pause + mute/unmute).
/// Each button stops tap propagation so the parent fullscreen gesture is not
/// triggered.
class VideoControlRow extends StatelessWidget {
  final bool isPlaying;
  final bool isMuted;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onToggleMute;

  const VideoControlRow({
    super.key,
    required this.isPlaying,
    required this.isMuted,
    required this.onTogglePlayPause,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ControlCircleButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          onTap: onTogglePlayPause,
        ),
        const SizedBox(width: 6),
        ControlCircleButton(
          icon: isMuted ? Icons.volume_off : Icons.volume_up,
          onTap: onToggleMute,
        ),
      ],
    );
  }
}

/// A small circular button with a white icon on a semi-transparent dark
/// background. Wrapped in its own [GestureDetector] to absorb the tap and
/// prevent the parent from opening the fullscreen viewer.
class ControlCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const ControlCircleButton(
      {super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
