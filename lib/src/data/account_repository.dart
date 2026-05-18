import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/account.dart';
import '../domain/models/session_cookie.dart';

class AccountRepository {
  static const _accountsKey = 'fspez_accounts';
  static const _activeAccountIdKey = 'fspez_active_account_id';

  final SharedPreferences _prefs;

  AccountRepository(this._prefs);

  List<Account> loadAll() {
    final json = _prefs.getString(_accountsKey);
    if (json == null) return [];

    final list = jsonDecode(json) as List<dynamic>;
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      final cookieRaw = map['cookieRaw'] as String?;
      final cookieModhash = map['cookieModhash'] as String?;
      return Account(
        id: map['id'] as String,
        username: map['username'] as String,
        sessionCookie: SessionCookie(
          value: map['cookieValue'] as String,
          expiresAt: DateTime.parse(map['cookieExpires'] as String),
          rawCookie: cookieRaw,
          modhash: cookieModhash,
        ),
        isDefault: map['isDefault'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> save(Account account) async {
    final accounts = loadAll();
    final index = accounts.indexWhere((a) => a.id == account.id);

    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }

    await _persistAll(accounts);
  }

  Future<void> remove(String accountId) async {
    final accounts = loadAll().where((a) => a.id != accountId).toList();
    await _persistAll(accounts);

    if (_prefs.getString(_activeAccountIdKey) == accountId) {
      await _prefs.remove(_activeAccountIdKey);
    }
  }

  Future<void> setActive(String accountId) async {
    await _prefs.setString(_activeAccountIdKey, accountId);
  }

  Account? loadActive() {
    final activeId = _prefs.getString(_activeAccountIdKey);
    if (activeId == null) return null;

    return loadAll().where((a) => a.id == activeId).firstOrNull;
  }

  Future<void> _persistAll(List<Account> accounts) async {
    final json = accounts
        .map((a) => {
              'id': a.id,
              'username': a.username,
              'cookieValue': a.sessionCookie.value,
              'cookieExpires': a.sessionCookie.expiresAt.toIso8601String(),
              'isDefault': a.isDefault,
              if (a.sessionCookie.rawCookie != null)
                'cookieRaw': a.sessionCookie.rawCookie,
              if (a.sessionCookie.modhash != null)
                'cookieModhash': a.sessionCookie.modhash,
            })
        .toList();
    await _prefs.setString(_accountsKey, jsonEncode(json));
  }
}
