/// Feed card density mode, persisted in SharedPreferences.
enum FeedDensity {
  comfortable('comfortable', 'Comfortable'),
  compact('compact', 'Compact');

  final String persistKey;
  final String label;

  const FeedDensity(this.persistKey, this.label);

  static FeedDensity fromPersistKey(String? key) {
    if (key == null) return FeedDensity.comfortable;
    for (final density in FeedDensity.values) {
      if (density.persistKey == key) return density;
    }
    return FeedDensity.comfortable;
  }
}
