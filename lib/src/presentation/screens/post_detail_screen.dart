import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../data/auth_providers.dart';
import '../../data/app_settings.dart';
import '../../data/comment_providers.dart';
import '../../data/write_providers.dart';
import '../../data/comment_repository.dart';
import '../../domain/enums/comment_sort.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/interaction_helpers.dart';
import '../utils/open_url.dart';
import '../widgets/bottom_sheet_menu.dart';
import '../widgets/comment_composer_sheet.dart';
import '../widgets/comment_tree.dart';
import '../widgets/edit_sheet.dart';
import '../widgets/media_viewer.dart';
import '../widgets/post_actions.dart';
import '../widgets/post_media_tile.dart';
import '../widgets/reddit_body.dart';
import 'subreddit_feed_screen.dart';
import 'user_profile_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  CommentSort _commentSort = CommentSort.best;
  bool _sensitiveRevealed = false;

  @override
  void initState() {
    super.initState();
    _commentSort =
        ref.read(appSettingsProvider).defaultCommentSort ?? CommentSort.best;
  }

  ({String subreddit, String postId, CommentSort sort}) _postDetailParams(
      [Post? post]) {
    final target = post ?? widget.post;
    return (
      subreddit: target.subreddit.name,
      postId: target.id,
      sort: _commentSort,
    );
  }

  void _openComposer({
    String? thingId,
    String? parentAuthor,
    String? parentBody,
  }) {
    showCommentComposerSheet(
      context,
      thingId: thingId ?? widget.post.fullname,
      parentAuthor: parentAuthor,
      parentBody: parentBody,
    ).then((posted) {
      if (posted == true && context.mounted) {
        ref.invalidate(postDetailProvider(_postDetailParams()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _replyToComment(String commentId, String author, String? body) {
    _openComposer(
      thingId: commentId,
      parentAuthor: author,
      parentBody: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(activeAccountProvider);
    final detailAsync = ref.watch(postDetailProvider(_postDetailParams()));
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'r/${widget.post.subreddit.name}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      body: detailAsync.when(
        data: (detail) => _buildBody(
          context,
          detail,
          voteOverrides: voteOverrides,
          saveOverrides: saveOverrides,
          loggedIn: account != null,
        ),
        loading: () => _buildBody(context, null,
            voteOverrides: voteOverrides,
            saveOverrides: saveOverrides,
            commentsLoading: true),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 8),
                Text('Failed to load comments',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PostDetail? detail, {
    Map<String, VoteDirection> voteOverrides = const {},
    Map<String, bool> saveOverrides = const {},
    bool loggedIn = false,
    bool commentsLoading = false,
  }) {
    final theme = Theme.of(context);
    final comments = detail?.comments ?? const [];
    final post = detail?.post ?? widget.post;
    final postFullname = post.fullname;
    final postEffectiveVote = voteOverrides[postFullname];
    final postEffectiveSaved = saveOverrides[postFullname];
    final actions = ref.read(postActionsServiceProvider);
    final username = ref.read(activeAccountProvider)?.username;
    final settings = ref.watch(appSettingsProvider);
    final shouldBlur = !_sensitiveRevealed &&
        ((post.isNsfw && settings.nsfwBlur) ||
            (post.isSpoiler && settings.spoilerBlur));
    final showAwards = settings.showAwards;

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _PostDetailHeader(
                post: post,
                theme: theme,
                showAwards: showAwards,
                effectiveVote: postEffectiveVote,
                onVote: (dir) => handleVote(actions, postFullname, dir),
                effectiveSaved: postEffectiveSaved,
                onSave: () {
                  final wasSaved = saveOverrides[postFullname] ?? post.isSaved;
                  handleSave(actions, postFullname, context,
                      wasSaved: wasSaved);
                },
                onEdit: username != null && post.author == username
                    ? () {
                        showEditSheet(context,
                                currentText: post.selftext ?? '',
                                readOnlyTitle: post.title,
                                thingId: postFullname)
                            .then((saved) {
                          if (saved == true && context.mounted) {
                            ref.invalidate(
                                postDetailProvider(_postDetailParams(post)));
                          }
                        });
                      }
                    : null,
                onDelete: username != null && post.author == username
                    ? () => handleDelete(context, actions, postFullname)
                    : null,
              ),
              if (post.selftext != null && post.selftext!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: RedditBody(post.selftext!),
                ),
              if (post.videoUrl != null)
                _SensitiveMediaPreview(
                  isSensitive: shouldBlur,
                  isNsfw: post.isNsfw,
                  isSpoiler: post.isSpoiler,
                  onReveal: () => setState(() => _sensitiveRevealed = true),
                  child: PostMediaTile(
                    imageUrl: post.thumbnailUrl ??
                        (post.mediaUrls.isNotEmpty ? post.mediaUrls.first : ''),
                    isVideo: true,
                    onTap: () => MediaViewer.show(
                      context,
                      imageUrls: post.mediaUrls,
                      videoUrl: post.videoUrl,
                      isNsfw: post.isNsfw,
                      isSpoiler: post.isSpoiler,
                      initiallyRevealed: _sensitiveRevealed,
                    ),
                  ),
                )
              else if (post.mediaUrls.length >= 2)
                _SensitiveMediaPreview(
                  isSensitive: shouldBlur,
                  isNsfw: post.isNsfw,
                  isSpoiler: post.isSpoiler,
                  onReveal: () => setState(() => _sensitiveRevealed = true),
                  child: PostMediaTile(
                    imageUrl: post.mediaUrls.first,
                    badgeText: '${post.mediaUrls.length}',
                    onTap: () => MediaViewer.show(
                      context,
                      imageUrls: post.mediaUrls,
                      isNsfw: post.isNsfw,
                      isSpoiler: post.isSpoiler,
                      initiallyRevealed: _sensitiveRevealed,
                    ),
                  ),
                )
              else if (post.mediaUrls.length == 1)
                _SensitiveMediaPreview(
                  isSensitive: shouldBlur,
                  isNsfw: post.isNsfw,
                  isSpoiler: post.isSpoiler,
                  onReveal: () => setState(() => _sensitiveRevealed = true),
                  child: PostMediaTile(
                    imageUrl: post.mediaUrls.first,
                    onTap: () => MediaViewer.show(
                      context,
                      imageUrls: post.mediaUrls,
                      isNsfw: post.isNsfw,
                      isSpoiler: post.isSpoiler,
                      initiallyRevealed: _sensitiveRevealed,
                    ),
                  ),
                )
              else if (post.type == PostType.image && post.url != null)
                _SensitiveMediaPreview(
                  isSensitive: shouldBlur,
                  isNsfw: post.isNsfw,
                  isSpoiler: post.isSpoiler,
                  onReveal: () => setState(() => _sensitiveRevealed = true),
                  child: PostMediaTile(
                    imageUrl: post.url!,
                    onTap: () => MediaViewer.show(
                      context,
                      imageUrls: [post.url!],
                      isNsfw: post.isNsfw,
                      isSpoiler: post.isSpoiler,
                      initiallyRevealed: _sensitiveRevealed,
                    ),
                  ),
                )
              else if (post.type == PostType.link && post.url != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: InkWell(
                    onTap: () => openUrl(post.url!),
                    child: Text(
                      post.url!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      comments.isEmpty
                          ? 'Comments'
                          : 'Comments (${comments.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final sort = await showRadioBottomSheet<CommentSort>(
                          context,
                          title: 'Sort comments',
                          currentValue: _commentSort,
                          values: CommentSort.values,
                          labelFn: (s) => s.label,
                        );
                        if (sort != null && sort != _commentSort) {
                          setState(() => _commentSort = sort);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort, size: 18),
                            const SizedBox(width: 4),
                            Text(_commentSort.label),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (commentsLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No comments yet')),
                )
              else
                ...comments.map((c) => CommentTree(
                      comment: c,
                      showAwards: showAwards,
                      voteOverrides: voteOverrides,
                      onVote: (fullname, dir) =>
                          handleVote(actions, fullname, dir),
                      saveOverrides: saveOverrides,
                      onSave: (fullname) =>
                          handleSave(actions, fullname, context),
                      onReply: loggedIn ? _replyToComment : null,
                      onAuthorTap: (author) {
                        if (author != '[deleted]') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfileScreen(username: author),
                            ),
                          );
                        }
                      },
                      onEdit: username != null && c.author == username
                          ? (fullname) {
                              showEditSheet(context,
                                      currentText: c.body, thingId: fullname)
                                  .then((saved) {
                                if (saved == true && context.mounted) {
                                  ref.invalidate(postDetailProvider(
                                      _postDetailParams(post)));
                                }
                              });
                            }
                          : null,
                      onDelete: username != null && c.author == username
                          ? (fullname) {
                              handleDelete(context, actions, fullname)
                                  .then((deleted) {
                                if (deleted && context.mounted) {
                                  ref.invalidate(postDetailProvider(
                                      _postDetailParams(post)));
                                }
                              });
                            }
                          : null,
                    )),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (loggedIn) _buildInputBar(theme, postFullname),
      ],
    );
  }

  Widget _buildInputBar(ThemeData theme, String postFullname) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: InkWell(
        onTap: () => _openComposer(thingId: postFullname),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(Icons.edit_outlined,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Add a comment...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetailHeader extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final bool showAwards;
  final VoteDirection? effectiveVote;
  final ValueChanged<VoteDirection>? onVote;
  final bool? effectiveSaved;
  final VoidCallback? onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PostDetailHeader({
    required this.post,
    required this.theme,
    required this.showAwards,
    this.effectiveVote,
    this.onVote,
    this.effectiveSaved,
    this.onSave,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            post: post,
            showAwards: showAwards,
            onSubredditTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SubredditFeedScreen(
                  subredditName: post.subreddit.name,
                ),
              ),
            ),
            onAuthorTap: post.author != '[deleted]'
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            UserProfileScreen(username: post.author),
                      ),
                    )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          PostActions(
            post: post,
            effectiveVote: effectiveVote,
            onVote: onVote,
            effectiveSaved: effectiveSaved,
            onSave: onSave,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SensitiveMediaPreview extends StatelessWidget {
  final bool isSensitive;
  final bool isNsfw;
  final bool isSpoiler;
  final VoidCallback onReveal;
  final Widget child;

  const _SensitiveMediaPreview({
    required this.isSensitive,
    required this.isNsfw,
    required this.isSpoiler,
    required this.onReveal,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSensitive) return child;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onReveal,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: child,
          ),
          Container(color: Colors.black54),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isNsfw)
                    _SensitivePill(
                      label: 'NSFW',
                      color: theme.colorScheme.error,
                    ),
                  if (isNsfw && isSpoiler) const SizedBox(width: 6),
                  if (isSpoiler)
                    _SensitivePill(
                      label: 'Spoiler',
                      color: theme.colorScheme.tertiary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to reveal',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensitivePill extends StatelessWidget {
  final String label;
  final Color color;

  const _SensitivePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
