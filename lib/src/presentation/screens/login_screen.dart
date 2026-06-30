import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import 'auth_webview_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reddit, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('fspez',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              Text('A third-party Reddit client',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AuthWebViewScreen()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Log in with Reddit'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(guestModeProvider.notifier).state = true,
                child: const Text('Browse as guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
