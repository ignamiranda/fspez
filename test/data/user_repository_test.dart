import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/user_repository.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

String _withNextData(String jsonBody) {
  return '''
    <html>
    <script id="__NEXT_DATA__" type="application/json">$jsonBody</script>
    </html>
  ''';
}

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
    test('parses user profile from HTML', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('''
          {
            "props": {
              "pageProps": {
                "user": {
                  "id": "abc123",
                  "name": "testuser",
                  "linkKarma": 1000,
                  "commentKarma": 500,
                  "createdUtc": 1600000000,
                  "iconUrl": "https://example.com/icon.png",
                  "isGold": true,
                  "isMod": false
                }
              }
            }
          }
        '''),
                200,
              ));

      final profile = await repository.fetchProfile('testuser');

      expect(profile.username, 'testuser');
      expect(profile.linkKarma, 1000);
      expect(profile.commentKarma, 500);
      expect(profile.isGold, isTrue);
      expect(profile.isMod, isFalse);
      expect(profile.iconUrl, 'https://example.com/icon.png');
    });

    test('uses fallback username when name field is missing', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('''
          {
            "props": {
              "pageProps": {
                "user": {
                  "id": "abc123",
                  "linkKarma": 0,
                  "commentKarma": 0,
                  "createdUtc": 1600000000
                }
              }
            }
          }
        '''),
                200,
              ));

      final profile = await repository.fetchProfile('fallback');

      expect(profile.username, 'fallback');
    });

    test('throws on API error', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not found', 404));

      expect(
        () => repository.fetchProfile('unknown'),
        throwsA(isA<RedditApiException>()),
      );
    });
  });

  group('fetchComments', () {
    test('parses user comments from HTML', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('''
          {
            "props": {
              "pageProps": {
                "comments": [
                  {
                    "id": "c1",
                    "body": "Great post!",
                    "author": "testuser",
                    "score": 42,
                    "likes": true,
                    "createdUtc": 1600000000,
                    "subreddit": "flutter",
                    "linkTitle": "My Flutter App",
                    "linkPermalink": "/r/flutter/comments/abc/",
                    "linkId": "t3_abc"
                  }
                ]
              }
            }
          }
        '''),
                200,
              ));

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

    test('returns empty list for no comments', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('{"props":{"pageProps":{}}}'),
                200,
              ));

      final comments = await repository.fetchComments('lurker');

      expect(comments, isEmpty);
    });
  });

  group('fetchModeratedSubreddits', () {
    test('returns list of display names from HTML', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('''
          {
            "props": {
              "pageProps": {
                "moderatedSubreddits": [
                  {"displayName": "flutter"},
                  {"displayName": "dartlang"}
                ]
              }
            }
          }
        '''),
                200,
              ));

      final subs = await repository.fetchModeratedSubreddits(
        sessionCookie: SessionCookie(value: 'sess', expiresAt: DateTime.now()),
      );

      expect(subs, ['flutter', 'dartlang']);
    });

    test('returns empty list when no moderated subreddits', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('{"props":{"pageProps":{}}}'),
                200,
              ));

      final subs = await repository.fetchModeratedSubreddits(
        sessionCookie: SessionCookie(value: 'sess', expiresAt: DateTime.now()),
      );

      expect(subs, isEmpty);
    });

    test('hits correct endpoint', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('{"props":{"pageProps":{}}}'),
                200,
              ));

      await repository.fetchModeratedSubreddits(
        sessionCookie: SessionCookie(value: 'sess', expiresAt: DateTime.now()),
      );

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/subreddits/mine/moderator'),
            headers: any(named: 'headers'),
          )).called(1);
    });
  });
}
