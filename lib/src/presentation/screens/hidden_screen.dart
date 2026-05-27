import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../utils/infinite_scroll.dart';
import '../widgets/feed_screen_scaffold.dart';

class HiddenScreen extends ConsumerStatefulWidget {
  const HiddenScreen({super.key});

  @override
  ConsumerState<HiddenScreen> createState() => _HiddenScreenState();
}

class _HiddenScreenState extends ConsumerState<HiddenScreen> {
  static const _config = FeedPageConfig.hidden();
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = createInfiniteScrollController(
      () => ref.read(feedPageProvider(_config).notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(feedPageProvider(_config).notifier).refresh(),
          ),
        ],
      ),
      body: FeedScreenScaffold(
        config: _config,
        scrollController: _scrollController!,
        emptyMessage: 'No hidden posts.',
      ),
    );
  }
}
