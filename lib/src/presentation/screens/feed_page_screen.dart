import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../utils/infinite_scroll.dart';
import '../widgets/feed_screen_scaffold.dart';

/// A parameterized screen that renders a feed page for any [FeedPageConfig].
///
/// Replaces HiddenScreen and SavedScreen, which were identical except for
/// the config, title, and empty message.
class FeedPageScreen extends ConsumerStatefulWidget {
  final FeedPageConfig config;
  final String title;
  final String emptyMessage;

  const FeedPageScreen({
    super.key,
    required this.config,
    required this.title,
    this.emptyMessage = 'No posts.',
  });

  @override
  ConsumerState<FeedPageScreen> createState() => _FeedPageScreenState();
}

class _FeedPageScreenState extends ConsumerState<FeedPageScreen> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = createInfiniteScrollController(
      () => ref.read(feedPageProvider(widget.config).notifier).loadMore(),
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
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(feedPageProvider(widget.config).notifier).refresh(),
          ),
        ],
      ),
      body: FeedScreenScaffold(
        config: widget.config,
        scrollController: _scrollController!,
        emptyMessage: widget.emptyMessage,
        filterHidden: false,
      ),
    );
  }
}
