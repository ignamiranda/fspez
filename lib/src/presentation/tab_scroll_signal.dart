import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented each time the user taps an already-active bottom nav tab,
/// signaling the visible screen to scroll its primary list to the top.
final tabScrollSignalProvider = StateProvider<int>((ref) => 0);
