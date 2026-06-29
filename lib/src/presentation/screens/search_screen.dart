import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/write_providers.dart';
import '../../domain/models/post.dart';
import '../providers/search_providers.dart';
import '../utils/block_user_helpers.dart';
import '../widgets/post_card.dart';
import '../widgets/subreddit_card.dart';
import '../widgets/user_search_card.dart';
import 'post_detail_screen.dart';
import 'subreddit_feed_screen.dart';
import 'user_profile_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialSubredditScope;

  const SearchScreen({super.key, this.initialSubredditScope});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollControllers = <ScrollController>[];
  bool _hasSearched = false;
  String _lastQuery = '';
  String? _subredditScope;
  late TabController _tabController;

  static const _tabs = [
    'Posts',
    'Communities',
    'Comments',
    'Media',
    'Profiles',
  ];

  @override
  void initState() {
    super.initState();
    _subredditScope = widget.initialSubredditScope;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  SearchRequest get _request => (query: _lastQuery, subreddit: _subredditScope);

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    for (final c in _scrollControllers) {
      c.dispose();
    }
    _scrollControllers.clear();

    // Create scroll controllers for search tabs
    for (var i = 0; i < _tabs.length; i++) {
      _scrollControllers.add(ScrollController());
      final controller = _scrollControllers[i];
      controller.addListener(() {
        if (controller.position.pixels >=
            controller.position.maxScrollExtent - 300) {
          _loadMore(i);
        }
      });
    }

    setState(() {
      _hasSearched = true;
      _lastQuery = query;
    });
    _tabController.index = 0;
  }

  void _loadMore(int tabIndex) {
    switch (tabIndex) {
      case 0: // Posts
        ref.read(searchPostsProvider(_request).notifier).loadMore();
      case 1: // Communities
        ref.read(searchCommunitiesProvider(_request).notifier).loadMore();
      case 2: // Comments
        ref.read(searchCommentsProvider(_request).notifier).loadMore();
      case 3: // Media
        ref.read(searchPostsProvider(_request).notifier).loadMore();
      case 4: // Profiles
        ref.read(searchUsersProvider(_request).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _subredditScope == null
                ? 'Search Reddit...'
                : 'Search in r/${_subredditScope!}...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
        actions: [
          if (_subredditScope != null)
            IconButton(
              tooltip: 'Search all of Reddit',
              icon: const Icon(Icons.public),
              onPressed: () => setState(() => _subredditScope = null),
            ),
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
        bottom: _hasSearched
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              )
            : null,
      ),
      body: _hasSearched
          ? Column(
              children: [
                if (_subredditScope != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Chip(
                          avatar: const Icon(Icons.travel_explore, size: 16),
                          label: Text('Searching in r/${_subredditScope!}'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _PostsTab(
                        request: _request,
                        scrollController: _scrollControllers[0],
                      ),
                      _CommunitiesTab(
                        request: _request,
                        scrollController: _scrollControllers[1],
                      ),
                      _CommentsTab(
                        request: _request,
                        scrollController: _scrollControllers[2],
                      ),
                      _MediaTab(
                        request: _request,
                        scrollController: _scrollControllers[3],
                      ),
                      _ProfilesTab(
                        request: _request,
                        scrollController: _scrollControllers[4],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: Text('Enter a query to search Reddit')),
    );
  }
}

// ── Posts Tab ─────────────────────────────────────────────────────────────────

class _PostsTab extends ConsumerWidget {
  final SearchRequest request;
  final ScrollController scrollController;

  const _PostsTab({required this.request, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchPostsProvider(request));
    final notifier = ref.read(searchPostsProvider(request).notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = state.items[index];
          return PostCard(
            post: post,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            ),
            onSubredditTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SubredditFeedScreen(subredditName: post.subreddit.name),
              ),
            ),
            onAuthorTap: post.author != '[deleted]'
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(username: post.author),
                    ),
                  )
                : null,
            onBlock:
                ref.read(activeAccountProvider) != null &&
                    post.author != '[deleted]'
                ? () => handleBlockUser(
                    context: context,
                    notifier: ref.read(postActionsProvider.notifier),
                    username: post.author,
                  )
                : null,
          );
        },
      ),
    );
  }
}

// ── Communities Tab ───────────────────────────────────────────────────────────

class _CommunitiesTab extends ConsumerWidget {
  final SearchRequest request;
  final ScrollController scrollController;

  const _CommunitiesTab({
    required this.request,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchCommunitiesProvider(request));
    final notifier = ref.read(searchCommunitiesProvider(request).notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final subreddit = state.items[index];
          return SubredditCard(
            subreddit: subreddit,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SubredditFeedScreen(subredditName: subreddit.name),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Comments Tab ──────────────────────────────────────────────────────────────

class _CommentsTab extends ConsumerWidget {
  final SearchRequest request;
  final ScrollController scrollController;

  const _CommentsTab({required this.request, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchCommentsProvider(request));
    final notifier = ref.read(searchCommentsProvider(request).notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = state.items[index];
          return _CommentCard(
            post: post,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            ),
          );
        },
      ),
    );
  }
}

/// A comment-style card that shows post selftext as the "comment body".
class _CommentCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const _CommentCard({required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'r/${post.subreddit.name}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('·'),
                ),
                Text(
                  'u/${post.author}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              post.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (post.selftext != null && post.selftext!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  post.selftext!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  '${post.score}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(
                  '${post.commentCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Media Tab ─────────────────────────────────────────────────────────────────

class _MediaTab extends ConsumerWidget {
  final SearchRequest request;
  final ScrollController scrollController;

  const _MediaTab({required this.request, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchPostsProvider(request));
    final notifier = ref.read(searchPostsProvider(request).notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    // Client-side filter for image/video/gallery posts
    final mediaPosts = state.items
        .where(
          (p) =>
              p.type == PostType.image ||
              p.type == PostType.video ||
              p.type == PostType.gallery,
        )
        .toList();

    if (mediaPosts.isEmpty) {
      return const Center(child: Text('No media results found.'));
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: mediaPosts.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == mediaPosts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = mediaPosts[index];
          return PostCard(
            post: post,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            ),
            onSubredditTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SubredditFeedScreen(subredditName: post.subreddit.name),
              ),
            ),
            onAuthorTap: post.author != '[deleted]'
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(username: post.author),
                    ),
                  )
                : null,
            onBlock:
                ref.read(activeAccountProvider) != null &&
                    post.author != '[deleted]'
                ? () => handleBlockUser(
                    context: context,
                    notifier: ref.read(postActionsProvider.notifier),
                    username: post.author,
                  )
                : null,
          );
        },
      ),
    );
  }
}

// ── Profiles Tab ──────────────────────────────────────────────────────────────

class _ProfilesTab extends ConsumerWidget {
  final SearchRequest request;
  final ScrollController scrollController;

  const _ProfilesTab({required this.request, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchUsersProvider(request));
    final notifier = ref.read(searchUsersProvider(request).notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final user = state.items[index];
          return UserSearchCard(
            user: user,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(username: user.name),
              ),
            ),
          );
        },
      ),
    );
  }
}
