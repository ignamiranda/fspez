import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/feed_parser.dart';
import 'package:fspez/src/domain/models/feed.dart';
import 'package:fspez/src/domain/models/post.dart';
import 'package:fspez/src/domain/enums/feed_sort.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';

void main() {
  late FeedParser parser;

  setUp(() {
    parser = FeedParser();
  });

  group('parseVote', () {
    test('true returns upvote', () {
      expect(parser.parseVote(true), VoteDirection.upvote);
    });

    test('false returns downvote', () {
      expect(parser.parseVote(false), VoteDirection.downvote);
    });

    test('null returns none', () {
      expect(parser.parseVote(null), VoteDirection.none);
    });
  });

  group('parsePostType', () {
    test('image hint returns PostType.image', () {
      expect(
        parser.parsePostType({'post_hint': 'image'}),
        PostType.image,
      );
    });

    test('is_gallery returns PostType.gallery', () {
      expect(
        parser.parsePostType({'is_gallery': true}),
        PostType.gallery,
      );
    });

    test('is_self returns PostType.self_', () {
      expect(
        parser.parsePostType({'is_self': true}),
        PostType.self_,
      );
    });

    test('crosspost_parent returns PostType.crosspost', () {
      expect(
        parser.parsePostType({'crosspost_parent': 't3_abc'}),
        PostType.crosspost,
      );
    });

    test('unknown hint returns PostType.link', () {
      expect(
        parser.parsePostType({}),
        PostType.link,
      );
    });
  });

  group('parsePost', () {
    test('parses minimal post data', () {
      final data = {
        'id': 'abc123',
        'title': 'Test Post',
        'author': 'testuser',
        'subreddit': 'flutter',
        'subreddit_id': 't5_2qh30',
        'selftext': '',
        'url': 'https://example.com',
        'thumbnail': 'self',
        'score': 42,
        'num_comments': 7,
        'over_18': false,
        'spoiler': false,
        'saved': false,
        'stickied': false,
        'locked': false,
        'permalink': '/r/flutter/comments/abc123/test_post/',
        'created_utc': 1000000000,
      };

      final post = parser.parsePost(data);

      expect(post.id, 'abc123');
      expect(post.title, 'Test Post');
      expect(post.author, 'testuser');
      expect(post.subreddit.name, 'flutter');
      expect(post.subreddit.id, 't5_2qh30');
      expect(post.score, 42);
      expect(post.commentCount, 7);
      expect(post.type, PostType.link);
      expect(post.vote, VoteDirection.none);
      expect(post.isNsfw, false);
      expect(post.permalink, '/r/flutter/comments/abc123/test_post/');
      expect(post.createdAt, DateTime.fromMillisecondsSinceEpoch(1000000000000));
    });

    test('handles deleted author', () {
      final data = {
        'id': 'abc',
        'title': 'Test',
        'permalink': '/r/test/',
        'created_utc': 1000000000,
      };

      final post = parser.parsePost(data);

      expect(post.author, '[deleted]');
      expect(post.subreddit.name, '');
    });

    test('parses subreddit icon from sr_detail', () {
      final data = {
        'id': 'abc',
        'title': 'Post with icon',
        'permalink': '/r/test/abc',
        'created_utc': 1000000000,
        'subreddit': 'flutter',
        'sr_detail': {
          'icon_img': 'https://example.com/icon.png',
        },
      };

      final post = parser.parsePost(data);

      expect(post.subreddit.iconUrl, 'https://example.com/icon.png');
    });

    test('parses subreddit community_icon fallback', () {
      final data = {
        'id': 'abc',
        'title': 'Post with community icon',
        'permalink': '/r/test/abc',
        'created_utc': 1000000000,
        'subreddit': 'flutter',
        'sr_detail': {
          'community_icon': 'https://example.com/community.png',
        },
      };

      final post = parser.parsePost(data);

      expect(post.subreddit.iconUrl, 'https://example.com/community.png');
    });

    test('cleans &amp; from icon URLs', () {
      final data = {
        'id': 'abc',
        'title': 'Post with encoded URL',
        'permalink': '/r/test/abc',
        'created_utc': 1000000000,
        'subreddit': 'flutter',
        'sr_detail': {
          'community_icon': 'https://example.com/icon.png?width=256&amp;s=abc123',
        },
      };

      final post = parser.parsePost(data);

      expect(post.subreddit.iconUrl, 'https://example.com/icon.png?width=256&s=abc123');
    });

    test('subreddit icon is null when no sr_detail', () {
      final data = {
        'id': 'abc',
        'title': 'Post no icon',
        'permalink': '/r/test/abc',
        'created_utc': 1000000000,
        'subreddit': 'flutter',
      };

      final post = parser.parsePost(data);

      expect(post.subreddit.iconUrl, isNull);
    });

    test('parses vote direction', () {
      final upvoted = parser.parsePost({
        'id': '1',
        'title': 'Upvoted',
        'permalink': '/r/test/1',
        'created_utc': 1000000000,
        'likes': true,
      });
      expect(upvoted.vote, VoteDirection.upvote);

      final downvoted = parser.parsePost({
        'id': '2',
        'title': 'Downvoted',
        'permalink': '/r/test/2',
        'created_utc': 1000000000,
        'likes': false,
      });
      expect(downvoted.vote, VoteDirection.downvote);
    });
  });

  group('parseFeed', () {
    test('parses a feed with posts', () {
      final data = {
        'data': {
          'children': [
            {
              'kind': 't3',
              'data': {
                'id': 'post1',
                'title': 'Post 1',
                'permalink': '/r/test/1',
                'created_utc': 1000000000,
              },
            },
            {
              'kind': 't3',
              'data': {
                'id': 'post2',
                'title': 'Post 2',
                'permalink': '/r/test/2',
                'created_utc': 1000000000,
              },
            },
          ],
          'after': 't3_after_cursor',
          'before': null,
        },
      };

      final feed = parser.parseFeed(data, FeedKind.home, FeedSort.hot);

      expect(feed.kind, FeedKind.home);
      expect(feed.sort, FeedSort.hot);
      expect(feed.posts.length, 2);
      expect(feed.posts[0].id, 'post1');
      expect(feed.posts[1].id, 'post2');
      expect(feed.after, 't3_after_cursor');
      expect(feed.before, isNull);
      expect(feed.hasMorePages, true);
    });
  });
}
