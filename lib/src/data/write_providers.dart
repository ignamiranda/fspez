import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/vote_direction.dart';
import 'account_client.dart';
import 'action_notifier.dart';
import 'interaction_client.dart';
import 'media_client.dart';
import 'message_client.dart';
import 'submit_client.dart';
import 'auth_providers.dart';
import 'submit_notifier.dart';
import 'compose_notifier.dart';
import 'edit_notifier.dart';
import 'block_action_notifier.dart';
import 'post_actions_service.dart';
import 'write_notifier.dart';

final interactionClientProvider = Provider<InteractionClient>((ref) {
  return InteractionClient(ref.watch(httpTransportProvider));
});

final submitClientProvider = Provider<SubmitClient>((ref) {
  return SubmitClient(ref.watch(httpTransportProvider));
});

final messageClientProvider = Provider<MessageClient>((ref) {
  return MessageClient(ref.watch(httpTransportProvider));
});

final accountClientProvider = Provider<AccountClient>((ref) {
  return AccountClient(ref.watch(httpTransportProvider));
});

final voteProvider =
    StateNotifierProvider<ActionNotifier<VoteDirection>, Map<String, VoteDirection>>((ref) {
      final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
      return ActionNotifier<VoteDirection>(cookie);
    });

final saveProvider = StateNotifierProvider<ActionNotifier<bool>, Map<String, bool>>((
  ref,
) {
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return ActionNotifier<bool>(cookie);
});

final hideProvider = StateNotifierProvider<ActionNotifier<bool>, Map<String, bool>>((
  ref,
) {
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return ActionNotifier<bool>(cookie);
});

final deleteProvider = StateNotifierProvider<ActionNotifier<void>, Map<String, void>>(
  (ref) {
    final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
    return ActionNotifier<void>(cookie);
  },
);

final mediaUploadClientProvider = Provider<MediaUploadClient>((ref) {
  final client = MediaUploadClient(ref.watch(submitClientProvider));
  ref.onDispose(client.dispose);
  return client;
});

final submitProvider =
    StateNotifierProvider<SubmitNotifier, SubmitState>((ref) {
  return SubmitNotifier(
    ref.watch(submitClientProvider),
    ref.watch(mediaUploadClientProvider),
  );
});

final composeProvider = StateNotifierProvider<ComposeNotifier, WriteState>((
  ref,
) {
  return ComposeNotifier(ref.watch(messageClientProvider));
});

final editProvider = StateNotifierProvider<EditNotifier, WriteState>((ref) {
  return EditNotifier(ref.watch(interactionClientProvider));
});

final blockActionProvider =
    StateNotifierProvider<BlockActionNotifier, Map<String, bool>>((ref) {
      final client = ref.watch(accountClientProvider);
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
    client: ref.watch(interactionClientProvider),
    sessionCookie: cookie,
  );
});
