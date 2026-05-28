import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'screens/feed_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/account_screen.dart';
import 'screens/login_screen.dart';
import '../data/auth_providers.dart';
import '../data/inbox_providers.dart';

class FspezApp extends ConsumerWidget {
  const FspezApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'fspez',
      theme: FspezTheme.light(),
      darkTheme: FspezTheme.dark(),
      themeMode: ThemeMode.system,
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
    final account = ref.watch(activeAccountProvider);
    final isLoggedIn = account != null;

    if (_wasLoggedIn != null && _wasLoggedIn != isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
    _wasLoggedIn = isLoggedIn;

    return isLoggedIn ? const _MainShell() : const LoginScreen();
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    FeedScreen(),
    InboxScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(inboxUnreadCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
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
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(icon),
    );
  }
}
