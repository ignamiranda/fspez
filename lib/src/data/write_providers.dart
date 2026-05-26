import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/vote_direction.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'vote_notifier.dart';
import 'save_notifier.dart';
import 'hide_notifier.dart';

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
    StateNotifierProvider<HideNotifier, Set<String>>((ref) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return HideNotifier(client, cookie);
});
