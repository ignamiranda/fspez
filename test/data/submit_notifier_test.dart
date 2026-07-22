import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/media_client.dart';
import 'package:fspez/src/data/submit_client.dart';
import 'package:fspez/src/data/submit_notifier.dart';
import 'package:fspez/src/domain/models/flair_option.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubmitClient extends Mock implements SubmitClient {}

class _MockMediaUploadClient extends Mock implements MediaUploadClient {}

void main() {
  late _MockSubmitClient submitClient;
  late _MockMediaUploadClient mediaClient;
  late SubmitNotifier notifier;

  setUpAll(() {
    registerFallbackValue(SessionCookie(
      value: 'fallback',
      expiresAt: DateTime.utc(2099),
    ));
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    submitClient = _MockSubmitClient();
    mediaClient = _MockMediaUploadClient();
    notifier = SubmitNotifier(submitClient, mediaClient);
  });

  group('state management', () {
    test('initial state has default values', () {
      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.success, isFalse);
      expect(notifier.state.selectedImage, isNull);
      expect(notifier.state.selectedVideo, isNull);
      expect(notifier.state.galleryFiles, isEmpty);
    });

    test('reset clears all state', () {
      notifier.selectFlair(const FlairOption(
          flairTemplateId: 'f1', text: 'Discussion', isEditable: false));
      notifier.state =
          notifier.state.copyWith(isSubmitting: true, error: 'some error');

      notifier.reset();

      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.selectedFlair, isNull);
    });
  });

  group('canSubmit', () {
    test('returns true when not submitting and flair not required', () {
      expect(notifier.canSubmit, isTrue);
    });

    test('returns false while submitting', () {
      notifier.state = notifier.state.copyWith(isSubmitting: true);
      expect(notifier.canSubmit, isFalse);
    });

    test('returns false when flair is required but none selected', () {
      notifier.state =
          notifier.state.copyWith(isFlairRequired: true, selectedFlair: null);
      expect(notifier.canSubmit, isFalse);
    });

    test('returns true when flair is required and selected', () {
      notifier.state = notifier.state.copyWith(
        isFlairRequired: true,
        selectedFlair: const FlairOption(
            flairTemplateId: 'f1', text: 'Discussion', isEditable: false),
      );
      expect(notifier.canSubmit, isTrue);
    });
  });

  group('selectFlair', () {
    test('updates selected flair and clears error', () {
      notifier.state = notifier.state.copyWith(error: 'previous error');
      const flair = FlairOption(
          flairTemplateId: 'f1', text: 'Discussion', isEditable: false);

      notifier.selectFlair(flair);

      expect(notifier.state.selectedFlair, flair);
      expect(notifier.state.error, isNull);
    });
  });

  group('onSubredditChanged', () {
    test('clears flairs on empty subreddit', () {
      notifier.state = notifier.state.copyWith(
        flairOptions: [
          const FlairOption(
              flairTemplateId: 'f1', text: 'A', isEditable: false),
        ],
      );

      notifier.onSubredditChanged('');

      expect(notifier.state.flairOptions, isEmpty);
    });

    test('triggers 300ms debounced fetch on new subreddit', () async {
      final options = <FlairOption>[
        const FlairOption(
            flairTemplateId: 'f1', text: 'News', isEditable: false),
      ];
      when(() => submitClient.fetchFlairOptions('flutterdev', null))
          .thenAnswer((_) async => options);

      notifier.onSubredditChanged('flutterdev');
      expect(notifier.state.isFetchingFlairs, isFalse); // Not fetched yet

      await Future.delayed(const Duration(milliseconds: 350));
      expect(notifier.state.flairOptions, options);
      expect(notifier.state.isFetchingFlairs, isFalse);
    });

    test('uses cache on repeated subreddit', () async {
      final options = <FlairOption>[
        const FlairOption(
            flairTemplateId: 'f1', text: 'News', isEditable: false),
      ];
      when(() => submitClient.fetchFlairOptions('flutterdev', null))
          .thenAnswer((_) async => options);

      // First call populates cache
      notifier.onSubredditChanged('flutterdev');
      await Future.delayed(const Duration(milliseconds: 350));

      // Second call hits cache
      notifier.onSubredditChanged('flutterdev');
      expect(notifier.state.flairOptions, options);
    });
  });

  group('submit', () {
    final cookie = SessionCookie(
      value: 'session',
      expiresAt: DateTime.utc(2099),
    );

    test('returns false when canSubmit is false', () async {
      notifier.state = notifier.state.copyWith(isSubmitting: true);

      final result = await notifier.submit(fields: {}, sessionCookie: cookie);

      expect(result, isFalse);
      verifyNever(() => submitClient.submit(
          fields: any(named: 'fields'),
          sessionCookie: any(named: 'sessionCookie')));
    });

    test('submits fields and returns true on success', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      final result = await notifier.submit(
        fields: {'kind': 'self', 'sr': 'test'},
        sessionCookie: cookie,
      );

      expect(result, isTrue);
      expect(notifier.state.success, isTrue);
      verify(() => submitClient.submit(
          fields: {'kind': 'self', 'sr': 'test'},
          sessionCookie: cookie)).called(1);
    });

    test('returns false and sets error on failure', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenThrow(Exception('submit failed'));

      final result = await notifier.submit(
        fields: {'kind': 'self', 'sr': 'test'},
        sessionCookie: cookie,
      );

      expect(result, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.isSubmitting, isFalse);
    });

    test('includes flair_id and flair_text when flair selected', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      notifier.selectFlair(const FlairOption(
          flairTemplateId: 'f1', text: 'Discussion', isEditable: false));

      await notifier.submit(
        fields: {'kind': 'self', 'sr': 'test'},
        sessionCookie: cookie,
      );

      verify(() => submitClient.submit(fields: {
            'kind': 'self',
            'sr': 'test',
            'flair_id': 'f1',
            'flair_text': 'Discussion',
          }, sessionCookie: cookie)).called(1);
    });
  });

  group('submitText', () {
    final cookie = SessionCookie(
      value: 'session',
      expiresAt: DateTime.utc(2099),
      modhash: 'mh123',
    );

    test('builds self fields and calls submit', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      final result = await notifier.submitText(
        title: 'My Post',
        subreddit: 'flutter',
        text: 'Hello',
        sessionCookie: cookie,
      );

      expect(result, isTrue);
      verify(() => submitClient.submit(fields: {
            'kind': 'self',
            'sr': 'flutter',
            'title': 'My Post',
            'uh': 'mh123',
            'text': 'Hello',
          }, sessionCookie: cookie)).called(1);
    });

    test('omits text field when empty', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      await notifier.submitText(
        title: 'Title',
        subreddit: 'flutter',
        text: '',
        sessionCookie: cookie,
      );

      verify(() => submitClient.submit(fields: {
            'kind': 'self',
            'sr': 'flutter',
            'title': 'Title',
            'uh': 'mh123',
          }, sessionCookie: cookie)).called(1);
    });
  });

  group('submitLink', () {
    final cookie = SessionCookie(
      value: 'session',
      expiresAt: DateTime.utc(2099),
      modhash: 'mh456',
    );

    test('builds link fields and calls submit', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      await notifier.submitLink(
        title: 'Cool Link',
        subreddit: 'flutter',
        url: 'https://example.com',
        sessionCookie: cookie,
      );

      verify(() => submitClient.submit(fields: {
            'kind': 'link',
            'sr': 'flutter',
            'title': 'Cool Link',
            'uh': 'mh456',
            'url': 'https://example.com',
          }, sessionCookie: cookie)).called(1);
    });
  });

  group('media state mutations', () {
    test('setImage updates selectedImage', () {
      final file = PlatformFile(name: 'img.png', size: 100);
      notifier.setImage(file);
      expect(notifier.state.selectedImage, file);
    });

    test('clearImage clears selectedImage', () {
      notifier.setImage(PlatformFile(name: 'img.png', size: 100));
      notifier.clearImage();
      expect(notifier.state.selectedImage, isNull);
    });

    test('setVideo updates selectedVideo', () {
      final file = PlatformFile(name: 'vid.mp4', size: 1000);
      notifier.setVideo(file);
      expect(notifier.state.selectedVideo, file);
    });

    test('clearVideo clears selectedVideo', () {
      notifier.setVideo(PlatformFile(name: 'vid.mp4', size: 1000));
      notifier.clearVideo();
      expect(notifier.state.selectedVideo, isNull);
    });

    test('setGalleryFiles sets files and captions', () {
      final files = <PlatformFile>[
        PlatformFile(name: '1.jpg', size: 100),
        PlatformFile(name: '2.jpg', size: 200),
      ];
      notifier.setGalleryFiles(files);
      expect(notifier.state.galleryFiles, hasLength(2));
      expect(notifier.state.galleryCaptions, hasLength(2));
    });

    test('addGalleryImages caps at 20', () {
      final many = List<PlatformFile>.generate(
          20, (i) => PlatformFile(name: '$i.jpg', size: 100));
      notifier.setGalleryFiles(many);

      notifier.addGalleryImages(
          <PlatformFile>[PlatformFile(name: 'extra.jpg', size: 100)]);
      expect(notifier.state.galleryFiles, hasLength(20));
    });

    test('removeGalleryItem removes file and caption', () {
      notifier.setGalleryFiles(<PlatformFile>[
        PlatformFile(name: '1.jpg', size: 100),
        PlatformFile(name: '2.jpg', size: 200),
      ]);
      notifier.removeGalleryItem(0);
      expect(notifier.state.galleryFiles, hasLength(1));
      expect(notifier.state.galleryFiles[0].name, '2.jpg');
    });

    test('updateGalleryCaption updates caption at index', () {
      notifier.setGalleryFiles([PlatformFile(name: '1.jpg', size: 100)]);
      notifier.updateGalleryCaption(0, 'New caption');
      expect(notifier.state.galleryCaptions[0], 'New caption');
    });

    test('clearAllMedia clears image, gallery, and video', () {
      notifier.setImage(PlatformFile(name: 'img.png', size: 100));
      notifier.setVideo(PlatformFile(name: 'vid.mp4', size: 1000));
      notifier.setGalleryFiles([PlatformFile(name: '1.jpg', size: 100)]);
      notifier.clearAllMedia();
      expect(notifier.state.selectedImage, isNull);
      expect(notifier.state.selectedVideo, isNull);
      expect(notifier.state.galleryFiles, isEmpty);
    });
  });
}
