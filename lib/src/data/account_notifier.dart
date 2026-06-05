import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/account.dart';
import '../domain/models/session_cookie.dart';
import 'account_repository.dart';
import 'feed_cache.dart';

class AccountListVersionNotifier extends StateNotifier<int> {
  AccountListVersionNotifier() : super(0);

  void bump() => state++;
}

class ActiveAccountNotifier extends StateNotifier<Account?> {
  final AccountRepository _repository;
  final AccountListVersionNotifier _listVersion;
  final FeedCache _feedCache;

  ActiveAccountNotifier(this._repository, this._listVersion, this._feedCache)
      : super(_repository.loadActive()) {
    Future.microtask(_deduplicate);
  }

  Future<void> _deduplicate() async {
    final accounts = _repository.loadAll();
    final seen = <String>{};
    final keep = <Account>[];
    Account? replacement;
    for (final account in accounts) {
      if (seen.contains(account.username)) {
        replacement ??= account;
      } else {
        seen.add(account.username);
        keep.add(account);
      }
    }
    if (replacement != null && keep.length < accounts.length) {
      final activeId = state?.id;
      await _repository.replaceAll(keep);
      if (activeId != null && !keep.any((a) => a.id == activeId)) {
        state = keep.isNotEmpty ? keep.first : null;
      }
    }
  }

  Future<void> setActive(Account account) async {
    await _repository.setActive(account.id);
    state = account;
    _listVersion.bump();
  }

  Future<void> addAccount(Account account) async {
    await _repository.save(account);
    await _repository.setActive(account.id);
    state = account;
    _listVersion.bump();
  }

  Future<void> removeAccount(String accountId) async {
    _feedCache.clearForAccount(accountId);
    await _repository.remove(accountId);
    if (state?.id == accountId) {
      state = _repository.loadActive();
    }
    _listVersion.bump();
  }

  Future<void> updateSessionCookie(SessionCookie newCookie) async {
    final current = state;
    if (current == null) return;
    final updated = Account(
      id: current.id,
      username: current.username,
      sessionCookie: newCookie,
    );
    await _repository.save(updated);
    state = updated;
    _listVersion.bump();
  }
}
