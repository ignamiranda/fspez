import '../models/account.dart';

abstract class IAccountRepository {
  Future<List<Account>> loadAll();

  Future<void> save(Account account);

  Future<void> remove(String id);

  Future<void> setActive(String id);

  Future<Account?> loadActive();

  Future<void> clearAllExcept(String id);

  Future<void> replaceAll(List<Account> accounts);
}
