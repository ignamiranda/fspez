import 'format_utils.dart';

String formatRedditAccountAge(DateTime createdAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(createdAt);
  final safeDays = diff.isNegative ? 0 : diff.inDays;

  if (safeDays < 30) {
    return 'Redditor for $safeDays day${safeDays == 1 ? '' : 's'}';
  }

  final months = safeDays ~/ 30;
  if (months < 12) {
    return 'Redditor for $months month${months == 1 ? '' : 's'}';
  }

  final years = safeDays ~/ 365;
  return 'Redditor for $years year${years == 1 ? '' : 's'}';
}

String formatProfileKarmaCount(int count) {
  return count == 0 ? '0' : formatCount(count);
}

String formatProfileKarmaBreakdown(int linkKarma, int commentKarma) {
  return 'Post karma: ${formatProfileKarmaCount(linkKarma)} · '
      'Comment karma: ${formatProfileKarmaCount(commentKarma)}';
}
