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
  final void Function(Post post)? onPostEdit;
  final void Function(Post post)? onPostDelete;
  final void Function(Post post)? onPostHide;
  final void Function(Post post)? onPostUnhide;
  final Set<String> hiddenFullnames;
  final String? currentUsername;
  final void Function(Post post)? onPostTap;
  final void Function(Post post)? onSubredditTap;
  final void Function(Post post)? onAuthorTap;
  final bool showStickiedIndicator;
  final String emptyMessage;
  final ScrollController? scrollController;
  final Widget? footer;
  final Future<void> Function()? onRefresh;

  const PostList({
    super.key,
    required this.posts,
    this.voteOverrides = const {},
    this.saveOverrides = const {},
    this.onPostVote,
    this.onPostSave,
    this.onPostEdit,
    this.onPostDelete,
    this.onPostHide,
    this.onPostUnhide,
    this.hiddenFullnames = const {},
    this.currentUsername,
    this.onPostTap,
    this.onSubredditTap,
    this.onAuthorTap,
    this.showStickiedIndicator = false,
    this.emptyMessage = 'No posts yet.',
    this.scrollController,
    this.footer,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final visiblePosts = hiddenFullnames.isEmpty
        ? posts
        : posts.where((p) => !hiddenFullnames.contains(p.fullname)).toList();

    if (visiblePosts.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final listView = ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: visiblePosts.length + (footer != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (footer != null && index == visiblePosts.length) {
          return footer!;
        }
        final post = visiblePosts[index];
        final fullname = post.fullname;
        return PostCard(
          post: post,
          effectiveVote: voteOverrides[fullname],
          onVote:
              onPostVote != null ? (dir) => onPostVote!(fullname, dir) : null,
          effectiveSaved: saveOverrides[fullname],
          onSave: onPostSave != null ? () => onPostSave!(fullname) : null,
          onEdit: onPostEdit != null && post.author == currentUsername
              ? () => onPostEdit!(post)
              : null,
          onDelete: onPostDelete != null && post.author == currentUsername
              ? () => onPostDelete!(post)
              : null,
          onHide: onPostHide != null && !hiddenFullnames.contains(post.fullname)
              ? () => onPostHide!(post)
              : null,
          onUnhide: onPostUnhide != null ? () => onPostUnhide!(post) : null,
          onTap: onPostTap != null ? () => onPostTap!(post) : null,
          showStickiedIndicator: showStickiedIndicator,
          onSubredditTap:
              onSubredditTap != null ? () => onSubredditTap!(post) : null,
          onAuthorTap: onAuthorTap != null ? () => onAuthorTap!(post) : null,
        );
      },
    );

    if (onRefresh == null) return listView;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: listView,
    );
  }
}
