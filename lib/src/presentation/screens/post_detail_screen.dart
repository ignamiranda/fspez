import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/models/post.dart';
import '../../domain/models/comment.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/comment_tree.dart';
import 'subreddit_feed_screen.dart';

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
    final detailAsync = ref.watch(
      postDetailProvider((
        subreddit: widget.post.subreddit.name,
        postId: widget.post.id,
      )),
    );
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
          detail.comments,
          voteOverrides: voteOverrides,
          saveOverrides: saveOverrides,
          loggedIn: account != null,
        ),
        loading: () => _buildBody(context, const [],
            voteOverrides: voteOverrides, saveOverrides: saveOverrides),
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
    List<Comment> comments, {
    Map<String, VoteDirection> voteOverrides = const {},
    Map<String, bool> saveOverrides = const {},
    bool loggedIn = false,
  }) {
    final theme = Theme.of(context);
    final postFullname = widget.post.fullname;
    final postEffectiveVote = voteOverrides[postFullname];
    final postEffectiveSaved = saveOverrides[postFullname];

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _PostHeader(
                post: widget.post,
                theme: theme,
                effectiveVote: postEffectiveVote,
                onVote: (dir) =>
                    handleVote(ref.read(voteProvider.notifier), postFullname, dir),
                effectiveSaved: postEffectiveSaved,
                onSave: () => handleSave(
                    ref.read(saveProvider.notifier), postFullname, context),
              ),
              if (widget.post.selftext != null &&
                  widget.post.selftext!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.post.selftext!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              if (widget.post.type == PostType.image &&
                  widget.post.url != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.post.url!,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  comments.isEmpty
                      ? 'Comments'
                      : 'Comments (${comments.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No comments yet')),
                )
              else
                ...comments.map((c) => CommentTree(
                      comment: c,
                      voteOverrides: voteOverrides,
                      onVote: (fullname, dir) => handleVote(
                          ref.read(voteProvider.notifier), fullname, dir),
                      saveOverrides: saveOverrides,
                      onSave: (fullname) => handleSave(
                          ref.read(saveProvider.notifier), fullname, context),
                      onReply: loggedIn ? _replyToComment : null,
                    )),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (loggedIn)
          _buildInputBar(theme),
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

class _PostHeader extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final VoteDirection? effectiveVote;
  final ValueChanged<VoteDirection>? onVote;
  final bool? effectiveSaved;
  final VoidCallback? onSave;

  const _PostHeader({
    required this.post,
    required this.theme,
    this.effectiveVote,
    this.onVote,
    this.effectiveSaved,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  post.subreddit.name.isNotEmpty
                      ? post.subreddit.name[0].toUpperCase()
                      : 'r',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SubredditFeedScreen(
                              subredditName: post.subreddit.name,
                            ),
                          ),
                        ),
                        child: Text(
                          'r/${post.subreddit.name}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '· u/${post.author}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo(post.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.isNsfw)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('NSFW',
                      style: TextStyle(fontSize: 9, color: Colors.red)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () => onVote?.call(VoteDirection.upvote),
                child: Icon(
                  (effectiveVote ?? post.vote) == VoteDirection.upvote
                      ? Icons.arrow_upward
                      : Icons.arrow_upward_outlined,
                  size: 16,
                  color: (effectiveVote ?? post.vote) == VoteDirection.upvote
                      ? Colors.orange
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formatCount(post.score),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => onVote?.call(VoteDirection.downvote),
                child: Icon(
                  (effectiveVote ?? post.vote) == VoteDirection.downvote
                      ? Icons.arrow_downward
                      : Icons.arrow_downward_outlined,
                  size: 16,
                  color: (effectiveVote ?? post.vote) == VoteDirection.downvote
                      ? Colors.blue
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: onSave,
                child: Icon(
                  (effectiveSaved ?? post.isSaved)
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                  size: 16,
                  color: (effectiveSaved ?? post.isSaved)
                      ? Colors.amber
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 16),
              const SizedBox(width: 4),
              Text(
                formatCount(post.commentCount),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
