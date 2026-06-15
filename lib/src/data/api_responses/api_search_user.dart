import '../../domain/models/search_user.dart';

class ApiSearchUser {
  final String name;
  final int linkKarma;
  final int commentKarma;
  final String? iconImg;
  final bool isGold;
  final bool isMod;

  ApiSearchUser({
    required this.name,
    required this.linkKarma,
    required this.commentKarma,
    this.iconImg,
    required this.isGold,
    required this.isMod,
  });

  factory ApiSearchUser.fromJson(Map<String, dynamic> data) {
    return ApiSearchUser(
      name: data['name'] as String? ?? '',
      linkKarma: data['link_karma'] as int? ?? 0,
      commentKarma: data['comment_karma'] as int? ?? 0,
      iconImg: data['icon_img'] as String?,
      isGold: data['is_gold'] as bool? ?? false,
      isMod: data['is_mod'] as bool? ?? false,
    );
  }

  SearchUser toDomain() {
    return SearchUser(
      name: name,
      linkKarma: linkKarma,
      commentKarma: commentKarma,
      iconImg: iconImg?.replaceAll('&amp;', '&'),
      isGold: isGold,
      isMod: isMod,
    );
  }
}
