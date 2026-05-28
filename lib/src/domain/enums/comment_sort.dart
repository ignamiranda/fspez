enum CommentSort {
  best('best', 'Best'),
  top('top', 'Top'),
  new_('new', 'New'),
  controversial('controversial', 'Controversial'),
  old('old', 'Old');

  final String queryValue;
  final String label;

  const CommentSort(this.queryValue, this.label);
}
