import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../../data/user_providers.dart';
import '../../domain/models/post.dart';
import '../../domain/models/subreddit.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_comment.dart';
import '../utils/infinite_scroll.dart';
import '../utils/format_utils.dart';
import '../widgets/feed_screen_scaffold.dart';
import 'post_detail_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserComment> _comments = [];
  bool _commentsLoading = true;
  String? _commentsError;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = createInfiniteScrollController(
      () => ref.read(feedPageProvider(FeedPageConfig.user(widget.username)).notifier).loadMore(),
    );
    _loadComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _commentsLoading = true;
      _commentsError = null;
    });
    try {
      final repo = ref.read(userRepositoryProvider);
      final sessionCookie = ref.read(activeAccountProvider)?.sessionCookie;
      final comments = await repo.fetchComments(widget.username,
          sessionCookie: sessionCookie);
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
    final config = FeedPageConfig.user(widget.username);

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
            Text('Failed to load comments',
                style: theme.textTheme.bodySmall),
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
            Icon(Icons.chat_bubble_outline, size: 48,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No comments yet.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.separated(
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
                    comment.linkTitle,
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
                      Icon(Icons.arrow_upward, size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
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

  Widget _buildAboutTab(
      AsyncValue<UserProfile> profileAsync, ThemeData theme) {
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
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Gold',
                        style: TextStyle(
                            fontSize: 11, color: Colors.amber.shade900)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _KarmaRow(
            label: 'Post Karma',
            value: profile.linkKarma,
            icon: Icons.article_outlined,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _KarmaRow(
            label: 'Comment Karma',
            value: profile.commentKarma,
            icon: Icons.chat_bubble_outline,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Account Age',
            value: _accountAge(profile.createdAt),
            icon: Icons.calendar_today_outlined,
            theme: theme,
          ),
          if (profile.isMod) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Moderator',
              value: profile.subredditName != null
                  ? 'r/${profile.subredditName}'
                  : 'Yes',
              icon: Icons.shield_outlined,
              theme: theme,
            ),
          ],
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 48,
                color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text('Could not load profile.',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String _accountAge(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    final years = diff.inDays ~/ 365;
    final months = (diff.inDays % 365) ~/ 30;
    if (years > 0) return '$years years, $months months';
    return '$months months';
  }

  Post _buildMinimalPost(UserComment comment, String postId) {
    return Post(
      id: postId,
      title: comment.linkTitle,
      author: comment.author,
      subreddit: Subreddit(id: '', name: comment.subreddit),
      createdAt: comment.createdAt,
      permalink: comment.linkPermalink,
      type: PostType.link,
      score: comment.score,
    );
  }
}

class _KarmaRow extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final ThemeData theme;

  const _KarmaRow({
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
        Text(formatCount(value),
            style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600)),
      ],
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
        Text(value,
            style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
