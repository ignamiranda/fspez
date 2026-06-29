/// Response model for POST /api/media/asset.json upload lease request.
class UploadLease {
  final String assetId;
  final String assetUrl;
  final String uploadUrl;
  final Map<String, String> args;
  final String status;

  const UploadLease({
    required this.assetId,
    required this.assetUrl,
    required this.uploadUrl,
    required this.args,
    required this.status,
  });

  factory UploadLease.fromJson(Map<String, dynamic> json) {
    final argsRaw = json['args'] as Map<String, dynamic>? ?? {};
    return UploadLease(
      assetId: (json['asset_id'] as String?) ?? '',
      assetUrl: (json['asset_url'] as String?) ?? '',
      uploadUrl: (json['upload_url'] as String?) ?? '',
      args: argsRaw.map((k, v) => MapEntry(k, v.toString())),
      status: (json['status'] as String?) ?? '',
    );
  }
}
