import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../../data/user_providers.dart';
import '../../data/write_providers.dart';
import '../../domain/enums/comment_sort.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/models/post.dart';
import '../../domain/models/subreddit.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/comment.dart';
import '../utils/block_user_helpers.dart';
import '../utils/infinite_scroll.dart';
import '../utils/format_utils.dart';
import '../utils/profile_formatters.dart';
import '../widgets/bottom_sheet_menu.dart';
import '../widgets/feed_screen_scaffold.dart';
import 'post_detail_screen.dart';
import '../widgets/report_sheet.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FeedSort _postsSort = FeedSort.new_;
  CommentSort _commentsSort = CommentSort.new_;
  List<Comment> _comments = [];
  bool _commentsLoading = true;
  String? _commentsError;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _scrollController = _createPostsScrollController();
    _loadComments();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  FeedPageConfig _postsConfig() {
    return FeedPageConfig.user(widget.username, sort: _postsSort);
  }

  ScrollController _createPostsScrollController() {
    return createInfiniteScrollController(
      () => ref.read(feedPageProvider(_postsConfig()).notifier).loadMore(),
    );
  }

  Future<void> _showSortMenu() async {
    if (_tabController.index == 2) return;

    if (_tabController.index == 0) {
      final sort = await showRadioBottomSheet<FeedSort>(
        context,
        title: 'Sort posts',
        currentValue: _postsSort,
        values: FeedSort.values,
        labelFn: (s) => s.label,
      );
      if (sort != null && sort != _postsSort) {
        final oldController = _scrollController;
        setState(() {
          _postsSort = sort;
          _scrollController = _createPostsScrollController();
        });
        oldController?.dispose();
      }
      return;
    }

    final sort = await showRadioBottomSheet<CommentSort>(
      context,
      title: 'Sort comments',
      currentValue: _commentsSort,
      values: CommentSort.values,
      labelFn: (s) => s.label,
    );
    if (sort != null && sort != _commentsSort) {
      setState(() {
        _commentsSort = sort;
      });
      await _loadComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _commentsLoading = true;
      _commentsError = null;
    });
    try {
      final repo = ref.read(userRepositoryProvider);
      final sessionCookie = ref.read(activeAccountProvider)?.sessionCookie;
      final comments = await repo.fetchComments(
        widget.username,
        sort: _commentsSort,
        sessionCookie: sessionCookie,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _commentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = e.toString();
          _commentsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.username));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('u/${widget.username}'),
        actions: [
          if (_tabController.index != 2)
            IconButton(
              icon: const Icon(Icons.sort),
              tooltip: _tabController.index == 0
                  ? 'Sort posts'
                  : 'Sort comments',
              onPressed: _showSortMenu,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showPostActionSheet(
              context,
              primaryActions: [
                BottomSheetAction(
                  icon: Icons.flag_outlined,
                  label: 'Report u/${widget.username}',
                  onTap: () {
                    Navigator.of(context).pop();
                    showReportSheet(
                      context,
                      thingId: 't2_${widget.username}',
                      subreddit: null,
                    );
                  },
                ),
              ],
              authorActions: [],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Comments'),
            Tab(text: 'About'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildCommentsTab(theme),
          _buildAboutTab(profileAsync, theme),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    final config = _postsConfig();

    return FeedScreenScaffold(
      config: config,
      scrollController: _scrollController!,
      emptyMessage: 'No posts yet.',
    );
  }

  Widget _buildCommentsTab(ThemeData theme) {
    if (_commentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_commentsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text('Failed to load comments', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadComments, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No comments yet.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.separated(
        key: ValueKey(_commentsSort),
        itemCount: _comments.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: theme.dividerColor),
        itemBuilder: (context, index) {
          final comment = _comments[index];
          return InkWell(
            onTap: () {
              final postId = comment.postId.replaceFirst('t3_', '');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    post: _buildMinimalPost(comment, postId),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'r/${comment.subreddit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo(comment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.linkTitle ?? '',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${comment.score}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutTab(AsyncValue<UserProfile> profileAsync, ThemeData theme) {
    return profileAsync.when(
      data: (profile) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: profile.iconUrl != null
                      ? NetworkImage(profile.iconUrl!)
                      : null,
                  child: profile.iconUrl == null
                      ? Text(
                          profile.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'u/${profile.username}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (profile.isGold)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Gold',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                if (ref.watch(blockActionProvider)[profile.username] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Blocked',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  formatRedditAccountAge(profile.createdAt),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatProfileKarmaBreakdown(
                    profile.linkKarma,
                    profile.commentKarma,
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (profile.isMod) ...[
            _InfoRow(
              label: 'Moderator',
              value: profile.subredditName != null
                  ? 'r/${profile.subredditName}'
                  : 'Yes',
              icon: Icons.shield_outlined,
              theme: theme,
            ),
            const SizedBox(height: 12),
          ],
          _BlockButton(profile: profile),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text('Could not load profile.', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Post _buildMinimalPost(Comment comment, String postId) {
    return Post(
      id: postId,
      title: comment.linkTitle ?? '',
      author: comment.author,
      subreddit: Subreddit(id: '', name: comment.subreddit ?? ''),
      createdAt: comment.createdAt,
      permalink: comment.linkPermalink ?? '',
      type: PostType.link,
      score: comment.score,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BlockButton extends ConsumerWidget {
  final UserProfile profile;

  const _BlockButton({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockActionProvider)[profile.username] ?? false;
    final theme = Theme.of(context);

    if (blocked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => handleUnblockUser(
              context: context,
              notifier: ref.read(blockActionProvider.notifier),
              username: profile.username,
              accountId: profile.accountId,
            ),
            icon: const Icon(Icons.person_off_outlined, size: 18),
            label: const Text('Unblock'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => handleBlockUser(
            context: context,
            notifier: ref.read(blockActionProvider.notifier),
            username: profile.username,
            accountId: profile.accountId,
          ),
          icon: const Icon(Icons.block, size: 18),
          label: const Text('Block'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }
}
