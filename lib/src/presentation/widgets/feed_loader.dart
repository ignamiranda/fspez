import 'package:flutter/material.dart';
import '../../domain/models/feed.dart';
import '../../domain/models/post.dart';

class FeedLoader extends ChangeNotifier {
  FeedLoader({
    required Future<Feed> Function({String? after}) fetchPage,
  }) : _fetchPage = fetchPage {
    _scrollController.addListener(_onScroll);
  }

  final Future<Feed> Function({String? after}) _fetchPage;
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _after;

  ScrollController get scrollController => _scrollController;
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  Future<void> loadInitial() async {
    _isLoading = true;
    _isLoadingMore = false;
    _posts = [];
    _after = null;
    _hasMore = true;
    _error = null;
    notifyListeners();
    try {
      final feed = await _fetchPage(after: null);
      _posts = feed.posts;
      _after = feed.after;
      _hasMore = feed.hasMorePages;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final feed = await _fetchPage(after: _after);
      _posts.addAll(feed.posts);
      _after = feed.after;
      _hasMore = feed.hasMorePages;
    } catch (_) {}
    _isLoadingMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
