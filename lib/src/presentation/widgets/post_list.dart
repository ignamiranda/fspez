import 'package:flutter/material.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import 'post_card.dart';

class PostList extends StatelessWidget {
  final List<Post> posts;
  final Map<String, VoteDirection> voteOverrides;
  final Map<String, bool> saveOverrides;
  final void Function(String fullname, VoteDirection direction)? onPostVote;
  final void Function(String fullname)? onPostSave;
  final void Function(Post post)? onPostTap;
  final String emptyMessage;

  const PostList({
    super.key,
    required this.posts,
    this.voteOverrides = const {},
    this.saveOverrides = const {},
    this.onPostVote,
    this.onPostSave,
    this.onPostTap,
    this.emptyMessage = 'No posts yet.',
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.separated(
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = posts[index];
        final fullname = 't3_${post.id}';
        return PostCard(
          post: post,
          effectiveVote: voteOverrides[fullname],
          onVote: onPostVote != null
              ? (dir) => onPostVote!(fullname, dir)
              : null,
          effectiveSaved: saveOverrides[fullname],
          onSave: onPostSave != null
              ? () => onPostSave!(fullname)
              : null,
          onTap: onPostTap != null ? () => onPostTap!(post) : null,
        );
      },
    );
  }
}
