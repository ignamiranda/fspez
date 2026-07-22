import 'package:equatable/equatable.dart';

/// Rich award data from Reddit's `all_awardings` API field.
///
/// Contains the icon URL, display name, and count for each award type
/// applied to a post or comment.
class AwardData with Equatable {
  /// Icon URL for the award (64px PNG typically).
  final String? iconUrl;

  /// Display name like "Silver", "Gold", "Wholesome", etc.
  final String name;

  /// Number of times this award was given.
  final int count;

  /// Hex color string (e.g. `#ff4500`) for the award, or null.
  final String? backgroundColor;

  const AwardData({
    this.iconUrl,
    required this.name,
    required this.count,
    this.backgroundColor,
  });

  @override
  List<Object?> get props => [iconUrl, name, count, backgroundColor];
}
