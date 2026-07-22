/// Time filter for "Top" sort in feed listings.
///
/// Maps to Reddit's `t` query parameter. Used when [FeedSort.top] is selected
/// to restrict the time window of posts considered.
enum TopTimeFilter {
  hour('hour', 'Past Hour'),
  day('day', 'Today'),
  week('week', 'Past Week'),
  month('month', 'Past Month'),
  year('year', 'Past Year'),
  all('all', 'All Time');

  final String queryValue;
  final String label;

  const TopTimeFilter(this.queryValue, this.label);
}
