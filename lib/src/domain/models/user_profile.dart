import 'package:equatable/equatable.dart';

class UserProfile with EquatableMixin {
  final String username;
  final int linkKarma;
  final int commentKarma;
  final DateTime createdAt;
  final String? iconUrl;
  final bool isGold;
  final bool isMod;
  final String? subredditName;

  const UserProfile({
    required this.username,
    this.linkKarma = 0,
    this.commentKarma = 0,
    required this.createdAt,
    this.iconUrl,
    this.isGold = false,
    this.isMod = false,
    this.subredditName,
  });

  @override
  List<Object?> get props => [
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
