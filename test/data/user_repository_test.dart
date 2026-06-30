import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/user_repository.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/enums/comment_sort.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;
  late UserRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(SessionCookie(value: '', expiresAt: DateTime.now()));
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    client = RedditClient(httpClient: mockHttp);
    repository = UserRepository(client);
  });

  group('fetchProfile', () {
    test('GETs user about endpoint and returns profile', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "name": "testuser",
            "link_karma": 1000,
            "comment_karma": 500,
            "created_utc": 1600000000,
            "icon_img": "https://example.com/icon.png",
            "is_gold": true,
            "is_mod": false
          }
        }
      ''', 200));

      final profile = await repository.fetchProfile('testuser');

      expect(profile.username, 'testuser');
      expect(profile.linkKarma, 1000);
      expect(profile.commentKarma, 500);
      expect(profile.isGold, isTrue);
      expect(profile.isMod, isFalse);
      expect(profile.iconUrl, 'https://example.com/icon.png');
    });

    test('uses fallback username when name field is missing', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "link_karma": 0,
            "comment_karma": 0,
            "created_utc": 1600000000
          }
        }
      ''', 200));

      final profile = await repository.fetchProfile('fallback');

      expect(profile.username, 'fallback');
    });

    test('throws on API error', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('Not found', 404));

      expect(
        () => repository.fetchProfile('unknown'),
        throwsA(isA<RedditApiException>()),
      );
    });
  });

  group('fetchComments', () {
    test('GETs user comments and returns list', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "children": [
              {
                "kind": "t1",
                "data": {
                  "id": "c1",
                  "body": "Great post!",
                  "author": "testuser",
                  "score": 42,
                  "likes": true,
                  "created_utc": 1600000000,
                  "subreddit": "flutter",
                  "link_title": "My Flutter App",
                  "link_permalink": "/r/flutter/comments/abc/",
                  "link_id": "t3_abc"
                }
              }
            ],
            "after": null
          }
        }
      ''', 200));

      final comments = await repository.fetchComments('testuser');

      expect(comments.length, 1);
      expect(comments[0].id, 'c1');
      expect(comments[0].body, 'Great post!');
      expect(comments[0].author, 'testuser');
      expect(comments[0].score, 42);
      expect(comments[0].subreddit, 'flutter');
      expect(comments[0].linkTitle, 'My Flutter App');
      expect(comments[0].linkPermalink, '/r/flutter/comments/abc/');
      expect(comments[0].postId, 't3_abc');
    });

    test('skips non-t1 children', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "children": [
              {"kind": "more", "data": {"count": 5}},
              {
                "kind": "t1",
                "data": {
                  "id": "c1",
                  "body": "Only comment",
                  "author": "user",
                  "created_utc": 1600000000,
                  "subreddit": "test",
                  "link_title": "Post",
                  "link_permalink": "/r/test/",
                  "link_id": "t3_abc"
                }
              }
            ],
            "after": null
          }
        }
      ''', 200));

      final comments = await repository.fetchComments('user');

      expect(comments.length, 1);
      expect(comments[0].id, 'c1');
    });

    test('returns empty list for no comments', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "children": [],
            "after": null
          }
        }
      ''', 200));

      final comments = await repository.fetchComments('lurker');

      expect(comments, isEmpty);
    });

    test('sends the requested comment sort', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "children": [],
            "after": null
          }
        }
      ''', 200));

      await repository.fetchComments('sorter', sort: CommentSort.top);

      verify(() => mockHttp.get(
            Uri.parse(
                'https://old.reddit.com/user/sorter/comments.json?limit=25&sort=top'),
            headers: any(named: 'headers'),
          )).called(1);
    });
  });

  group('fetchModeratedSubreddits', () {
    test('returns list of display names', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "children": [
              {"data": {"display_name": "flutter", "name": "t5_abc"}},
              {"data": {"display_name": "dartlang", "name": "t5_def"}}
            ]
          }
        }
      ''', 200));

      final subs = await repository.fetchModeratedSubreddits(
        sessionCookie: SessionCookie(value: 'sess', expiresAt: DateTime.now()),
      );

      expect(subs, ['flutter', 'dartlang']);
    });

    test('returns empty list when no moderated subreddits', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "children": []
          }
        }
      ''', 200));

      final subs = await repository.fetchModeratedSubreddits(
        sessionCookie: SessionCookie(value: 'sess', expiresAt: DateTime.now()),
      );

      expect(subs, isEmpty);
    });

    test('skips children without display_name', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {
          "data": {
            "children": [
              {"data": {"name": "t5_xyz"}},
              {"data": {"display_name": "valid"}}
            ]
          }
        }
      ''', 200));

      final subs = await repository.fetchModeratedSubreddits(
        sessionCookie: SessionCookie(value: 'sess', expiresAt: DateTime.now()),
      );

      expect(subs, ['valid']);
    });

    test('hits correct endpoint', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('''
        {"data": {"children": []}}
      ''', 200));

      await repository.fetchModeratedSubreddits(
        sessionCookie: SessionCookie(value: 'sess', expiresAt: DateTime.now()),
      );

      verify(() => mockHttp.get(
            Uri.parse(
                'https://old.reddit.com/subreddits/mine/moderator.json'),
            headers: any(named: 'headers'),
          )).called(1);
    });
  });
}
