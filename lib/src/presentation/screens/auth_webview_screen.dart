import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../data/auth_service.dart';
import '../../domain/models/account.dart';

class AuthWebViewScreen extends ConsumerStatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  ConsumerState<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends ConsumerState<AuthWebViewScreen> {
  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid && !Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account login requires Android or iOS.'),
          ),
        );
        Navigator.of(context).pop();
      });
      return;
    }
    _startLogin();
  }

  Future<void> _startLogin() async {
    final authService = ref.read(authServiceProvider);

    authService.authState.listen((state) {
      if (state == AuthState.authenticated && mounted) {
        Navigator.of(context).pop();
      }
    });

    try {
      final cookie = await authService.login();

      final account = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: _extractUsername(cookie.value),
        sessionCookie: cookie,
        isDefault: true,
      );

      if (mounted) {
        ref.read(activeAccountProvider.notifier).addAccount(account);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  String _extractUsername(String cookieValue) {
    try {
      final parts = cookieValue.split('.');
      if (parts.length >= 2) {
        return 'user_${cookieValue.hashCode.abs().toString().substring(0, 6)}';
      }
    } catch (_) {}
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening Reddit login...'),
          ],
        ),
      ),
    );
  }
}
