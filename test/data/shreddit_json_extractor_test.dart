import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/shreddit_json_extractor.dart';

void main() {
  group('ShredditJsonExtractor.extract', () {
    test('returns empty map for no script tags', () {
      final result =
          ShredditJsonExtractor.extract('<html><body></body></html>');
      expect(result, isEmpty);
    });

    test('returns empty map for null', () {
      final result = ShredditJsonExtractor.extract('');
      expect(result, isEmpty);
    });

    test('extracts from __NEXT_DATA__ script tag', () {
      const html = '''
        <html>
        <head><script id="__NEXT_DATA__" type="application/json">{"props":{"pageProps":{"test":"value"}}}</script></head>
        </html>
      ''';
      final result = ShredditJsonExtractor.extract(html);
      expect(result, isNotEmpty);
      expect(result['props']['pageProps']['test'], 'value');
    });

    test('returns empty map for invalid JSON in __NEXT_DATA__', () {
      const html = '''
        <html>
        <head><script id="__NEXT_DATA__" type="application/json">{invalid}</script></head>
        </html>
      ''';
      final result = ShredditJsonExtractor.extract(html);
      expect(result, isEmpty);
    });

    test('extracts from window.__INITIAL_STATE__ pattern', () {
      const html = '''
        <html>
        <script>window.__INITIAL_STATE__ = {"user":{"name":"testuser"}};</script>
        </html>
      ''';
      final result = ShredditJsonExtractor.extract(html);
      expect(result['user']['name'], 'testuser');
    });

    test('extracts from window.__r pattern', () {
      const html = '''
        <html>
        <script id="data">window.__r = {"data":{"key":"value"}};</script>
        </html>
      ''';
      final result = ShredditJsonExtractor.extract(html);
      expect(result['data']['key'], 'value');
    });

    test('prefers __NEXT_DATA__ over other patterns', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">{"source":"next"}</script>
        <script>window.__INITIAL_STATE__ = {"source":"init"};</script>
        </html>
      ''';
      final result = ShredditJsonExtractor.extract(html);
      expect(result['source'], 'next');
    });
  });
}
