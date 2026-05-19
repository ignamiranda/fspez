import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/account.dart';
import 'account_repository.dart';

class ActiveAccountNotifier extends StateNotifier<Account?> {
  final AccountRepository _repository;

  ActiveAccountNotifier(this._repository) : super(_repository.loadActive());

  Future<void> setActive(Account account) async {
    await _repository.setActive(account.id);
    state = account;
  }

  Future<void> addAccount(Account account) async {
    await _repository.save(account);
    await _repository.setActive(account.id);
    state = account;
  }

  Future<void> removeAccount(String accountId) async {
    await _repository.remove(accountId);
    if (state?.id == accountId) {
      state = _repository.loadActive();
    }
  }
}
