import 'package:equatable/equatable.dart';

class SearchUser with Equatable {
  final String name;
  final int linkKarma;
  final int commentKarma;
  final String? iconImg;
  final bool isGold;
  final bool isMod;

  const SearchUser({
    required this.name,
    this.linkKarma = 0,
    this.commentKarma = 0,
    this.iconImg,
    this.isGold = false,
    this.isMod = false,
  });

  String get displayName => 'u/$name';

  @override
  List<Object?> get props => [
        name,
        linkKarma,
        commentKarma,
        iconImg,
        isGold,
        isMod,
      ];
}
