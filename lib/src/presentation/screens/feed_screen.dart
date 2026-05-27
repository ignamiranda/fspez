import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_providers.dart';
import '../../data/feed_pagination.dart';
import '../../domain/enums/feed_sort.dart';
import '../utils/infinite_scroll.dart';
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
    final account = ref.watch(activeAccountProvider);
    final loggedIn = account != null;
    final config = _showAll
        ? FeedPageConfig.popularAll(sort: _sort)
        : loggedIn
            ? FeedPageConfig.home(sort: _sort)
            : const FeedPageConfig.popular();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showAll ? 'Popular' : loggedIn ? 'fspez' : 'Popular',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(feedPageProvider(_buildConfig()).notifier).refresh(),
          ),
          IconButton(
            icon: Icon(_showAll ? Icons.home : Icons.whatshot),
            tooltip: _showAll ? 'Home' : 'Popular',
            onPressed: () {
              setState(() => _showAll = !_showAll);
            },
          ),
          PopupMenuButton<FeedSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              setState(() => _sort = sort);
            },
            itemBuilder: (_) => FeedSort.values.map((sort) {
              return PopupMenuItem(
                value: sort,
                child: Text(sort.label),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
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
}
