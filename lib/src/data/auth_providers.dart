import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/account.dart';
import 'account_repository.dart';
import 'account_notifier.dart';
import 'cache_providers.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError('FlutterSecureStorage must be overridden in main');
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(secureStorageProvider));
});

final accountListVersionProvider =
    StateNotifierProvider<AccountListVersionNotifier, int>((ref) {
  return AccountListVersionNotifier();
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(accountListVersionProvider);
  return ref.watch(accountRepositoryProvider).loadAll();
});

final corruptedSessionProvider = StateProvider<bool>((ref) => false);

final activeAccountProvider =
    StateNotifierProvider<ActiveAccountNotifier, Account?>((ref) {
  return ActiveAccountNotifier(
    ref.watch(accountRepositoryProvider),
    ref.watch(accountListVersionProvider.notifier),
    ref.watch(feedCacheProvider),
    ref.watch(corruptedSessionProvider.notifier),
  );
});
