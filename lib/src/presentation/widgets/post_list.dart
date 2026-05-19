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
  final void Function(Post post)? onSubredditTap;
  final String emptyMessage;
  final ScrollController? scrollController;
  final Widget? footer;

  const PostList({
    super.key,
    required this.posts,
    this.voteOverrides = const {},
    this.saveOverrides = const {},
    this.onPostVote,
    this.onPostSave,
    this.onPostTap,
    this.onSubredditTap,
    this.emptyMessage = 'No posts yet.',
    this.scrollController,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final hasFooter = footer != null;
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: posts.length + (hasFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasFooter && index == posts.length) return footer!;
        final post = posts[index];
        final fullname = post.fullname;
        return Column(
          children: [
            if (index > 0) const Divider(height: 1),
            PostCard(
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
              onSubredditTap: onSubredditTap != null
                  ? () => onSubredditTap!(post)
                  : null,
            ),
          ],
        );
      },
    );
  }
}
