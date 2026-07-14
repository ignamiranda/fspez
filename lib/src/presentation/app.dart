import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tab_scroll_signal.dart';
import 'theme.dart';
import 'screens/feed_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/account_screen.dart';
import 'screens/login_screen.dart';
import 'screens/auth_webview_screen.dart';
import '../data/app_settings.dart';
import '../data/auth_providers.dart';
import '../data/inbox_providers.dart';
import 'providers/guest_mode_provider.dart';
import '../data/session_health.dart';
import '../domain/enums/app_theme_mode.dart';
import '../domain/models/session_cookie.dart';

class FspezApp extends ConsumerWidget {
  const FspezApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isAmoled = settings.themeMode == AppThemeMode.amoled;

    return MaterialApp(
      title: 'fspez',
      theme: FspezTheme.light(),
      darkTheme: isAmoled ? FspezTheme.amoled() : FspezTheme.dark(),
      themeMode: settings.themeMode.toThemeMode(),
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> {
  bool? _wasLoggedIn;

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(corruptedSessionProvider, (prev, next) {
      if (next == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Saved session data was corrupted. Please sign in again.',
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () =>
                    ref.read(corruptedSessionProvider.notifier).state = false,
              ),
            ),
          );
        });
      }
    });

    final account = ref.watch(activeAccountProvider);
    final isGuest = ref.watch(guestModeProvider);
    final isLoggedIn = account != null;

    if (_wasLoggedIn != null && _wasLoggedIn != isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
    _wasLoggedIn = isLoggedIn;

    return isGuest || isLoggedIn ? const _MainShell() : const LoginScreen();
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _selectedIndex = 0;
  SessionHealthStatus? _lastHealthStatus;

  static const _screens = <Widget>[
    FeedScreen(),
    InboxScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(inboxUnreadCountProvider);

    ref.listen(sessionHealthProvider, (_, next) {
      final health = next.valueOrNull;

      // Apply modhash from API response if stored cookie lacked one
      if (health?.newModhash != null) {
        final account = ref.read(activeAccountProvider);
        if (account != null &&
            account.sessionCookie.modhash != health!.newModhash) {
          ref.read(activeAccountProvider.notifier).updateSessionCookie(
                SessionCookie(
                  value: account.sessionCookie.value,
                  expiresAt: account.sessionCookie.expiresAt,
                  rawCookie: account.sessionCookie.rawCookie,
                  modhash: health.newModhash,
                ),
              );
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final messenger = ScaffoldMessenger.of(context);
        if (health == null || !health.needsRecovery) {
          messenger.clearMaterialBanners();
          _lastHealthStatus = null;
          return;
        }

        if (_lastHealthStatus == health.status) return;
        _lastHealthStatus = health.status;

        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          MaterialBanner(
            content: Text('${health.title}. ${health.message}'),
            actions: [
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                child: const Text('Account'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthWebViewScreen(),
                    ),
                  );
                },
                child: Text(health.actionLabel),
              ),
            ],
          ),
        );
      });
    });

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == _selectedIndex) {
            ref.read(tabScrollSignalProvider.notifier).state++;
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: _InboxNavIcon(
              count: unreadCount,
              icon: Icons.mail_outlined,
            ),
            selectedIcon: _InboxNavIcon(
              count: unreadCount,
              icon: Icons.mail,
            ),
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _InboxNavIcon extends StatelessWidget {
  final int count;
  final IconData icon;

  const _InboxNavIcon({required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: count > 0 ? 'Inbox, $count unread messages' : 'Inbox',
      child: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(icon),
      ),
    );
  }
}
