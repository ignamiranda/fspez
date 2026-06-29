import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/vote_direction.dart';
import 'auth_providers.dart';
import 'compose_notifier.dart';
import 'media_client.dart';
import 'post_actions_notifier.dart';
import 'reddit_client_provider.dart';
import 'submit_notifier.dart';

final postActionsProvider =
    StateNotifierProvider<PostActionsNotifier, PostActionsState>((ref) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return PostActionsNotifier(client, cookie);
});

// Backward-compatible state projections for reactive reads
final voteProvider = Provider<Map<String, VoteDirection>>((ref) {
  return ref.watch(postActionsProvider).votes;
});

final saveProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(postActionsProvider).saves;
});

final hideProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(postActionsProvider).hides;
});

final blockActionProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(postActionsProvider).blocks;
});

final mediaUploadClientProvider = Provider<MediaUploadClient>((ref) {
  final client = MediaUploadClient(ref.watch(redditClientProvider));
  ref.onDispose(client.dispose);
  return client;
});

final submitProvider =
    StateNotifierProvider<SubmitNotifier, SubmitState>((ref) {
  return SubmitNotifier(
    ref.watch(redditClientProvider),
    ref.watch(mediaUploadClientProvider),
  );
});

final composeProvider = StateNotifierProvider<ComposeNotifier, ComposeState>((
  ref,
) {
  return ComposeNotifier(ref.watch(redditClientProvider));
});
