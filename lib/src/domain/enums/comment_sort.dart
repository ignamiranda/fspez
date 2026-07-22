enum CommentSort {
  best('best', 'Best'),
  top('top', 'Top'),
  new_('new', 'New'),
  controversial('controversial', 'Controversial'),
  old('old', 'Old'),
  qa('qa', 'Q&A');

  final String queryValue;
  final String label;

  const CommentSort(this.queryValue, this.label);
}
