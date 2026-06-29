import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'inbox_repository.dart';
import 'inbox_notifier.dart';
import 'write_providers.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(
    ref.watch(redditClientProvider),
    ref.watch(messageClientProvider),
  );
});

final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final repo = ref.watch(inboxRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return InboxNotifier(repo, account);
});

final inboxUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider.select((state) => state.unreadCount));
});
