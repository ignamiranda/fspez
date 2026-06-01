import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/app_settings.dart';
import '../../data/feed_providers.dart';
import '../../data/feed_pagination.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/enums/feed_density.dart';
import '../tab_scroll_signal.dart';
import '../utils/infinite_scroll.dart';
import '../widgets/bottom_sheet_menu.dart';
import '../widgets/feed_screen_scaffold.dart';
import 'search_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedSort _sort = FeedSort.hot;
  bool _showAll = false;
  ScrollController? _scrollController;

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
    super.dispose();
  }

  FeedPageConfig _buildConfig() {
    if (_showAll) return FeedPageConfig.popularAll(sort: _sort);
    final account = ref.read(activeAccountProvider);
    final loggedIn = account != null;
    return loggedIn
        ? FeedPageConfig.home(sort: _sort)
        : const FeedPageConfig.popular();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showAll
              ? 'Popular'
              : loggedIn
                  ? 'fspez'
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
            tooltip: _showAll ? 'Home' : 'Popular',
            onPressed: () {
              setState(() => _showAll = !_showAll);
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort feed',
            onPressed: () async {
              final sort = await showRadioBottomSheet<FeedSort>(
                context,
                title: 'Sort feed',
                currentValue: _sort,
                values: FeedSort.values,
                labelFn: (s) => s.label,
              );
              if (sort != null && sort != _sort) {
                setState(() => _sort = sort);
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
      ),
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
