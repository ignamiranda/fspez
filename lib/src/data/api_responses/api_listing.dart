import 'api_post.dart';

class ApiListing {
  final String? after;
  final String? before;
  final List<ApiPost> children;

  ApiListing({this.after, this.before, required this.children});

  factory ApiListing.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final children = (data['children'] as List<dynamic>)
        .map((c) => ApiPost.fromJson(c['data'] as Map<String, dynamic>))
        .toList();
    return ApiListing(
      after: data['after'] as String?,
      before: data['before'] as String?,
      children: children,
    );
  }

  factory ApiListing.fromListing(Map<String, dynamic> json) {
    return ApiListing.fromJson(json);
  }
}
