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
import '../widgets/comment_tree.dart';
import '../widgets/edit_sheet.dart';
import '../widgets/media_viewer.dart';
import '../widgets/post_actions.dart';
import 'subreddit_feed_screen.dart';
import 'user_profile_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;
  String? _replyToId;
  String? _replyToName;
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final account = ref.read(activeAccountProvider);
    if (account == null) return;

    setState(() => _isSending = true);
    try {
      final repo = ref.read(commentRepositoryProvider);
      await repo.reply(
        thingId: _replyToId ?? widget.post.fullname,
        text: text,
        sessionCookie: account.sessionCookie,
      );
      _commentController.clear();
      setState(() {
        _isSending = false;
        _replyToId = null;
        _replyToName = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
      setState(() => _isSending = false);
    }
  }

  void _replyToComment(String commentId, String author) {
    setState(() {
      _replyToId = commentId;
      _replyToName = author;
    });
    _commentController.text = '';
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
                  child: Text(
                    post.selftext!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              if (post.videoUrl != null)
                _SensitiveMediaPreview(
                  isSensitive: shouldBlur,
                  isNsfw: post.isNsfw,
                  isSpoiler: post.isSpoiler,
                  onReveal: () => setState(() => _sensitiveRevealed = true),
                  child: _PostMediaTile(
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
                  child: _PostMediaTile(
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
                  child: _PostMediaTile(
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
                  child: _PostMediaTile(
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
        if (loggedIn) _buildInputBar(theme),
      ],
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          if (_replyToName != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text('@$_replyToName',
                    style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() {
                  _replyToId = null;
                  _replyToName = null;
                }),
                visualDensity: VisualDensity.compact,
              ),
            ),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: _replyToName != null
                    ? 'Reply to @$_replyToName...'
                    : 'Add a comment...',
                border: InputBorder.none,
                isDense: true,
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          if (_isSending)
            const SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendComment,
            ),
        ],
      ),
    );
  }
}

/// A tappable media tile used in post detail for images and galleries.
class _PostMediaTile extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isVideo;

  const _PostMediaTile({
    required this.imageUrl,
    required this.onTap,
    this.badgeText,
    this.isVideo = false,
  });

  @override
  State<_PostMediaTile> createState() => _PostMediaTileState();
}

class _PostMediaTileState extends State<_PostMediaTile> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _imageSize;
  String? _resolvedImageUrl;
  bool _errored = false;

  static const double _longImageAspectRatioThreshold = 0.25;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedImageUrl != widget.imageUrl) {
      _resolveImageSize();
    }
  }

  @override
  void didUpdateWidget(_PostMediaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageSize = null;
      _resolvedImageUrl = null;
      _errored = false;
      _resolveImageSize();
    }
  }

  @override
  void dispose() {
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  void _resolveImageSize() {
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }

    _imageSize = null;
    _resolvedImageUrl = widget.imageUrl;
    final provider = NetworkImage(widget.imageUrl);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      },
      onError: (_, __) {
        if (mounted) setState(() => _errored = true);
      },
    );
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  bool get _isLongImage {
    final size = _imageSize;
    if (size == null || size.width == 0) return false;
    return size.width / size.height < _longImageAspectRatioThreshold;
  }

  @override
  Widget build(BuildContext context) {
    if (_imageSize == null && !_errored) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          height: 180,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final theme = Theme.of(context);
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isLongImage && !widget.isVideo)
              Image.network(
                widget.imageUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final total = loadingProgress.expectedTotalBytes?.toDouble();
                  final progress = total != null
                      ? loadingProgress.cumulativeBytesLoaded / total
                      : null;
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                        value: progress,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (widget.isVideo)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            if (_isLongImage && !widget.isVideo)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Long image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (widget.badgeText != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        widget.badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_errored)
              const Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 48),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GestureDetector(onTap: widget.onTap, child: child),
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
            showAwards: showAwards,
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
