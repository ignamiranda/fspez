import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class OptimisticStateNotifier<K, V> extends StateNotifier<Map<K, V>> {
  OptimisticStateNotifier() : super({});

  V effective(K key, V original) => state[key] ?? original;

  void optimisticSet(K key, V value) {
    state = {...state, key: value};
  }

  void optimisticRevert(K key, V? previous) {
    if (previous == null) {
      final copy = Map<K, V>.from(state)..remove(key);
      state = copy;
    } else {
      state = {...state, key: previous};
    }
  }
}
