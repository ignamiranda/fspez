import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/data/session_health.dart';
import 'package:fspez/src/domain/models/account.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    client = RedditClient(httpClient: mockHttp);
  });

  Account buildAccount({String? modhash}) {
    return Account(
      id: '1',
      username: 'testuser',
      sessionCookie: SessionCookie(
        value: 'cookie',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        modhash: modhash,
      ),
    );
  }

  String htmlWithModhash(String modhash) {
    return '''<html><script id="__NEXT_DATA__" type="application/json">
{"props":{"pageProps":{"user":{"name":"testuser"},"modhash":"$modhash"}}}
</script></html>''';
  }

  String htmlNoModhash() {
    return '''<html><script id="__NEXT_DATA__" type="application/json">
{"props":{"pageProps":{"user":{"name":"testuser"}}}}
</script></html>''';
  }

  test('returns healthy when shredded HTML shows user and modhash exists',
      () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(htmlWithModhash('abc'), 200));

    final health =
        await checkSessionHealth(client, buildAccount(modhash: 'abc'));

    expect(health.status, SessionHealthStatus.healthy);
  });

  test(
      'returns healthy with newModhash when HTML provides one but stored is absent',
      () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(htmlWithModhash('abc'), 200));

    final health = await checkSessionHealth(client, buildAccount());

    expect(health.status, SessionHealthStatus.healthy);
    expect(health.newModhash, 'abc');
  });

  test('returns missingModhash when both stored and HTML modhash are absent',
      () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(htmlNoModhash(), 200));

    final health = await checkSessionHealth(client, buildAccount());

    expect(health.status, SessionHealthStatus.missingModhash);
    expect(health.newModhash, isNull);
  });

  test('returns expired on forbidden response', () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response('Forbidden', 403));

    final health =
        await checkSessionHealth(client, buildAccount(modhash: 'abc'));

    expect(health.status, SessionHealthStatus.expired);
  });
}
