import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fspez/src/data/account_notifier.dart';
import 'package:fspez/src/data/account_repository.dart';
import 'package:fspez/src/data/auth_providers.dart';
import 'package:fspez/src/data/feed_cache.dart';
import 'package:fspez/src/domain/models/account.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'account_repository_test.dart' show FakeSecureStorage;

class ThrowingAccountRepository extends AccountRepository {
  ThrowingAccountRepository() : super(FakeSecureStorage());

  @override
  Future<Account?> loadActive() async {
    throw PlatformException(code: 'read', message: 'BadPaddingException');
  }

  @override
  Future<List<Account>> loadAll() async {
    throw PlatformException(code: 'read', message: 'BadPaddingException');
  }
}

void main() {
  group('ActiveAccountNotifier corrupted storage', () {
    test('falls back to null state on PlatformException', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final corrupted = StateProvider<bool>((ref) => false);
      final container = ProviderContainer();
      final notifier = ActiveAccountNotifier(
        ThrowingAccountRepository(),
        AccountListVersionNotifier(),
        FeedCache(prefs),
        container.read(corrupted.notifier),
      );

      await Future(() {});
      await Future(() {});

      expect(notifier.state, isNull);
      expect(container.read(corrupted), isTrue);
      container.dispose();
    });
  });
}
