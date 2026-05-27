import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/vote_direction.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'vote_notifier.dart';
import 'save_notifier.dart';
import 'hide_notifier.dart';
import 'delete_notifier.dart';
import 'submit_notifier.dart';
import 'compose_notifier.dart';

final voteProvider =
    StateNotifierProvider<VoteNotifier, Map<String, VoteDirection>>((ref) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return VoteNotifier(client, cookie);
});

final saveProvider =
    StateNotifierProvider<SaveNotifier, Map<String, bool>>((ref) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return SaveNotifier(client, cookie);
});

final hideProvider =
    StateNotifierProvider<HideNotifier, Map<String, bool>>((ref) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return HideNotifier(client, cookie);
});

final deleteProvider =
    StateNotifierProvider<DeleteNotifier, Map<String, void>>((ref) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return DeleteNotifier(client, cookie);
});

final submitProvider =
    StateNotifierProvider<SubmitNotifier, SubmitState>((ref) {
  return SubmitNotifier(ref.watch(redditClientProvider));
});

final composeProvider =
    StateNotifierProvider<ComposeNotifier, ComposeState>((ref) {
  return ComposeNotifier(ref.watch(redditClientProvider));
});
