import '../../domain/enums/vote_direction.dart';
import '../../domain/models/post.dart';

VoteDirection parseVoteDirection(dynamic likes) {
  if (likes == true) return VoteDirection.upvote;
  if (likes == false) return VoteDirection.downvote;
  return VoteDirection.none;
}

PostType postTypeFromMap(Map<String, dynamic> data) {
  final hint = data['post_hint'] as String?;
  if (hint == 'image') return PostType.image;
  if (hint == 'link') return PostType.link;
  if (hint == 'hosted:video') return PostType.video;
  if (hint == 'rich:video') return PostType.video;
  if (data['is_gallery'] == true) return PostType.gallery;
  if (data['is_self'] == true) return PostType.self_;
  if (data['crosspost_parent'] != null) return PostType.crosspost;
  return PostType.link;
}
