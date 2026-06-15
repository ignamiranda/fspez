import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/data/auth_providers.dart';
import 'src/presentation/app.dart';
import 'src/presentation/screens/compose_autotest_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.environment['FSPEZ_AUTOTEST_COMPOSE'] == '1') {
    final sessionValue = Platform.environment['REDDIT_SESSION'];
    if (sessionValue == null || sessionValue.isEmpty) {
      stderr.writeln('FSPEZ_AUTOTEST_COMPOSE set but REDDIT_SESSION missing');
      exit(2);
    }

    runApp(
      MaterialApp(
        home: ComposeAutotestScreen(sessionValue: sessionValue),
      ),
    );
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final secureStorage = const FlutterSecureStorage();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        secureStorageProvider.overrideWithValue(secureStorage),
      ],
      child: const FspezApp(),
    ),
  );
}
