import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_settings.dart';
import '../../domain/models/post.dart';

const _kWindowSize = 5;
const _kEstimatedItemHeight = 300.0;
const _kMaxTrackedUrls = 200;

List<String> extractPreviewUrls(Post post, {required bool skipSensitive}) {
  if (skipSensitive && (post.isNsfw || post.isSpoiler)) return [];
  final urls = <String>{};
  for (final url in post.mediaUrls) {
    urls.add(url);
  }
  if (post.thumbnailUrl != null &&
      post.thumbnailUrl != 'self' &&
      post.thumbnailUrl != 'default' &&
      post.thumbnailUrl != 'nsfw' &&
      post.thumbnailUrl != 'spoiler') {
    urls.add(post.thumbnailUrl!);
  }
  if (post.type == PostType.image && post.url != null) {
    urls.add(post.url!);
  }
  return urls.toList();
}

class FeedMediaPrefetcher extends ConsumerStatefulWidget {
  final List<Post> posts;
  final ScrollController scrollController;
  final Widget child;

  const FeedMediaPrefetcher({
    super.key,
    required this.posts,
    required this.scrollController,
    required this.child,
  });

  @override
  ConsumerState<FeedMediaPrefetcher> createState() =>
      _FeedMediaPrefetcherState();
}

class _FeedMediaPrefetcherState extends ConsumerState<FeedMediaPrefetcher> {
  int _lastPrefetchedIndex = -1;
  final Set<String> _prefetchedUrls = {};

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetch());
  }

  @override
  void didUpdateWidget(FeedMediaPrefetcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posts != widget.posts) {
      _lastPrefetchedIndex = -1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefetch());
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    _prefetch();
  }

  int _estimateLastVisibleIndex() {
    if (!widget.scrollController.hasClients || widget.posts.isEmpty) return 0;
    final visibleEnd = widget.scrollController.offset +
        widget.scrollController.position.viewportDimension;
    return (visibleEnd / _kEstimatedItemHeight)
        .floor()
        .clamp(0, widget.posts.length - 1);
  }

  void _prefetch() {
    if (!mounted || widget.posts.isEmpty) return;

    final settings = ref.read(appSettingsProvider);
    final skipSensitive = settings.nsfwBlur || settings.spoilerBlur;

    final lastVisible = _estimateLastVisibleIndex();
    final prefetchEnd =
        (lastVisible + _kWindowSize).clamp(0, widget.posts.length);

    if (lastVisible <= _lastPrefetchedIndex &&
        _lastPrefetchedIndex < prefetchEnd) {
      return;
    }
    _lastPrefetchedIndex = lastVisible;

    for (int i = lastVisible; i < prefetchEnd; i++) {
      final urls = extractPreviewUrls(widget.posts[i],
          skipSensitive: skipSensitive);
      for (final url in urls) {
        if (_prefetchedUrls.add(url)) {
          precacheImage(NetworkImage(url), context);
        }
      }
    }

    if (_prefetchedUrls.length > _kMaxTrackedUrls) {
      _prefetchedUrls.clear();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
