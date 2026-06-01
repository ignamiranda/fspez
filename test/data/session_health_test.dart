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

  test('returns healthy when /api/me matches and modhash exists', () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          '{"data":{"name":"testuser","modhash":"abc"}}',
          200,
        ));

    final health =
        await checkSessionHealth(client, buildAccount(modhash: 'abc'));

    expect(health.status, SessionHealthStatus.healthy);
  });

  test(
      'returns healthy with newModhash when API provides one but stored is absent',
      () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          '{"data":{"name":"testuser","modhash":"abc"}}',
          200,
        ));

    final health = await checkSessionHealth(client, buildAccount());

    expect(health.status, SessionHealthStatus.healthy);
    expect(health.newModhash, 'abc');
  });

  test('returns missingModhash when both stored and API modhash are absent',
      () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          '{"data":{"name":"testuser"}}',
          200,
        ));

    final health = await checkSessionHealth(client, buildAccount());

    expect(health.status, SessionHealthStatus.missingModhash);
    expect(health.newModhash, isNull);
  });

  test('returns expired on forbidden /api/me response', () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response('Forbidden', 403));

    final health =
        await checkSessionHealth(client, buildAccount(modhash: 'abc'));

    expect(health.status, SessionHealthStatus.expired);
  });
}
