import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../data/inbox_notifier.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_feed.dart';
import '../utils/format_utils.dart';
import 'compose_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.inbox_outlined, size: 64,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Log in to see your inbox.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
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
                ButtonSegment(value: InboxTab.inbox, label: Text('All')),
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
          Expanded(
            child: _buildBody(state, notifier, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ComposeScreen(),
          ),
        ),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  Widget _buildBody(
      InboxState state, InboxNotifier notifier, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(state.error!, textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No messages yet.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _expandedIds.clear();
        notifier.refresh();
      },
      child: ListView.builder(
        controller: notifier.scrollController,
        itemCount: state.messages.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.messages.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final msg = state.messages[index];
          return _MessageTile(
            message: msg,
            isExpanded: _expandedIds.contains(msg.id),
            onToggle: () => setState(() {
              final id = msg.id;
              if (_expandedIds.contains(id)) {
                _expandedIds.remove(id);
              } else {
                _expandedIds.add(id);
              }
            }),
            onReply: msg.isComment
                ? null
                : () {
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
                  },
          );
        },
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final Message message;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback? onReply;

  const _MessageTile({
    required this.message,
    required this.isExpanded,
    required this.onToggle,
    this.onReply,
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
                if (message.isNew)
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
                              message.author,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: message.isNew
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (message.isComment)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.reply_outlined, size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          Text(
                            timeAgo(message.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.subject,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: message.isNew
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: isExpanded ? null : 2,
                        overflow:
                            isExpanded ? null : TextOverflow.ellipsis,
                      ),
                      if (!isExpanded && message.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          message.body,
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
              ? _MessageBody(message: message, onReply: onReply)
              : const SizedBox.shrink(),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

class _MessageBody extends StatelessWidget {
  final Message message;
  final VoidCallback? onReply;

  const _MessageBody({required this.message, this.onReply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 34, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.subreddit != null) ...[
            Text(
              'r/${message.subreddit}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message.body,
            style: theme.textTheme.bodyMedium,
          ),
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
          if (message.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Replies',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            ...message.replies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(reply.author,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text(timeAgo(reply.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(reply.body, style: theme.textTheme.bodySmall),
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
