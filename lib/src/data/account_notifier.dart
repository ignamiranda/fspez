import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/account.dart';
import 'account_repository.dart';

class AccountListVersionNotifier extends StateNotifier<int> {
  AccountListVersionNotifier() : super(0);

  void bump() => state++;
}

class ActiveAccountNotifier extends StateNotifier<Account?> {
  final AccountRepository _repository;
  final AccountListVersionNotifier _listVersion;

  ActiveAccountNotifier(this._repository, this._listVersion)
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
    await _repository.remove(accountId);
    if (state?.id == accountId) {
      state = _repository.loadActive();
    }
    _listVersion.bump();
  }
}
