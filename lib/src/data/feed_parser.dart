import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/enums/feed_sort.dart';
import '../domain/enums/vote_direction.dart';
import 'api_responses/api_responses.dart';
import 'post_mapping.dart' as post_mapping;

class FeedParser {
  Feed parseFeed(
    Map<String, dynamic> data,
    FeedKind kind,
    FeedSort sort, {
    String? multiredditName,
  }) {
    final listing = ApiListing.fromJson(data);
    return Feed(
      kind: kind,
      sort: sort,
      posts: listing.children.map((api) => api.toDomain()).toList(),
      after: listing.after,
      before: listing.before,
      multiredditName: multiredditName,
    );
  }

  Post parsePost(Map<String, dynamic> data) {
    return ApiPost.fromJson(data).toDomain();
  }

  PostType parsePostType(Map<String, dynamic> data) =>
      post_mapping.inferPostType(
        postHint: data['post_hint'] as String?,
        isGallery: data['is_gallery'] as bool?,
        isSelf: data['is_self'] as bool?,
        crosspostParent: data['crosspost_parent'] as String?,
      );

  VoteDirection parseVote(dynamic likes) =>
      post_mapping.parseVoteDirection(likes);
}
