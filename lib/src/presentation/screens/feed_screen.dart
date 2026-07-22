import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/app_settings.dart';
import '../../data/feed_providers.dart';
import '../../data/feed_pagination.dart';
import '../../data/write_providers.dart';
import '../../data/paginated_list_state.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/enums/feed_density.dart';
import '../../domain/enums/top_time_filter.dart';
import '../../domain/enums/vote_direction.dart';
import '../../domain/models/post.dart';
import '../tab_scroll_signal.dart';
import '../utils/desktop_shortcuts.dart';
import '../utils/infinite_scroll.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/bottom_sheet_menu.dart';
import '../widgets/feed_screen_scaffold.dart';
import 'post_detail_screen.dart';
import 'search_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedSort _sort = FeedSort.hot;
  TopTimeFilter _timeFilter = TopTimeFilter.all;
  bool _showAll = false;
  ScrollController? _scrollController;
  int _focusedIndex = -1;
  final FocusNode _feedFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController = createInfiniteScrollController(
      () => ref.read(feedPageProvider(_buildConfig()).notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _feedFocusNode.dispose();
    super.dispose();
  }

  FeedPageConfig _buildConfig() {
    if (_showAll) {
      return FeedPageConfig.popularAll(
        sort: _sort,
        topTimeFilter: _timeFilter,
      );
    }
    final account = ref.read(activeAccountProvider);
    final loggedIn = account != null;
    return loggedIn
        ? FeedPageConfig.home(sort: _sort, topTimeFilter: _timeFilter)
        : const FeedPageConfig.popular();
  }

  void _scrollToFocused() {
    final c = _scrollController;
    if (c == null || !c.hasClients || _focusedIndex < 0) return;
    // Estimate the scroll offset to bring the focused item into view.
    // Each item is roughly 120-200px tall depending on density.
    final itemHeight =
        ref.read(appSettingsProvider).feedDensity == FeedDensity.compact
            ? 100.0
            : 180.0;
    final targetOffset = _focusedIndex * itemHeight;
    final maxScroll = c.position.maxScrollExtent;
    c.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  List<Post> _visiblePosts(PaginatedListState<Post> feedState) {
    final hiddenMap = ref.read(hideProvider);
    final hidden =
        hiddenMap.entries.where((e) => e.value).map((e) => e.key).toSet();
    return hidden.isEmpty
        ? feedState.items
        : feedState.items.where((p) => !hidden.contains(p.fullname)).toList();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!isDesktopPlatform) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final feedState = ref.read(feedPageProvider(_buildConfig()));
    final posts = _visiblePosts(feedState);
    if (posts.isEmpty) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyJ) {
      setState(() {
        _focusedIndex = _focusedIndex < 0
            ? 0
            : (_focusedIndex + 1).clamp(0, posts.length - 1);
      });
      _scrollToFocused();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyK) {
      setState(() {
        _focusedIndex = _focusedIndex < 0
            ? 0
            : (_focusedIndex - 1).clamp(0, posts.length - 1);
      });
      _scrollToFocused();
      return KeyEventResult.handled;
    }

    if (_focusedIndex < 0 || _focusedIndex >= posts.length) {
      return KeyEventResult.ignored;
    }

    final focusedPost = posts[_focusedIndex];
    final fullname = focusedPost.fullname;
    final actions = ref.read(postActionsServiceProvider);

    if (key == LogicalKeyboardKey.enter) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(post: focusedPost),
        ),
      );
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyA) {
      if (actions != null) {
        handleVote(actions, context, fullname, VoteDirection.upvote);
      } else {
        requireLoginForAction(context, action: 'vote');
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyZ) {
      if (actions != null) {
        handleVote(actions, context, fullname, VoteDirection.downvote);
      } else {
        requireLoginForAction(context, action: 'vote');
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyS) {
      if (actions != null) {
        final saveOverrides = ref.read(saveProvider);
        final wasSaved = saveOverrides[fullname] ?? focusedPost.isSaved;
        handleSave(actions, fullname, context, wasSaved: wasSaved);
      } else {
        requireLoginForAction(context, action: 'save');
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(tabScrollSignalProvider, (_, __) {
      final c = _scrollController;
      if (c != null && c.hasClients && c.offset > 0) {
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduceMotion) {
          c.jumpTo(0);
        } else {
          c.animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      }
      // Reset focus when scrolling to top
      setState(() => _focusedIndex = -1);
    });
    final account = ref.watch(activeAccountProvider);
    final loggedIn = account != null;
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final config = _showAll
        ? FeedPageConfig.popularAll(sort: _sort)
        : loggedIn
            ? FeedPageConfig.home(sort: _sort)
            : const FeedPageConfig.popular();

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(
          _showAll
              ? 'Popular'
              : loggedIn
                  ? 'Home'
                  : 'Popular',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh feed',
            onPressed: () =>
                ref.read(feedPageProvider(_buildConfig()).notifier).refresh(),
          ),
          IconButton(
            icon: Icon(_feedDensityIcon(settings.feedDensity)),
            tooltip: _feedDensityTooltip(settings.feedDensity),
            onPressed: () => settingsNotifier.setFeedDensity(
              _nextFeedDensity(settings.feedDensity),
            ),
          ),
          IconButton(
            icon: Icon(_showAll ? Icons.home : Icons.whatshot),
            tooltip: _showAll ? 'Popular' : 'Home',
            onPressed: () {
              setState(() => _showAll = !_showAll);
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort feed',
            onPressed: () async {
              final ctx = context;
              final sort = await showRadioBottomSheet<FeedSort>(
                ctx,
                title: 'Sort feed',
                currentValue: _sort,
                values: FeedSort.values,
                labelFn: (s) => s.label,
              );
              if (sort != null && sort != _sort) {
                if (sort == FeedSort.top) {
                  final timeFilter = await showRadioBottomSheet<TopTimeFilter>(
                    // ignore: use_build_context_synchronously
                    ctx,
                    title: 'Top from…',
                    currentValue: _timeFilter,
                    values: TopTimeFilter.values,
                    labelFn: (s) => s.label,
                  );
                  if (timeFilter != null) {
                    setState(() {
                      _sort = sort;
                      _timeFilter = timeFilter;
                    });
                  }
                } else {
                  setState(() => _sort = sort);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: FeedScreenScaffold(
        config: config,
        scrollController: _scrollController!,
        focusedIndex: _focusedIndex,
      ),
    );

    if (!isDesktopPlatform) return scaffold;

    return Focus(
      focusNode: _feedFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: scaffold,
    );
  }

  FeedDensity _nextFeedDensity(FeedDensity current) {
    return switch (current) {
      FeedDensity.comfortable => FeedDensity.compact,
      FeedDensity.compact => FeedDensity.comfortable,
    };
  }

  IconData _feedDensityIcon(FeedDensity current) {
    return switch (current) {
      FeedDensity.comfortable => Icons.view_list_outlined,
      FeedDensity.compact => Icons.view_agenda_outlined,
    };
  }

  String _feedDensityTooltip(FeedDensity current) {
    return switch (current) {
      FeedDensity.comfortable => 'Switch to compact feed',
      FeedDensity.compact => 'Switch to comfortable feed',
    };
  }
}
