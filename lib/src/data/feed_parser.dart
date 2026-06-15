import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/enums/feed_sort.dart';
import '../domain/enums/vote_direction.dart';
import 'api_responses/api_responses.dart';
import 'parsers/shared_parsers.dart';

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

  PostType parsePostType(Map<String, dynamic> data) => postTypeFromMap(data);

  VoteDirection parseVote(dynamic likes) => parseVoteDirection(likes);
}
