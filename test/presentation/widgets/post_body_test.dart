import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/post.dart';
import 'package:fspez/src/domain/models/subreddit.dart';
import 'package:fspez/src/presentation/widgets/post_body.dart';
import 'package:fspez/src/presentation/widgets/post_action_bar.dart';
import 'package:fspez/src/presentation/widgets/post_metadata.dart';
import 'package:fspez/src/presentation/widgets/feed_media_tile.dart';
import 'package:fspez/src/data/auth_providers.dart';

Post _createPost({
  required String id,
  String title = 'Test Post',
  PostType type = PostType.link,
  List<String> mediaUrls = const [],
  String? videoUrl,
  String? selftext,
  String? url,
  bool isNsfw = false,
  bool isSpoiler = false,
}) {
  return Post(
    id: id,
    title: title,
    author: 'testuser',
    subreddit: const Subreddit(id: 't5_1', name: 'flutter'),
    createdAt: DateTime.now(),
    permalink: '/r/flutter/comments/$id/test_post/',
    type: type,
    mediaUrls: mediaUrls,
    videoUrl: videoUrl,
    selftext: selftext,
    url: url,
    isNsfw: isNsfw,
    isSpoiler: isSpoiler,
  );
}

Widget _buildTestApp(SharedPreferences prefs, Widget child) {
  return ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  late SharedPreferences testPrefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
  });

  group('PostBody', () {
    testWidgets('renders metadata row and title for any post type',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '1'),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      expect(find.text('Test Post'), findsOneWidget);
      expect(find.text('r/flutter'), findsOneWidget);
      expect(find.text('u/testuser'), findsOneWidget);
    });

    testWidgets('renders action bar with media present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '2',
            type: PostType.image,
            url: 'https://example.com/img.jpg',
            mediaUrls: ['https://example.com/img.jpg'],
          ),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      expect(find.byIcon(Icons.arrow_upward_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
    });

    testWidgets('renders action bar for self posts without media',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '3',
            type: PostType.self_,
            selftext: 'A self post body',
          ),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      expect(find.byIcon(Icons.arrow_upward_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('renders action bar for link posts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '4',
            type: PostType.link,
            url: 'https://example.com',
          ),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      expect(find.byIcon(Icons.arrow_upward_outlined), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('shows selftext preview when showSelftext is true',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '5',
            type: PostType.self_,
            selftext: 'This is a self post body text',
          ),
          vote: VoteDirection.none,
          isSaved: false,
          showSelftext: true,
        ),
      ));

      expect(find.text('This is a self post body text'), findsOneWidget);
    });

    testWidgets('hides selftext preview when showSelftext is false',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '6',
            type: PostType.self_,
            selftext: 'This should be hidden',
          ),
          vote: VoteDirection.none,
          isSaved: false,
          showSelftext: false,
        ),
      ));

      expect(find.text('This should be hidden'), findsNothing);
    });

    testWidgets('shows upvote ratio when provided', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '7'),
          vote: VoteDirection.none,
          isSaved: false,
          upvoteRatio: 0.85,
        ),
      ));

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('hides upvote ratio when not provided', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '8'),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('shows vote button active state for upvoted post',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '9'),
          vote: VoteDirection.upvote,
          isSaved: false,
        ),
      ));

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_outlined), findsOneWidget);
    });

    testWidgets('shows save button active state for saved post',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '10'),
          vote: VoteDirection.none,
          isSaved: true,
        ),
      ));

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_outline), findsNothing);
    });

    testWidgets('exposes semantic labels for post actions', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_buildTestApp(
          testPrefs,
          PostBody(
            post: _createPost(id: '11'),
            vote: VoteDirection.none,
            isSaved: false,
          ),
        ));

        expect(find.bySemanticsLabel('Upvote'), findsOneWidget);
        expect(find.bySemanticsLabel('Downvote'), findsOneWidget);
        expect(find.bySemanticsLabel('Save'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('calls onVote when upvote button is tapped', (tester) async {
      VoteDirection? tapped;
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '12'),
          vote: VoteDirection.none,
          isSaved: false,
          onVote: (dir) => tapped = dir,
        ),
      ));

      await tester.tap(find.byIcon(Icons.arrow_upward_outlined));
      expect(tapped, VoteDirection.upvote);
    });

    testWidgets('calls onVote when downvote button is tapped', (tester) async {
      VoteDirection? tapped;
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '13'),
          vote: VoteDirection.none,
          isSaved: false,
          onVote: (dir) => tapped = dir,
        ),
      ));

      await tester.tap(find.byIcon(Icons.arrow_downward_outlined));
      expect(tapped, VoteDirection.downvote);
    });

    testWidgets('calls onSave when save button is tapped', (tester) async {
      var saved = false;
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '14'),
          vote: VoteDirection.none,
          isSaved: false,
          onSave: () => saved = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.bookmark_outline));
      expect(saved, isTrue);
    });

    testWidgets('calls onTap when comments button is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '15'),
          vote: VoteDirection.none,
          isSaved: false,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      expect(tapped, isTrue);
    });

    testWidgets('renders FeedMediaTile for image posts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '16',
            type: PostType.image,
            url: 'https://example.com/img.jpg',
            mediaUrls: ['https://example.com/img.jpg'],
          ),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      expect(find.byType(FeedMediaTile), findsOneWidget);
    });

    testWidgets('renders FeedMediaTile for gallery posts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '17',
            type: PostType.gallery,
            mediaUrls: [
              'https://example.com/img1.jpg',
              'https://example.com/img2.jpg',
            ],
          ),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      expect(find.byType(FeedMediaTile), findsOneWidget);
    });

    testWidgets('layout order: metadata above action bar for link posts',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(id: '18', type: PostType.link),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      final metadataPos = tester.getTopLeft(find.byType(PostMetadataRow));
      final actionBarPos = tester.getTopLeft(find.byType(PostActionBar));
      expect(actionBarPos.dy, greaterThan(metadataPos.dy));
    });

    testWidgets('layout order: metadata above action bar for self posts',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '19',
            type: PostType.self_,
            selftext: 'Some body text',
          ),
          vote: VoteDirection.none,
          isSaved: false,
          showSelftext: true,
        ),
      ));

      final metadataPos = tester.getTopLeft(find.byType(PostMetadataRow));
      final actionBarPos = tester.getTopLeft(find.byType(PostActionBar));
      expect(actionBarPos.dy, greaterThan(metadataPos.dy));
    });

    testWidgets('layout order: media above action bar for image posts',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        testPrefs,
        PostBody(
          post: _createPost(
            id: '20',
            type: PostType.image,
            url: 'https://example.com/img.jpg',
            mediaUrls: ['https://example.com/img.jpg'],
          ),
          vote: VoteDirection.none,
          isSaved: false,
        ),
      ));

      final mediaPos = tester.getTopLeft(find.byType(FeedMediaTile));
      final actionBarPos = tester.getTopLeft(find.byType(PostActionBar));
      expect(actionBarPos.dy, greaterThan(mediaPos.dy));
    });
  });
}
