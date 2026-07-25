import '../domain/enums/vote_direction.dart';

Map<String, dynamic> pageProps(Map<String, dynamic> extracted) {
  final props = extracted['props'] as Map<String, dynamic>?;
  if (props == null) return extracted;
  return props['pageProps'] as Map<String, dynamic>? ?? extracted;
}

VoteDirection parseVote(dynamic likes) {
  if (likes == true) return VoteDirection.upvote;
  if (likes == false) return VoteDirection.downvote;
  return VoteDirection.none;
}

int? intOr(Map<String, dynamic> map, String key) => map[key] as int?;

bool? boolOr(Map<String, dynamic> map, String key) => map[key] as bool?;

double? doubleOr(Map<String, dynamic> map, String key) =>
    (map[key] as num?)?.toDouble();

final _fullnameRegex = RegExp(r'^t[0-9]+_');

String? extractUsernameFromHtml(String html) {
  final patterns = [
    RegExp(r'"loggedInUser"\s*:\s*"([^"]+)"'),
    RegExp(r'"user"\s*:\s*\{\s*"name"\s*:\s*"([^"]+)"'),
    RegExp(r'"username"\s*:\s*"([^"]+)"'),
    RegExp(r'<shreddit-app[^>]*username="([^"]+)"'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(html);
    if (match != null) {
      final name = match.group(1);
      if (name != null &&
          name.isNotEmpty &&
          name.length < 30 &&
          !_fullnameRegex.hasMatch(name)) {
        return name;
      }
    }
  }

  return null;
}

String? extractModhashFromHtml(String html) {
  final patterns = [
    RegExp(r'"modhash"\s*:\s*"([^"]+)"'),
    RegExp(r'name="uh"\s+value="([^"]+)"'),
    RegExp(r'X-Modhash:\s*([a-z0-9]+)'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(html);
    if (match != null) {
      final hash = match.group(1);
      if (hash != null && hash.isNotEmpty) return hash;
    }
  }

  return null;
}
