import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/flair_notifier.dart';
import 'package:fspez/src/data/submit_client.dart';
import 'package:fspez/src/domain/models/flair_option.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubmitClient extends Mock implements SubmitClient {}

void main() {
  late _MockSubmitClient submitClient;
  late FlairNotifier notifier;

  setUp(() {
    submitClient = _MockSubmitClient();
    notifier = FlairNotifier(submitClient);
  });

  group('initial state', () {
    test('has default values', () {
      expect(notifier.state.flairOptions, isEmpty);
      expect(notifier.state.selectedFlair, isNull);
      expect(notifier.state.isFlairRequired, isFalse);
      expect(notifier.state.isFetchingFlairs, isFalse);
    });
  });

  group('selectFlair', () {
    test('updates selected flair', () {
      const flair = FlairOption(
        flairTemplateId: 'f1',
        text: 'Discussion',
        isEditable: false,
      );

      notifier.selectFlair(flair);

      expect(notifier.state.selectedFlair, flair);
    });

    test('clears selected flair when null', () {
      const flair = FlairOption(
        flairTemplateId: 'f1',
        text: 'Discussion',
        isEditable: false,
      );
      notifier.selectFlair(flair);

      notifier.selectFlair(null);

      expect(notifier.state.selectedFlair, isNull);
    });
  });

  group('onSubredditChanged', () {
    test('clears flairs on empty subreddit', () {
      notifier.state = const FlairState(
        flairOptions: [
          FlairOption(
            flairTemplateId: 'f1',
            text: 'News',
            isEditable: false,
          ),
        ],
      );

      notifier.onSubredditChanged('');

      expect(notifier.state.flairOptions, isEmpty);
    });

    test('triggers 300ms debounced fetch on new subreddit', () async {
      final options = <FlairOption>[
        const FlairOption(
          flairTemplateId: 'f1',
          text: 'News',
          isEditable: false,
        ),
      ];
      when(() => submitClient.fetchFlairOptions('flutterdev', null))
          .thenAnswer((_) async => options);

      notifier.onSubredditChanged('flutterdev');
      expect(notifier.state.isFetchingFlairs, isFalse);

      await Future.delayed(const Duration(milliseconds: 350));
      expect(notifier.state.flairOptions, options);
      expect(notifier.state.isFetchingFlairs, isFalse);
    });

    test('uses cache on repeated subreddit', () async {
      final options = <FlairOption>[
        const FlairOption(
          flairTemplateId: 'f1',
          text: 'News',
          isEditable: false,
        ),
      ];
      when(() => submitClient.fetchFlairOptions('flutterdev', null))
          .thenAnswer((_) async => options);

      notifier.onSubredditChanged('flutterdev');
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.onSubredditChanged('flutterdev');
      expect(notifier.state.flairOptions, options);
    });

    test('clears selectedFlair on cache hit', () async {
      final options = <FlairOption>[
        const FlairOption(
          flairTemplateId: 'f1',
          text: 'News',
          isEditable: false,
        ),
      ];
      when(() => submitClient.fetchFlairOptions('flutterdev', null))
          .thenAnswer((_) async => options);

      notifier.onSubredditChanged('flutterdev');
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.selectFlair(const FlairOption(
        flairTemplateId: 'f2',
        text: 'Discussion',
        isEditable: false,
      ));
      expect(notifier.state.selectedFlair, isNotNull);

      notifier.onSubredditChanged('flutterdev');
      expect(notifier.state.selectedFlair, isNull);
    });
  });

  group('reset', () {
    test('clears all flair state', () {
      notifier.selectFlair(const FlairOption(
        flairTemplateId: 'f1',
        text: 'Discussion',
        isEditable: false,
      ));
      notifier.state = notifier.state.copyWith(isFetchingFlairs: true);

      notifier.reset();

      expect(notifier.state.flairOptions, isEmpty);
      expect(notifier.state.selectedFlair, isNull);
      expect(notifier.state.isFetchingFlairs, isFalse);
    });
  });
}
