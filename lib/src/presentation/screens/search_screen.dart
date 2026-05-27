import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../utils/infinite_scroll.dart';
import '../widgets/feed_screen_scaffold.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _hasSearched = false;
  String _lastQuery = '';
  ScrollController? _scrollController;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    _scrollController?.dispose();
    _scrollController = createInfiniteScrollController(
      () => ref.read(feedPageProvider(FeedPageConfig.search(_lastQuery)).notifier).loadMore(),
    );
    setState(() {
      _hasSearched = true;
      _lastQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search Reddit...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return const Center(
        child: Text('Enter a query to search Reddit'),
      );
    }

    final config = FeedPageConfig.search(_lastQuery);
    final state = ref.watch(feedPageProvider(config));
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FeedScreenScaffold(
      config: config,
      scrollController: _scrollController!,
      emptyMessage: 'No results found.',
    );
  }
}
