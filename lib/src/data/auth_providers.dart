import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/account.dart';
import 'account_repository.dart';
import 'account_notifier.dart';
import 'cache_providers.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(sharedPrefsProvider));
});

final accountListVersionProvider =
    StateNotifierProvider<AccountListVersionNotifier, int>((ref) {
  return AccountListVersionNotifier();
});

final accountsProvider = Provider<List<Account>>((ref) {
  ref.watch(accountListVersionProvider);
  return ref.watch(accountRepositoryProvider).loadAll();
});

final activeAccountProvider =
    StateNotifierProvider<ActiveAccountNotifier, Account?>((ref) {
  return ActiveAccountNotifier(
    ref.watch(accountRepositoryProvider),
    ref.watch(accountListVersionProvider.notifier),
    ref.watch(feedCacheProvider),
  );
});
