import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/vote_direction.dart';
import 'action_notifier.dart';
import 'media_client.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'submit_notifier.dart';
import 'compose_notifier.dart';
import 'edit_notifier.dart';
import 'block_action_notifier.dart';
import 'post_actions_service.dart';

final voteProvider =
    StateNotifierProvider<ActionNotifier<VoteDirection>, Map<String, VoteDirection>>((ref) {
      final client = ref.watch(redditClientProvider);
      final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
      return ActionNotifier<VoteDirection>(client, cookie);
    });

final saveProvider = StateNotifierProvider<ActionNotifier<bool>, Map<String, bool>>((
  ref,
) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return ActionNotifier<bool>(client, cookie);
});

final hideProvider = StateNotifierProvider<ActionNotifier<bool>, Map<String, bool>>((
  ref,
) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return ActionNotifier<bool>(client, cookie);
});

final deleteProvider = StateNotifierProvider<ActionNotifier<void>, Map<String, void>>(
  (ref) {
    final client = ref.watch(redditClientProvider);
    final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
    return ActionNotifier<void>(client, cookie);
  },
);

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

final editProvider = StateNotifierProvider<EditNotifier, EditState>((ref) {
  return EditNotifier(ref.watch(redditClientProvider));
});

final blockActionProvider =
    StateNotifierProvider<BlockActionNotifier, Map<String, bool>>((ref) {
      final client = ref.watch(redditClientProvider);
      final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
      return BlockActionNotifier(client, cookie);
    });

final postActionsServiceProvider = Provider<PostActionsService?>((ref) {
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  if (cookie == null) return null;
  return PostActionsService(
    voteNotifier: ref.watch(voteProvider.notifier),
    saveNotifier: ref.watch(saveProvider.notifier),
    hideNotifier: ref.watch(hideProvider.notifier),
    deleteNotifier: ref.watch(deleteProvider.notifier),
    editNotifier: ref.watch(editProvider.notifier),
    sessionCookie: cookie,
  );
});
