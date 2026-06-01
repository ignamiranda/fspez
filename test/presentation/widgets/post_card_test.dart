import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';
import 'package:fspez/src/presentation/widgets/post_card.dart';

class MockVideoPlayerController extends Mock implements VideoPlayerController {}

class MockVideoPlayerValue extends Mock implements VideoPlayerValue {}

void main() {
  group('InlineVideoManager', () {
    late MockVideoPlayerController controllerA;
    late MockVideoPlayerController controllerB;

    setUp(() {
      controllerA = MockVideoPlayerController();
      controllerB = MockVideoPlayerController();

      // Default stubs for VideoPlayerValue used by isCompleted / position
      final valueA = MockVideoPlayerValue();
      final valueB = MockVideoPlayerValue();
      when(() => valueA.isCompleted).thenReturn(false);
      when(() => valueA.position).thenReturn(Duration.zero);
      when(() => valueB.isCompleted).thenReturn(false);
      when(() => valueB.position).thenReturn(Duration.zero);
      when(() => controllerA.value).thenReturn(valueA);
      when(() => controllerB.value).thenReturn(valueB);

      // play/pause are void — just register
      when(() => controllerA.play()).thenAnswer((_) async {});
      when(() => controllerA.pause()).thenAnswer((_) async {});
      when(() => controllerB.play()).thenAnswer((_) async {});
      when(() => controllerB.pause()).thenAnswer((_) async {});
    });

    tearDown(() {
      // Reset the manager singleton between tests
      final current = InlineVideoManager.activeController;
      if (current != null) {
        InlineVideoManager.deactivate(current);
      }
    });

    test('activate plays controller and sets it as active', () {
      InlineVideoManager.activate(controllerA);

      verify(() => controllerA.play()).called(1);
      expect(InlineVideoManager.activeController, controllerA);
    });

    test('activate pauses previous and plays new', () {
      InlineVideoManager.activate(controllerA);
      InlineVideoManager.activate(controllerB);

      verify(() => controllerA.pause()).called(1);
      verify(() => controllerB.play()).called(1);
      expect(InlineVideoManager.activeController, controllerB);
    });

    test('activate same controller does not pause it', () {
      InlineVideoManager.activate(controllerA);
      InlineVideoManager.activate(controllerA);

      // activate always plays, but the important thing is pause is never called
      verify(() => controllerA.play()).called(2);
      verifyNever(() => controllerA.pause());
    });

    test('deactivate pauses and clears active controller', () {
      InlineVideoManager.activate(controllerA);
      InlineVideoManager.deactivate(controllerA);

      verify(() => controllerA.pause()).called(1);
      expect(InlineVideoManager.activeController, isNull);
    });

    test('deactivate non-active controller does nothing', () {
      InlineVideoManager.activate(controllerA);
      InlineVideoManager.deactivate(controllerB);

      // controllerA should still be playing
      verifyNever(() => controllerB.pause());
      expect(InlineVideoManager.activeController, controllerA);
    });

    test('activeController returns null when no controller active', () {
      expect(InlineVideoManager.activeController, isNull);
    });
  });
}
