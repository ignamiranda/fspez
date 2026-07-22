import '../domain/enums/vote_direction.dart';
import '../domain/models/post.dart';

List<String> parseMediaUrls(Map<String, dynamic> data) {
  final metadata = data['media_metadata'] as Map<String, dynamic>?;
  if (metadata == null) return const [];

  List<String> ids;
  final galleryData = data['gallery_data'] as Map<String, dynamic>?;
  final items = galleryData?['items'] as List<dynamic>?;
  if (items != null && items.isNotEmpty) {
    ids = items
        .map((item) => (item as Map<String, dynamic>)['media_id'] as String?)
        .whereType<String>()
        .toList();
  } else {
    ids = metadata.keys.toList();
  }

  final urls = <String>[];
  for (final id in ids) {
    final entry = metadata[id] as Map<String, dynamic>?;
    if (entry == null) continue;
    if (entry['status'] == 'valid') {
      final s = entry['s'] as Map<String, dynamic>?;
      if (s != null) {
        final u = s['u'] as String?;
        if (u != null) {
          urls.add(cleanUrl(u));
          continue;
        }
      }
      final previews = entry['p'] as List<dynamic>?;
      if (previews != null && previews.isNotEmpty) {
        final last = previews.last as Map<String, dynamic>;
        final u = last['u'] as String?;
        if (u != null) {
          urls.add(cleanUrl(u));
        }
      }
    }
  }
  return urls;
}

String? parseVideoUrl(Map<String, dynamic> data) {
  final media = data['media'] as Map<String, dynamic>?;
  if (media == null) return null;
  final redditVideo = media['reddit_video'] as Map<String, dynamic>?;
  if (redditVideo == null) return null;
  // Prefer HLS URL which includes audio tracks (fallback_url is video-only DASH)
  final hlsUrl = redditVideo['hls_url'] as String?;
  if (hlsUrl != null) return cleanUrl(hlsUrl);
  final fallbackUrl = redditVideo['fallback_url'] as String?;
  if (fallbackUrl == null) return null;
  return cleanUrl(fallbackUrl);
}

PostType inferPostType({
  required String? postHint,
  required bool? isGallery,
  required bool? isSelf,
  required String? crosspostParent,
}) {
  final hint = postHint;
  if (hint == 'image') return PostType.image;
  if (hint == 'link') return PostType.link;
  if (hint == 'hosted:video') return PostType.video;
  if (hint == 'rich:video') return PostType.video;
  if (isGallery == true) return PostType.gallery;
  if (isSelf == true) return PostType.self_;
  if (crosspostParent != null) return PostType.crosspost;
  return PostType.link;
}

String? subredditIcon(Map<String, dynamic>? srDetail) {
  if (srDetail == null) return null;
  final icon = srDetail['icon_img'] as String?;
  if (icon != null && icon.isNotEmpty) return cleanUrl(icon);
  final communityIcon = srDetail['community_icon'] as String?;
  if (communityIcon != null && communityIcon.isNotEmpty) {
    return cleanUrl(communityIcon);
  }
  return null;
}

String? cleanThumbnail(String? thumbnail) {
  if (thumbnail == null ||
      thumbnail == 'self' ||
      thumbnail == 'default' ||
      thumbnail == 'nsfw') {
    return null;
  }
  return cleanUrl(thumbnail);
}

String cleanUrl(String url) => url.replaceAll('&amp;', '&');

VoteDirection parseVoteDirection(dynamic likes) {
  if (likes == true) return VoteDirection.upvote;
  if (likes == false) return VoteDirection.downvote;
  return VoteDirection.none;
}

int awardCount(Map<String, dynamic> data) {
  final totalAwards = data['total_awards_received'];
  if (totalAwards is num) {
    final count = totalAwards.toInt();
    if (count > 0) return count;
  }

  final allAwardings = data['all_awardings'];
  if (allAwardings is List) {
    final counted = allAwardings.whereType<Map<String, dynamic>>().fold<int>(0,
        (sum, award) {
      final count = award['count'];
      if (count is num) return sum + count.toInt();
      if (count is String) {
        final parsed = int.tryParse(count);
        if (parsed != null) return sum + parsed;
      }
      return sum + 1;
    });
    if (counted > 0) return counted;

    if (allAwardings.isNotEmpty) return allAwardings.length;
  }

  final gildings = data['gildings'];
  if (gildings is Map<String, dynamic>) {
    final count = gildings.values
        .whereType<num>()
        .fold<int>(0, (sum, value) => sum + value.toInt());
    if (count > 0) return count;
  }

  final gilded = data['gilded'];
  if (gilded is num) return gilded.toInt();

  return 0;
}
