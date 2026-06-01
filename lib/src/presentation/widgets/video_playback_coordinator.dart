import 'package:video_player/video_player.dart';

abstract class VideoPlaybackCoordinator {
  VideoPlayerController? get activeController;

  void activate(VideoPlayerController controller);

  void deactivate(VideoPlayerController controller);
}

class GlobalVideoPlaybackCoordinator implements VideoPlaybackCoordinator {
  GlobalVideoPlaybackCoordinator._();

  static final GlobalVideoPlaybackCoordinator instance =
      GlobalVideoPlaybackCoordinator._();

  VideoPlayerController? _activeController;

  @override
  VideoPlayerController? get activeController => _activeController;

  @override
  void activate(VideoPlayerController controller) {
    if (_activeController != null && _activeController != controller) {
      _activeController!.pause();
    }
    _activeController = controller;
    controller.play();
  }

  @override
  void deactivate(VideoPlayerController controller) {
    if (_activeController == controller) {
      _activeController?.pause();
      _activeController = null;
    }
  }
}
