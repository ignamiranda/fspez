import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/models/account.dart';
import '../domain/models/session_cookie.dart';
import '../domain/repositories/i_account_repository.dart';

class AccountRepository implements IAccountRepository {
  static const _accountsKey = 'fspez_accounts';
  static const _activeAccountIdKey = 'fspez_active_account_id';

  final FlutterSecureStorage _storage;

  AccountRepository(this._storage);

  Future<String?> _tryRead(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }

  Future<List<Account>> loadAll() async {
    final json = await _tryRead(_accountsKey);
    if (json == null) {
      return [];
    }

    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return Account(
          id: map['id'] as String,
          username: map['username'] as String,
          sessionCookie: SessionCookie(
            value: map['cookieValue'] as String,
            expiresAt: DateTime.parse(map['cookieExpires'] as String),
            rawCookie: map['cookieRaw'] as String?,
            modhash: map['cookieModhash'] as String?,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('AccountRepository.loadAll JSON deserialization failed: $e');
      // Corrupted data — clear and return empty.
      try {
        await _storage.delete(key: _accountsKey);
      } on PlatformException {
        // Best-effort cleanup.
      }
      return [];
    }
  }

  Future<void> save(Account account) async {
    final accounts = await loadAll();
    final idIndex = accounts.indexWhere((a) => a.id == account.id);
    if (idIndex >= 0) {
      accounts[idIndex] = account;
      await _persistAll(accounts);
      return;
    }

    final usernameIndex =
        accounts.indexWhere((a) => a.username == account.username);
    if (usernameIndex >= 0) {
      accounts[usernameIndex] = account;
    } else {
      accounts.add(account);
    }

    await _persistAll(accounts);
  }

  Future<void> clearAllExcept(String accountId) async {
    final accounts = await loadAll();
    final active = accounts.where((a) => a.id == accountId).toList();
    await _persistAll(active);
  }

  Future<void> replaceAll(List<Account> accounts) async {
    await _persistAll(accounts);
  }

  Future<void> remove(String accountId) async {
    final accounts = await loadAll();
    final remaining = accounts.where((a) => a.id != accountId).toList();
    await _persistAll(remaining);

    final activeId = await _tryRead(_activeAccountIdKey);
    if (activeId == null) return;
    if (activeId == accountId) {
      await _storage.delete(key: _activeAccountIdKey);
    }
  }

  Future<void> setActive(String accountId) async {
    await _storage.write(key: _activeAccountIdKey, value: accountId);
  }

  Future<Account?> loadActive() async {
    final activeId = await _tryRead(_activeAccountIdKey);
    if (activeId == null) return null;
    final all = await loadAll();
    return all.where((a) => a.id == activeId).firstOrNull;
  }

  Future<void> _persistAll(List<Account> accounts) async {
    final json = accounts
        .map((a) => {
              'id': a.id,
              'username': a.username,
              'cookieValue': a.sessionCookie.value,
              'cookieExpires': a.sessionCookie.expiresAt.toIso8601String(),
              if (a.sessionCookie.rawCookie != null)
                'cookieRaw': a.sessionCookie.rawCookie,
              if (a.sessionCookie.modhash != null)
                'cookieModhash': a.sessionCookie.modhash,
            })
        .toList();
    await _storage.write(key: _accountsKey, value: jsonEncode(json));
  }
}
