import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import 'post_card.dart';

class PostList extends StatefulWidget {
  final List<Post> posts;
  final Map<String, VoteDirection> voteOverrides;
  final Map<String, bool> saveOverrides;
  final void Function(String fullname, VoteDirection direction)? onPostVote;
  final void Function(String fullname)? onPostSave;
  final void Function(Post post)? onPostTap;
  final void Function(Post post)? onSubredditTap;
  final String emptyMessage;
  final ScrollController? scrollController;
  final Widget? footer;
  final Future<void> Function()? onRefresh;

  const PostList({
    super.key,
    required this.posts,
    this.voteOverrides = const {},
    this.saveOverrides = const {},
    this.onPostVote,
    this.onPostSave,
    this.onPostTap,
    this.onSubredditTap,
    this.emptyMessage = 'No posts yet.',
    this.scrollController,
    this.footer,
    this.onRefresh,
  });

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  static const double _refreshThreshold = 48;
  static const Duration _refreshArmDelay = Duration(milliseconds: 140);

  bool _isRefreshing = false;
  bool _refreshArmed = false;
  double _pullDistance = 0;
  bool _isAtTop = true;

  void _resetPull() {
    if (_pullDistance == 0 && !_refreshArmed) return;
    setState(() {
      _pullDistance = 0;
      _refreshArmed = false;
    });
  }

  void _addPull(double amount) {
    if (_isRefreshing || amount <= 0) return;

    if (_refreshArmed) return;

    setState(() {
      _pullDistance += amount;
    });
    if (_pullDistance >= _refreshThreshold) {
      _refreshArmed = true;
      Future.delayed(_refreshArmDelay, () {
        if (!mounted || !_refreshArmed || widget.onRefresh == null) return;
        _startRefresh();
      });
    }
  }

  Future<void> _startRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;

    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh!.call();
    } finally {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _refreshArmed = false;
        _pullDistance = 0;
        _isAtTop = true;
      });
    }
  }

  double get _pullProgress => (_pullDistance / _refreshThreshold).clamp(0.0, 1.0);

  bool _handlePointerSignal(PointerSignalEvent event) {
    if (widget.onRefresh == null) return false;
    if (event is PointerScrollEvent) {
      if (!_isAtTop || event.scrollDelta.dy > 0) {
        _resetPull();
      } else if (event.scrollDelta.dy < 0) {
        _addPull(event.scrollDelta.dy.abs());
      }
    }
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (widget.onRefresh == null) return false;

    _isAtTop = notification.metrics.pixels <=
        notification.metrics.minScrollExtent + 0.5;

    if (notification is ScrollEndNotification) {
      if (!_refreshArmed) _resetPull();
      return false;
    }

    if (notification is OverscrollNotification) {
      if (_isAtTop) _addPull(notification.overscroll.abs());
    }

    return false;
  }

  Widget _buildTopIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 80),
          opacity: _isRefreshing ? 1 : (_pullDistance > 0 ? 1 : 0),
          child: LinearProgressIndicator(
            value: _isRefreshing ? null : _pullProgress,
            minHeight: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.posts.isEmpty
        ? Center(child: Text(widget.emptyMessage))
        : NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: ListView.builder(
              controller: widget.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.posts.length + (widget.footer != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (widget.footer != null && index == widget.posts.length) {
                  return widget.footer!;
                }
                final post = widget.posts[index];
                final fullname = post.fullname;
                return PostCard(
                  post: post,
                  effectiveVote: widget.voteOverrides[fullname],
                  onVote: widget.onPostVote != null
                      ? (dir) => widget.onPostVote!(fullname, dir)
                      : null,
                  effectiveSaved: widget.saveOverrides[fullname],
                  onSave: widget.onPostSave != null
                      ? () => widget.onPostSave!(fullname)
                      : null,
                  onTap: widget.onPostTap != null ? () => widget.onPostTap!(post) : null,
                  onSubredditTap: widget.onSubredditTap != null
                      ? () => widget.onSubredditTap!(post)
                      : null,
                );
              },
            ),
          );

    if (widget.onRefresh == null) return content;

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(top: widget.onRefresh == null ? 0 : _pullDistance),
              child: content,
            ),
          ),
        ),
        if (_isRefreshing || _pullDistance > 0) _buildTopIndicator(),
      ],
    );
  }
}
