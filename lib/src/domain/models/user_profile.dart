import 'package:equatable/equatable.dart';

class UserProfile with EquatableMixin {
  final String id;
  final String username;
  final int linkKarma;
  final int commentKarma;
  final DateTime createdAt;
  final String? iconUrl;
  final bool isGold;
  final bool isMod;
  final String? subredditName;

  const UserProfile({
    required this.id,
    required this.username,
    this.linkKarma = 0,
    this.commentKarma = 0,
    required this.createdAt,
    this.iconUrl,
    this.isGold = false,
    this.isMod = false,
    this.subredditName,
  });

  /// The Reddit fullname for this user (t2_{id}).
  String get accountId => 't2_$id';

  @override
  List<Object?> get props => [
    id,
    username,
    linkKarma,
    commentKarma,
    createdAt,
    iconUrl,
    isGold,
    isMod,
    subredditName,
  ];
}
