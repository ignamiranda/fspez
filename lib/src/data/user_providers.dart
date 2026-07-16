import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/i_user_repository.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'user_repository.dart';

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return UserRepository(ref.watch(redditClientProvider));
});

final userProfileProvider =
    FutureProvider.autoDispose.family<UserProfile, String>((ref, username) async {
  final repo = ref.watch(userRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  final sessionCookie = account?.sessionCookie;
  final profile = await repo.fetchProfile(username, sessionCookie: sessionCookie);

  // Fetch actual moderated subreddits only when viewing own profile
  List<String> moderated = const [];
  if (account?.username == username && sessionCookie != null) {
    try {
      moderated = await repo.fetchModeratedSubreddits(sessionCookie: sessionCookie);
    } catch (e) {
      debugPrint('UserProfileProvider moderated subreddits fetch failed: $e');
      // Non-fatal — moderated subs are supplemental info
    }
  }

  return profile.copyWith(moderatedSubreddits: moderated);
});
