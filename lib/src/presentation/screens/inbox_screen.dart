import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/inbox_providers.dart';
import '../../data/inbox_notifier.dart';
import '../../data/write_providers.dart';
import '../utils/block_user_helpers.dart';
import '../utils/error_messages.dart';
import '../widgets/shared/error_retry_widget.dart';
import '../../domain/models/inbox_item.dart';
import '../../domain/models/inbox_feed.dart';
import '../../domain/utils/comment_context.dart';
import '../tab_scroll_signal.dart';
import '../utils/format_utils.dart';
import '../utils/infinite_scroll.dart';
import '../widgets/reddit_body.dart';
import 'auth_webview_screen.dart';
import 'compose_screen.dart';
import 'post_detail_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final Set<String> _expandedIds = {};
  ScrollController? _inboxScrollController;

  @override
  void initState() {
    super.initState();
    _inboxScrollController = createInfiniteScrollController(
      () => ref.read(inboxProvider.notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _inboxScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(tabScrollSignalProvider, (_, __) {
      final c = _inboxScrollController;
      if (c != null && c.hasClients && c.offset > 0) {
        c.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    final state = ref.watch(inboxProvider);
    final notifier = ref.read(inboxProvider.notifier);
    final theme = Theme.of(context);
    final account = ref.watch(activeAccountProvider);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inbox')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Log in to see your inbox.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AuthWebViewScreen()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Log in'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh inbox',
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<InboxTab>(
              segments: const [
                ButtonSegment(value: InboxTab.all, label: Text('All')),
                ButtonSegment(value: InboxTab.unread, label: Text('Unread')),
                ButtonSegment(value: InboxTab.sent, label: Text('Sent')),
              ],
              selected: {state.tab},
              onSelectionChanged: (Set<InboxTab> selected) {
                _expandedIds.clear();
                notifier.loadTab(selected.first);
              },
            ),
          ),
          Expanded(child: _buildBody(state, notifier, theme)),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ComposeScreen())),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  Widget _buildBody(InboxState state, InboxNotifier notifier, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.messages.isEmpty) {
      return ErrorRetryWidget(
        message: userFriendlyErrorMessage(state.error!),
        onRetry: notifier.refresh,
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _expandedIds.clear();
        return notifier.refresh();
      },
      child: ListView.builder(
        controller: _inboxScrollController,
        itemCount: state.messages.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.messages.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final msg = state.messages[index];
          final account = ref.read(activeAccountProvider);
          return _MessageTile(
            item: msg,
            isExpanded: _expandedIds.contains(msg.id),
            onToggle: () {
              if (msg is CommentNotification) {
                final parsed = parseCommentContext(msg.context);
                if (parsed != null) {
                  if (msg.isNew) notifier.markAsRead(msg);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        subreddit: parsed.subreddit,
                        postId: parsed.postId,
                        initialCommentId: parsed.commentId,
                      ),
                    ),
                  );
                  return;
                }
              }
              final id = msg.id;
              final wasExpanded = _expandedIds.contains(id);
              setState(() {
                if (wasExpanded) {
                  _expandedIds.remove(id);
                } else {
                  _expandedIds.add(id);
                }
              });
              if (!wasExpanded && msg.isNew) {
                notifier.markAsRead(msg);
              }
            },
            onReply: msg is DirectMessage
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ComposeScreen(
                          replyTo: msg.author,
                          replySubject: msg.subject.startsWith('re:')
                              ? msg.subject
                              : 're: ${msg.subject}',
                        ),
                      ),
                    );
                  }
                : null,
            onBlock: account != null && msg.author != '[deleted]'
                ? () => handleBlockUser(
                      context: context,
                      notifier: ref.read(blockActionProvider.notifier),
                      username: msg.author,
                    )
                : null,
          );
        },
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final InboxItem item;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback? onReply;
  final VoidCallback? onBlock;

  const _MessageTile({
    required this.item,
    required this.isExpanded,
    required this.onToggle,
    this.onReply,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isNew)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  )
                else
                  const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.author,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: item.isNew
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (item is CommentNotification)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.reply_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            timeAgo(item.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (onBlock != null) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  builder: (ctx) => SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 16,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Theme.of(ctx)
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.4),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.block),
                                            title: Text(
                                              'Block u/${item.author}',
                                            ),
                                            onTap: () {
                                              Navigator.of(ctx).pop();
                                              onBlock!();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.more_horiz,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subject,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              item.isNew ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? null : TextOverflow.ellipsis,
                      ),
                      if (!isExpanded && item.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? _MessageBody(item: item, onReply: onReply)
              : const SizedBox.shrink(),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

class _MessageBody extends StatelessWidget {
  final InboxItem item;
  final VoidCallback? onReply;

  const _MessageBody({required this.item, this.onReply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final subreddit = item is CommentNotification
        ? (item as CommentNotification).subreddit
        : null;
    return Padding(
      padding: const EdgeInsets.only(left: 34, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subreddit != null) Text('r/$subreddit'),
          RedditBody(item.body),
          if (onReply != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Reply', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
          if (item.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Replies',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            ...item.replies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reply.author,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo(reply.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    RedditBody(reply.body),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
