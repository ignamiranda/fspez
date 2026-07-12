import 'package:equatable/equatable.dart';

class UserProfile with Equatable {
  final String id;
  final String username;
  final int linkKarma;
  final int commentKarma;
  final DateTime createdAt;
  final String? iconUrl;
  final bool isGold;
  final bool isMod;
  final List<String> moderatedSubreddits;

  const UserProfile({
    required this.id,
    required this.username,
    this.linkKarma = 0,
    this.commentKarma = 0,
    required this.createdAt,
    this.iconUrl,
    this.isGold = false,
    this.isMod = false,
    this.moderatedSubreddits = const [],
  });

  /// The Reddit fullname for this user (t2_{id}).
  String get accountId => 't2_$id';

  UserProfile copyWith({
    String? id,
    String? username,
    int? linkKarma,
    int? commentKarma,
    DateTime? createdAt,
    String? iconUrl,
    bool? isGold,
    bool? isMod,
    List<String>? moderatedSubreddits,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      linkKarma: linkKarma ?? this.linkKarma,
      commentKarma: commentKarma ?? this.commentKarma,
      createdAt: createdAt ?? this.createdAt,
      iconUrl: iconUrl ?? this.iconUrl,
      isGold: isGold ?? this.isGold,
      isMod: isMod ?? this.isMod,
      moderatedSubreddits: moderatedSubreddits ?? this.moderatedSubreddits,
    );
  }

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
    moderatedSubreddits,
  ];
}
