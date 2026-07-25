import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/comment_repository.dart';
import 'package:fspez/src/data/award_enricher.dart';
import 'package:fspez/src/data/message_client.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/enums/comment_sort.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _MockMessageClient extends Mock implements MessageClient {}

class _MockAwardEnricher extends Mock implements AwardEnricher {}

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
  late _MockMessageClient mockMessageClient;
  late CommentRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    mockMessageClient = _MockMessageClient();
    client = RedditClient(httpClient: mockHttp);
    repository =
        CommentRepository(client, mockMessageClient, const NoopAwardEnricher());
  });

  group('fetchComments', () {
    test('returns post and comments from valid HTML', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('''
          {
            "props": {
              "pageProps": {
                "post": {
                  "id": "post1",
                  "title": "Test Post",
                  "author": "testuser",
                  "subreddit": "flutter",
                  "subreddit_id": "t5_2qh30",
                  "permalink": "/r/flutter/comments/post1/test_post/",
                  "createdUtc": 1000000000,
                  "score": 100,
                  "numComments": 5
                },
                "comments": [
                  {
                    "id": "c1",
                    "body": "First comment",
                    "author": "user1",
                    "score": 10,
                    "createdUtc": 1000000001,
                    "depth": 0
                  },
                  {
                    "id": "c2",
                    "body": "Second comment",
                    "author": "user2",
                    "score": 5,
                    "createdUtc": 1000000002,
                    "depth": 0
                  }
                ]
              }
            }
          }
        '''),
                200,
              ));

      final detail = await repository.fetchComments('flutter', 'post1');

      expect(detail.post.id, 'post1');
      expect(detail.post.title, 'Test Post');
      expect(detail.post.author, 'testuser');
      expect(detail.comments.length, 2);
      expect(detail.comments[0].id, 'c1');
      expect(detail.comments[0].body, 'First comment');
      expect(detail.comments[1].id, 'c2');
      expect(detail.comments[1].body, 'Second comment');

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/r/flutter/comments/post1'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('passes comment sort query parameter when provided', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('{"props":{"pageProps":{}}}'),
                200,
              ));

      await repository.fetchComments(
        'flutter',
        'post1',
        sort: CommentSort.new_,
      );

      verify(() => mockHttp.get(
            Uri.parse(
                'https://www.reddit.com/r/flutter/comments/post1?sort=new'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('parses vote direction on posts and comments', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('''
          {
            "props": {
              "pageProps": {
                "post": {
                  "id": "p1",
                  "title": "Test",
                  "author": "u",
                  "subreddit": "flutter",
                  "subreddit_id": "t5_2qh30",
                  "permalink": "/r/test/1",
                  "createdUtc": 1000000000,
                  "likes": true
                },
                "comments": [
                  {
                    "id": "c1",
                    "body": "Upvoted",
                    "author": "u",
                    "score": 5,
                    "createdUtc": 1000000001,
                    "depth": 0,
                    "likes": true
                  },
                  {
                    "id": "c2",
                    "body": "Downvoted",
                    "author": "u",
                    "score": 2,
                    "createdUtc": 1000000002,
                    "depth": 0,
                    "likes": false
                  }
                ]
              }
            }
          }
        '''),
                200,
              ));

      final detail = await repository.fetchComments('flutter', 'p1');

      expect(detail.post.vote, VoteDirection.upvote);
      expect(detail.comments[0].vote, VoteDirection.upvote);
      expect(detail.comments[1].vote, VoteDirection.downvote);
    });

    test('throws on API error', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => repository.fetchComments('flutter', 'post1'),
        throwsA(isA<RedditApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });

    test('applies award counts from enricher', () async {
      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                _withNextData('''
          {
            "props": {
              "pageProps": {
                "post": {
                  "id": "post1",
                  "title": "Test Post",
                  "author": "testuser",
                  "subreddit": "flutter",
                  "subreddit_id": "t5_2qh30",
                  "permalink": "/r/flutter/comments/post1/test_post/",
                  "createdUtc": 1000000000
                },
                "comments": [
                  {
                    "id": "c1",
                    "body": "First comment",
                    "author": "user1",
                    "score": 10,
                    "createdUtc": 1000000001,
                    "depth": 0
                  }
                ]
              }
            }
          }
        '''),
                200,
              ));

      final mockEnricher = _MockAwardEnricher();
      when(() => mockEnricher.fetchAwards(
            any(),
            any(),
            sort: any(named: 'sort'),
            sessionCookie: any(named: 'sessionCookie'),
          )).thenAnswer((_) async => {'t3_post1': 7, 't1_c1': 2});

      final repo = CommentRepository(
        client,
        mockMessageClient,
        mockEnricher,
      );
      final detail = await repo.fetchComments('flutter', 'post1');

      expect(detail.post.awardCount, 7);
      expect(detail.comments.single.awardCount, 2);
    });
  });
}
