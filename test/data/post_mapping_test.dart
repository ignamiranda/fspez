import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/post_mapping.dart' as post_mapping;
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/post.dart';

void main() {
  group('parseVoteDirection', () {
    test('true returns upvote', () {
      expect(post_mapping.parseVoteDirection(true), VoteDirection.upvote);
    });

    test('false returns downvote', () {
      expect(post_mapping.parseVoteDirection(false), VoteDirection.downvote);
    });

    test('null returns none', () {
      expect(post_mapping.parseVoteDirection(null), VoteDirection.none);
    });
  });

  group('cleanUrl', () {
    test('replaces &amp; with &', () {
      expect(post_mapping.cleanUrl('a&amp;b'), 'a&b');
    });

    test('passes through clean URLs', () {
      expect(
          post_mapping.cleanUrl('https://example.com'), 'https://example.com');
    });
  });

  group('cleanThumbnail', () {
    test('returns null for self', () {
      expect(post_mapping.cleanThumbnail('self'), isNull);
    });

    test('returns null for default', () {
      expect(post_mapping.cleanThumbnail('default'), isNull);
    });

    test('returns null for nsfw', () {
      expect(post_mapping.cleanThumbnail('nsfw'), isNull);
    });

    test('returns null for null', () {
      expect(post_mapping.cleanThumbnail(null), isNull);
    });

    test('cleans valid thumbnail URL', () {
      expect(post_mapping.cleanThumbnail('https://example.com/img&amp;.jpg'),
          'https://example.com/img&.jpg');
    });
  });

  group('subredditIcon', () {
    test('returns icon_img when present', () {
      final srDetail = {'icon_img': 'https://example.com/icon.png'};
      expect(
          post_mapping.subredditIcon(srDetail), 'https://example.com/icon.png');
    });

    test('returns community_icon fallback', () {
      final srDetail = {'community_icon': 'https://example.com/community.png'};
      expect(post_mapping.subredditIcon(srDetail),
          'https://example.com/community.png');
    });

    test('icon_img takes priority over community_icon', () {
      final srDetail = {
        'icon_img': 'https://example.com/icon.png',
        'community_icon': 'https://example.com/community.png',
      };
      expect(
          post_mapping.subredditIcon(srDetail), 'https://example.com/icon.png');
    });

    test('returns null for null srDetail', () {
      expect(post_mapping.subredditIcon(null), isNull);
    });

    test('returns null when both icons are empty', () {
      final srDetail = {'icon_img': ''};
      expect(post_mapping.subredditIcon(srDetail), isNull);
    });

    test('cleans &amp; in icon URLs', () {
      final srDetail = {'icon_img': 'https://example.com/icon&amp;.png'};
      expect(post_mapping.subredditIcon(srDetail),
          'https://example.com/icon&.png');
    });
  });

  group('inferPostType', () {
    test('image hint returns PostType.image', () {
      expect(
        post_mapping.inferPostType(
            postHint: 'image',
            isGallery: false,
            isSelf: false,
            crosspostParent: null),
        PostType.image,
      );
    });

    test('link hint returns PostType.link', () {
      expect(
        post_mapping.inferPostType(
            postHint: 'link',
            isGallery: false,
            isSelf: false,
            crosspostParent: null),
        PostType.link,
      );
    });

    test('hosted:video returns PostType.video', () {
      expect(
        post_mapping.inferPostType(
            postHint: 'hosted:video',
            isGallery: false,
            isSelf: false,
            crosspostParent: null),
        PostType.video,
      );
    });

    test('rich:video returns PostType.video', () {
      expect(
        post_mapping.inferPostType(
            postHint: 'rich:video',
            isGallery: false,
            isSelf: false,
            crosspostParent: null),
        PostType.video,
      );
    });

    test('isGallery returns PostType.gallery', () {
      expect(
        post_mapping.inferPostType(
            postHint: null,
            isGallery: true,
            isSelf: false,
            crosspostParent: null),
        PostType.gallery,
      );
    });

    test('isSelf returns PostType.self_', () {
      expect(
        post_mapping.inferPostType(
            postHint: null,
            isGallery: false,
            isSelf: true,
            crosspostParent: null),
        PostType.self_,
      );
    });

    test('crosspost returns PostType.crosspost', () {
      expect(
        post_mapping.inferPostType(
            postHint: null,
            isGallery: false,
            isSelf: false,
            crosspostParent: 't3_abc'),
        PostType.crosspost,
      );
    });

    test('unknown hint falls back to link', () {
      expect(
        post_mapping.inferPostType(
            postHint: 'unknown',
            isGallery: false,
            isSelf: false,
            crosspostParent: null),
        PostType.link,
      );
    });
  });

  group('parseMediaUrls', () {
    test('returns empty list when no media_metadata', () {
      expect(post_mapping.parseMediaUrls({}), isEmpty);
    });

    test('returns empty list when metadata is null', () {
      expect(post_mapping.parseMediaUrls({'media_metadata': null}), isEmpty);
    });

    test('parses gallery items by media_id order', () {
      final data = {
        'media_metadata': {
          'img1': {
            'status': 'valid',
            's': {'u': 'https://example.com/1.jpg'}
          },
          'img2': {
            'status': 'valid',
            's': {'u': 'https://example.com/2.jpg'}
          },
        },
        'gallery_data': {
          'items': [
            {'media_id': 'img1'},
            {'media_id': 'img2'},
          ],
        },
      };
      final urls = post_mapping.parseMediaUrls(data);
      expect(urls, hasLength(2));
      expect(urls[0], contains('1.jpg'));
      expect(urls[1], contains('2.jpg'));
    });

    test('uses metadata keys when no gallery_data', () {
      final data = {
        'media_metadata': {
          'img1': {
            'status': 'valid',
            's': {'u': 'https://example.com/1.jpg'}
          },
        },
      };
      final urls = post_mapping.parseMediaUrls(data);
      expect(urls, hasLength(1));
      expect(urls[0], contains('1.jpg'));
    });

    test('skips invalid status entries', () {
      final data = {
        'media_metadata': {
          'img1': {
            'status': 'valid',
            's': {'u': 'https://example.com/1.jpg'}
          },
          'img2': {
            'status': 'failed',
            's': {'u': 'https://example.com/2.jpg'}
          },
        },
      };
      final urls = post_mapping.parseMediaUrls(data);
      expect(urls, hasLength(1));
    });
  });

  group('parseVideoUrl', () {
    test('prefers hls_url over fallback_url', () {
      final data = {
        'media': {
          'reddit_video': {
            'hls_url': 'https://example.com/video.m3u8',
            'fallback_url': 'https://example.com/video.mp4',
          },
        },
      };
      expect(post_mapping.parseVideoUrl(data), contains('video.m3u8'));
    });

    test('falls back to fallback_url when hls_url missing', () {
      final data = {
        'media': {
          'reddit_video': {
            'fallback_url': 'https://example.com/video.mp4',
          },
        },
      };
      expect(post_mapping.parseVideoUrl(data), contains('video.mp4'));
    });

    test('returns null when no media', () {
      expect(post_mapping.parseVideoUrl({}), isNull);
    });

    test('returns null when no reddit_video', () {
      final Map<String, dynamic> data = {'media': <String, dynamic>{}};
      expect(post_mapping.parseVideoUrl(data), isNull);
    });

    test('cleans &amp; in video URLs', () {
      final data = {
        'media': {
          'reddit_video': {
            'hls_url': 'https://example.com/video&amp;.m3u8',
          },
        },
      };
      expect(
          post_mapping.parseVideoUrl(data), 'https://example.com/video&.m3u8');
    });
  });

  group('awardCount', () {
    test('returns total_awards_received count', () {
      final data = {'total_awards_received': 5};
      expect(post_mapping.awardCount(data), 5);
    });

    test('falls through to all_awardings when total_awards_received is 0', () {
      final data = {
        'total_awards_received': 0,
        'all_awardings': [
          {'count': 3}
        ],
      };
      expect(post_mapping.awardCount(data), 3);
    });

    test('sums counts from all_awardings', () {
      final data = {
        'all_awardings': [
          {'count': 2},
          {'count': 3},
        ],
      };
      expect(post_mapping.awardCount(data), 5);
    });

    test('counts entries when count is string', () {
      final data = {
        'all_awardings': [
          {'count': '4'},
        ],
      };
      expect(post_mapping.awardCount(data), 4);
    });

    test('falls through to gildings', () {
      final data = {
        'gildings': {'gid_1': 2, 'gid_2': 3},
      };
      expect(post_mapping.awardCount(data), 5);
    });

    test('falls through to gilded', () {
      final data = {'gilded': 1};
      expect(post_mapping.awardCount(data), 1);
    });

    test('returns 0 when no award data', () {
      expect(post_mapping.awardCount({}), 0);
    });
  });
}
