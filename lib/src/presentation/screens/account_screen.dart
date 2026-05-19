import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import 'auth_webview_screen.dart';
import 'saved_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccount = ref.watch(activeAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: activeAccount == null ? _buildLoggedOut(context) : _buildLoggedIn(context, ref, activeAccount),
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 64,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Not logged in',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthWebViewScreen()),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Add Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedIn(BuildContext context, WidgetRef ref, account) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: CircleAvatar(child: Text(account.username[0].toUpperCase())),
          title: Text(account.username),
          subtitle: const Text('Active account'),
          trailing: Icon(Icons.check_circle, color: theme.colorScheme.tertiary),
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
          leading: const Icon(Icons.history),
          title: const Text('History'),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Log Out'),
          onTap: () {
            ref.read(activeAccountProvider.notifier).removeAccount(account.id);
          },
        ),
      ],
    );
  }
}
