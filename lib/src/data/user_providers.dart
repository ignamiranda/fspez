import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_profile.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(redditClientProvider));
});

final userProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, username) async {
  final repo = ref.watch(userRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchProfile(username, sessionCookie: sessionCookie);
});
