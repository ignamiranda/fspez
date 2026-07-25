import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/rss_feed_parser.dart';

void main() {
  late RssFeedParser parser;

  setUp(() {
    parser = RssFeedParser();
  });

  group('parseFeedXml', () {
    test('returns empty listing for empty string', () {
      final result = parser.parseFeedXml('');
      expect(result['data']['children'], isEmpty);
    });

    test('returns empty listing for non-XML', () {
      final result = parser.parseFeedXml('not xml');
      expect(result['data']['children'], isEmpty);
    });

    test('parses Atom feed with entries', () {
      const atom = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>t3_abc123</id>
    <title>Test Post Title</title>
    <author><name>testauthor</name></author>
    <published>2024-01-15T10:30:00+00:00</published>
    <link href="https://www.reddit.com/r/flutter/comments/abc123/test_post_title/" rel="alternate"/>
    <content type="html">&lt;!-- SC_OFF --&gt;&lt;p&gt;Post body here&lt;/p&gt;&lt;!-- SC_ON --&gt;</content>
    <category term="link" scheme="https://www.reddit.com/r/flutter"/>
  </entry>
</feed>''';
      final result = parser.parseFeedXml(atom);
      final children = result['data']['children'] as List;
      expect(children.length, 1);

      final post = children[0] as Map<String, dynamic>;
      expect(post['kind'], 't3');
      final data = post['data'] as Map<String, dynamic>;
      expect(data['id'], 'abc123');
      expect(data['title'], 'Test Post Title');
      expect(data['author'], 'testauthor');
      expect(data['subreddit'], 'flutter');
      expect(data['score'], 0);
      expect(data['num_comments'], 0);
      expect(data['permalink'], '/r/flutter/comments/abc123/test_post_title/');
      expect(data['selftext'], '<p>Post body here</p>');
    });

    test('parses multiple Atom entries', () {
      const atom = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>t3_post1</id>
    <title>Post One</title>
    <author><name>author1</name></author>
    <published>2024-01-15T10:00:00+00:00</published>
    <link href="https://www.reddit.com/r/test/comments/post1/p1/" rel="alternate"/>
  </entry>
  <entry>
    <id>t3_post2</id>
    <title>Post Two</title>
    <author><name>author2</name></author>
    <published>2024-01-15T11:00:00+00:00</published>
    <link href="https://www.reddit.com/r/test/comments/post2/p2/" rel="alternate"/>
  </entry>
</feed>''';
      final result = parser.parseFeedXml(atom);
      final children = result['data']['children'] as List;
      expect(children.length, 2);
      expect((children[0] as Map)['data']['title'], 'Post One');
      expect((children[1] as Map)['data']['title'], 'Post Two');
    });

    test('creates createdAt from timestamp', () {
      const atom = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>t3_post1</id>
    <title>Test</title>
    <author><name>user</name></author>
    <published>2024-06-15T12:00:00+00:00</published>
    <link href="https://www.reddit.com/r/test/comments/post1/t/" rel="alternate"/>
  </entry>
</feed>''';
      final result = parser.parseFeedXml(atom);
      final data = (result['data']['children'] as List)[0]['data']
          as Map<String, dynamic>;
      expect(data['created_utc'], greaterThan(0));
    });

    test('handles missing author', () {
      const atom = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>t3_post1</id>
    <title>No Author</title>
    <published>2024-01-15T10:00:00+00:00</published>
    <link href="https://www.reddit.com/r/test/comments/post1/p/" rel="alternate"/>
  </entry>
</feed>''';
      final result = parser.parseFeedXml(atom);
      final data = (result['data']['children'] as List)[0]['data']
          as Map<String, dynamic>;
      expect(data['author'], '[deleted]');
    });

    test('handles NSFW category', () {
      const atom = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>t3_nsfw</id>
    <title>NSFW Post</title>
    <author><name>user</name></author>
    <published>2024-01-15T10:00:00+00:00</published>
    <link href="https://www.reddit.com/r/test/comments/nsfw/p/" rel="alternate"/>
    <category term="nsfw" scheme="https://www.reddit.com/r/test"/>
  </entry>
</feed>''';
      final result = parser.parseFeedXml(atom);
      final data = (result['data']['children'] as List)[0]['data']
          as Map<String, dynamic>;
      expect(data['over_18'], true);
    });

    test('after is null when no next link', () {
      const atom = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>t3_post</id>
    <title>Test</title>
    <author><name>user</name></author>
    <published>2024-01-15T10:00:00+00:00</published>
    <link href="https://www.reddit.com/r/test/comments/post/p/" rel="alternate"/>
  </entry>
</feed>''';
      final result = parser.parseFeedXml(atom);
      expect(result['data']['after'], isNull);
    });

    test('extracts after from next link', () {
      const atom = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <link rel="next" href="https://www.reddit.com/r/test/.rss?after=t3_cursor"/>
  <entry>
    <id>t3_post</id>
    <title>Test</title>
    <author><name>user</name></author>
    <published>2024-01-15T10:00:00+00:00</published>
    <link href="https://www.reddit.com/r/test/comments/post/p/" rel="alternate"/>
  </entry>
</feed>''';
      final result = parser.parseFeedXml(atom);
      expect(result['data']['after'], 't3_cursor');
    });
  });
}

