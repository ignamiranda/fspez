import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/data/subreddit_repository.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late SubredditRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    repository = SubredditRepository(RedditClient(httpClient: mockHttp));
  });

  test('fetch parses subreddit about details', () async {
    when(() => mockHttp.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'kind': 't5',
          'data': {
            'id': '2qh33',
            'display_name': 'flutter',
            'public_description': 'Flutter community',
            'description': 'Long sidebar text',
            'subscribers': 123456,
            'active_user_count': 789,
            'created_utc': 1200000000,
            'over18': true,
            'quarantine': true,
            'user_is_subscriber': true,
            'subreddit_type': 'restricted',
            'icon_img': 'https://example.com/icon.png?x=1&amp;y=2',
            'banner_img': 'https://example.com/banner.png',
          },
        }),
        200,
      ),
    );

    final subreddit = await repository.fetch('flutter');

    expect(subreddit.id, '2qh33');
    expect(subreddit.name, 'flutter');
    expect(subreddit.description, 'Flutter community');
    expect(subreddit.sidebarDescription, 'Long sidebar text');
    expect(subreddit.subscriberCount, 123456);
    expect(subreddit.activeUserCount, 789);
    expect(subreddit.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1200000000 * 1000));
    expect(subreddit.isNsfw, isTrue);
    expect(subreddit.isQuarantined, isTrue);
    expect(subreddit.isSubscribed, isTrue);
    expect(subreddit.isRestricted, isTrue);
    expect(subreddit.iconUrl, 'https://example.com/icon.png?x=1&y=2');
    expect(subreddit.bannerUrl, 'https://example.com/banner.png');

    verify(
      () => mockHttp.get(
        Uri.parse('https://old.reddit.com/r/flutter/about.json'),
        headers: any(named: 'headers'),
      ),
    ).called(1);
  });

  test('fetchRules parses and sorts subreddit rules', () async {
    when(() => mockHttp.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'rules': [
            {
              'short_name': 'Second rule',
              'description': 'No spam',
              'kind': 'all',
              'violation_reason': 'Spam',
              'priority': 1,
            },
            {
              'short_name': 'First rule',
              'description': 'Be kind',
              'kind': 'comment',
              'violation_reason': 'Unkind',
              'priority': 0,
            },
          ],
          'site_rules': ['Spam'],
        }),
        200,
      ),
    );

    final rules = await repository.fetchRules('flutter');

    expect(rules, hasLength(2));
    expect(rules[0].shortName, 'First rule');
    expect(rules[0].description, 'Be kind');
    expect(rules[0].kind, 'comment');
    expect(rules[0].violationReason, 'Unkind');
    expect(rules[0].priority, 0);
    expect(rules[1].shortName, 'Second rule');

    verify(
      () => mockHttp.get(
        Uri.parse('https://old.reddit.com/r/flutter/about/rules.json'),
        headers: any(named: 'headers'),
      ),
    ).called(1);
  });
}
