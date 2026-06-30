import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/session_health.dart';
import '../../domain/models/account.dart';
import '../tab_scroll_signal.dart';
import 'auth_webview_screen.dart';
import 'saved_screen.dart';
import 'hidden_screen.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(tabScrollSignalProvider, (_, __) {
      final c = _scrollController;
      if (c != null && c.hasClients && c.offset > 0) {
        c.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });

    final activeAccount = ref.watch(activeAccountProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrNull ?? <Account>[];
    final sessionHealth = ref.watch(sessionHealthProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: activeAccount == null
          ? _buildGuestView(context)
          : _buildLoggedIn(context, accounts, activeAccount, sessionHealth),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.person_outline,
                    size: 64, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('Browsing as guest',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Log in to access your account, inbox, and post.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthWebViewScreen()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          onTap: () => _openSettings(context),
        ),
      ],
    );
  }

  Widget _buildLoggedIn(
    BuildContext context,
    List<dynamic> accounts,
    dynamic activeAccount,
    SessionHealth? sessionHealth,
  ) {
    final theme = Theme.of(context);
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (sessionHealth != null && sessionHealth.needsRecovery)
          _SessionHealthCard(
            health: sessionHealth,
            onRelogin: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthWebViewScreen()),
              );
            },
          ),
        if (sessionHealth != null && sessionHealth.needsRecovery)
          const SizedBox(height: 16),
        Text('Accounts',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 8),
        for (final account in accounts) ...[
          ListTile(
            leading: CircleAvatar(
              child: Text(account.username[0].toUpperCase()),
            ),
            title: Text(account.username),
            subtitle: account.id == activeAccount.id
                ? Text('Active',
                    style: TextStyle(color: theme.colorScheme.tertiary))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (account.id == activeAccount.id)
                  Icon(Icons.check_circle, color: theme.colorScheme.tertiary),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  onPressed: () => _removeAccount(context, account),
                ),
              ],
            ),
            onTap: account.id == activeAccount.id
                ? null
                : () => _switchAccount(account),
          ),
          if (account != accounts.last) const Divider(height: 1),
        ],
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.person_add),
          title: const Text('Add Account'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuthWebViewScreen()),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('My Profile'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    UserProfileScreen(username: activeAccount.username),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.bookmark_outline),
          title: const Text('Saved'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.visibility_off_outlined),
          title: const Text('Hidden'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HiddenScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('History'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    UserProfileScreen(username: activeAccount.username),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          onTap: () => _openSettings(context),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: theme.colorScheme.error),
          title:
              Text('Log Out', style: TextStyle(color: theme.colorScheme.error)),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Log Out'),
                content: Text('Remove account ${activeAccount.username}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              ref
                  .read(activeAccountProvider.notifier)
                  .removeAccount(activeAccount.id);
            }
          },
        ),
      ],
    );
  }

  void _switchAccount(dynamic account) {
    ref.read(activeAccountProvider.notifier).setActive(account);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _removeAccount(BuildContext context, dynamic account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text('Remove ${account.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(activeAccountProvider.notifier).removeAccount(account.id);
    }
  }
}

class _SessionHealthCard extends StatelessWidget {
  final SessionHealth health;
  final VoidCallback onRelogin;

  const _SessionHealthCard({
    required this.health,
    required this.onRelogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    health.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${health.message} Tap another account below or re-login.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onRelogin,
                  child: Text(health.actionLabel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AuthWebViewScreen(),
                      ),
                    );
                  },
                  child: const Text('Add account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
