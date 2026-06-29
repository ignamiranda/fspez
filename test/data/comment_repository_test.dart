import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/comment_repository.dart';
import 'package:fspez/src/data/message_client.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/enums/comment_sort.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _MockMessageClient extends Mock implements MessageClient {}

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
    repository = CommentRepository(client, mockMessageClient);
  });

  group('fetchComments', () {
    test('returns post and comments from valid response', () async {
      final responseJson = [
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't3',
                'data': {
                  'id': 'post1',
                  'title': 'Test Post',
                  'author': 'testuser',
                  'subreddit': 'flutter',
                  'subreddit_id': 't5_2qh30',
                  'permalink': '/r/flutter/comments/post1/test_post/',
                  'created_utc': 1000000000,
                  'score': 100,
                  'num_comments': 5,
                },
              },
            ],
          },
        },
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't1',
                'data': {
                  'id': 'c1',
                  'body': 'First comment',
                  'author': 'user1',
                  'score': 10,
                  'created_utc': 1000000001,
                  'depth': 0,
                  'collapsed': false,
                  'replies': '',
                },
              },
              {
                'kind': 't1',
                'data': {
                  'id': 'c2',
                  'body': 'Second comment',
                  'author': 'user2',
                  'score': 5,
                  'created_utc': 1000000002,
                  'depth': 0,
                  'collapsed': false,
                  'replies': '',
                },
              },
            ],
          },
        },
      ];

      when(() => mockHttp.get(
                any(),
                headers: any(named: 'headers'),
              ))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(responseJson), 200));

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
            Uri.parse('https://old.reddit.com/r/flutter/comments/post1.json'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('returns post with default values when post data is missing',
        () async {
      final responseJson = [
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't3',
                'data': {
                  'id': 'post1',
                  'title': 'Test',
                  'author': 'u',
                  'subreddit': 'flutter',
                  'subreddit_id': 't5_2qh30',
                  'permalink': '/r/flutter/comments/post1/test/',
                  'created_utc': 1000000000,
                },
              },
            ],
          },
        },
        {
          'kind': 'Listing',
          'data': {'children': []},
        },
      ];

      when(() => mockHttp.get(
                any(),
                headers: any(named: 'headers'),
              ))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(responseJson), 200));

      final detail = await repository.fetchComments('flutter', 'post1');

      expect(detail.post.id, 'post1');
      expect(detail.comments, isEmpty);
    });

    test('handles nested comment replies', () async {
      final responseJson = [
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't3',
                'data': {
                  'id': 'post1',
                  'title': 'Test',
                  'author': 'u',
                  'subreddit': 'flutter',
                  'subreddit_id': 't5_2qh30',
                  'permalink': '/r/test/1',
                  'created_utc': 1000000000,
                },
              },
            ],
          },
        },
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't1',
                'data': {
                  'id': 'c1',
                  'body': 'Top level',
                  'author': 'u1',
                  'score': 10,
                  'created_utc': 1000000001,
                  'depth': 0,
                  'collapsed': false,
                  'replies': {
                    'kind': 'Listing',
                    'data': {
                      'children': [
                        {
                          'kind': 't1',
                          'data': {
                            'id': 'c2',
                            'body': 'Nested reply',
                            'author': 'u2',
                            'score': 3,
                            'created_utc': 1000000002,
                            'depth': 1,
                            'collapsed': false,
                            'replies': '',
                          },
                        },
                      ],
                    },
                  },
                },
              },
            ],
          },
        },
      ];

      when(() => mockHttp.get(
                any(),
                headers: any(named: 'headers'),
              ))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(responseJson), 200));

      final detail = await repository.fetchComments('flutter', 'post1');

      expect(detail.comments.length, 1);
      expect(detail.comments[0].id, 'c1');
      expect(detail.comments[0].replies.length, 1);
      expect(detail.comments[0].replies[0].id, 'c2');
      expect(detail.comments[0].replies[0].body, 'Nested reply');
    });

    test('passes comment sort query parameter when provided', () async {
      final responseJson = [
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't3',
                'data': {
                  'id': 'post1',
                  'title': 'Test',
                  'author': 'u',
                  'subreddit': 'flutter',
                  'subreddit_id': 't5_2qh30',
                  'permalink': '/r/test/1',
                  'created_utc': 1000000000,
                },
              },
            ],
          },
        },
        {
          'kind': 'Listing',
          'data': {'children': []},
        },
      ];

      when(() => mockHttp.get(
                any(),
                headers: any(named: 'headers'),
              ))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(responseJson), 200));

      await repository.fetchComments(
        'flutter',
        'post1',
        sort: CommentSort.new_,
      );

      verify(() => mockHttp.get(
            Uri.parse(
                'https://old.reddit.com/r/flutter/comments/post1.json?sort=new'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('parses vote direction on comments', () async {
      final responseJson = [
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't3',
                'data': {
                  'id': 'p1',
                  'title': 'Test',
                  'author': 'u',
                  'subreddit': 'flutter',
                  'subreddit_id': 't5_2qh30',
                  'permalink': '/r/test/1',
                  'created_utc': 1000000000,
                  'likes': true,
                },
              },
            ],
          },
        },
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't1',
                'data': {
                  'id': 'c1',
                  'body': 'Upvoted',
                  'author': 'u',
                  'score': 5,
                  'created_utc': 1000000001,
                  'depth': 0,
                  'collapsed': false,
                  'likes': true,
                  'replies': '',
                },
              },
              {
                'kind': 't1',
                'data': {
                  'id': 'c2',
                  'body': 'Downvoted',
                  'author': 'u',
                  'score': 2,
                  'created_utc': 1000000002,
                  'depth': 0,
                  'collapsed': false,
                  'likes': false,
                  'replies': '',
                },
              },
            ],
          },
        },
      ];

      when(() => mockHttp.get(
                any(),
                headers: any(named: 'headers'),
              ))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(responseJson), 200));

      final detail = await repository.fetchComments('flutter', 'p1');

      expect(detail.post.vote, VoteDirection.upvote);
      expect(detail.comments[0].vote, VoteDirection.upvote);
      expect(detail.comments[1].vote, VoteDirection.downvote);
    });

    test('throws on API error', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => repository.fetchComments('flutter', 'post1'),
        throwsA(isA<RedditApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });

    test('applies award counts from html markup', () async {
      final responseJson = [
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't3',
                'data': {
                  'id': 'post1',
                  'title': 'Test Post',
                  'author': 'testuser',
                  'subreddit': 'flutter',
                  'subreddit_id': 't5_2qh30',
                  'permalink': '/r/flutter/comments/post1/test_post/',
                  'created_utc': 1000000000,
                },
              },
            ],
          },
        },
        {
          'kind': 'Listing',
          'data': {
            'children': [
              {
                'kind': 't1',
                'data': {
                  'id': 'c1',
                  'body': 'First comment',
                  'author': 'user1',
                  'score': 10,
                  'created_utc': 1000000001,
                  'depth': 0,
                  'collapsed': false,
                  'replies': '',
                },
              },
            ],
          },
        },
      ];

      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.path.endsWith('.json')) {
          return http.Response(jsonEncode(responseJson), 200);
        }
        if (uri.path.contains('/svc/shreddit/comments/')) {
          return http.Response(
            '<shreddit-comment id="t1_c1" award-count="2"></shreddit-comment>',
            200,
            headers: {'content-type': 'text/html'},
          );
        }
        return http.Response(
          '<shreddit-post id="t3_post1" award-count="7"></shreddit-post><faceplate-partial name="TopComments_test" src="/svc/shreddit/comments/r/flutter/post1?seeker-session=false&render-mode=partial&referer="></faceplate-partial>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final detail = await repository.fetchComments('flutter', 'post1');

      expect(detail.post.awardCount, 7);
      expect(detail.comments.single.awardCount, 2);
    });
  });
}
