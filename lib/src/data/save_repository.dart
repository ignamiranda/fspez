import 'package:http/http.dart' as http;
import 'dart:io';
import '../domain/models/session_cookie.dart';

const _logPath = r'C:\Users\ignam\AppData\Local\Temp\opencode\save_debug.log';

class SaveRepository {
  Future<void> save(String fullname, {SessionCookie? sessionCookie}) async {
    if (sessionCookie == null) throw SaveException(statusCode: 0, body: 'No session');
    await _doRequest('https://old.reddit.com/api/save', fullname, sessionCookie);
  }

  Future<void> unsave(String fullname, {SessionCookie? sessionCookie}) async {
    if (sessionCookie == null) throw SaveException(statusCode: 0, body: 'No session');
    await _doRequest('https://old.reddit.com/api/unsave', fullname, sessionCookie);
  }

  Future<void> _doRequest(String url, String fullname, SessionCookie sessionCookie) async {
    final cookie = sessionCookie.rawCookie ?? 'reddit_session=${sessionCookie.value}';
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'Accept': '*/*',
      'X-Requested-With': 'XMLHttpRequest',
      'Cookie': cookie,
      if (sessionCookie.modhash != null) 'X-Modhash': sessionCookie.modhash!,
    };
    final uri = Uri.parse(url);
    try {
      final response = await http.post(uri, headers: headers, body: 'id=$fullname');
      final log = '=== SAVE (old.reddit.com, modhash) ===\n'
          'Time: ${DateTime.now()}\n'
          'URL: $url\n'
          'Fullname: $fullname\n'
          'Cookie length: ${cookie.length} chars\n'
          'Modhash: ${sessionCookie.modhash}\n'
          'Status: ${response.statusCode}\n'
          'CT: ${response.headers['content-type']}\n'
          'Body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}\n'
          '===================\n';
      await File(_logPath).writeAsString(log);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final ct = (response.headers['content-type'] ?? '').toLowerCase();
        if (!ct.contains('text/html')) return;
      }
      throw SaveException(statusCode: response.statusCode, body: response.body);
    } catch (e) {
      if (e is SaveException) rethrow;
      await File(_logPath).writeAsString('=== SAVE ERROR ===\n$e\n===================\n');
      throw SaveException(statusCode: 0, body: e.toString());
    }
  }
}

class SaveException implements Exception {
  final int statusCode;
  final String body;
  const SaveException({required this.statusCode, required this.body});
  @override
  String toString() => 'SaveException($statusCode): ${body.length > 200 ? body.substring(0, 200) : body}';
}
