enum FeedSort {
  hot,
  new_,
  top,
  rising,
  controversial,
  best;

  String get label => name.replaceAll('_', '');
}
