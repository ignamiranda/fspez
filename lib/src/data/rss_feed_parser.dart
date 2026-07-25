import 'package:xml/xml.dart';

class RssFeedParser {
  Map<String, dynamic> parseFeedXml(String xmlString) {
    XmlDocument document;
    try {
      document = XmlDocument.parse(xmlString);
    } catch (_) {
      return _emptyListing();
    }
    final feed = document.findElements('feed').firstOrNull ??
        document.findElements('rss').firstOrNull;
    if (feed == null) return _emptyListing();

    if (feed.name.local == 'rss') {
      return _parseRss(feed);
    }
    return _parseAtom(feed);
  }

  Map<String, dynamic> _parseAtom(XmlElement feed) {
    final entries = feed.findElements('entry');
    final children = entries.map(_atomEntryToChild).toList();
    final after = _extractAtomAfter(feed);

    return {
      'data': {
        'children': children,
        'after': after,
        'before': null,
      },
    };
  }

  Map<String, dynamic> _parseRss(XmlElement rss) {
    final channel = rss.findElements('channel').firstOrNull;
    if (channel == null) return _emptyListing();

    final items = channel.findElements('item');
    final children = items.map(_rssItemToChild).toList();

    return {
      'data': {
        'children': children,
        'after': null,
        'before': null,
      },
    };
  }

  Map<String, dynamic> _atomEntryToChild(XmlElement entry) {
    final id = _atomText(entry, 'id') ?? '';
    final shortId = id.replaceFirst(RegExp(r'^t3_'), '');
    final title = _atomText(entry, 'title') ?? '';
    final authorText = _atomAuthor(entry);
    final published =
        _atomText(entry, 'published') ?? _atomText(entry, 'updated') ?? '';
    final link = _atomLink(entry);
    final content = _atomText(entry, 'content') ?? '';
    final categoryTerm = _atomCategoryTerm(entry);

    final createdUtc = _parseAtomDate(published);
    final permalink = _extractPermalink(link, shortId);

    return {
      'kind': 't3',
      'data': {
        'id': shortId,
        'title': title,
        'author': authorText,
        'subreddit': _extractSubreddit(link),
        'subreddit_id': '',
        'selftext': _stripContentTags(content),
        'url': link,
        'thumbnail': 'self',
        'score': 0,
        'num_comments': 0,
        'likes': null,
        'over_18': categoryTerm == 'nsfw',
        'spoiler': false,
        'saved': false,
        'stickied': false,
        'locked': false,
        'total_awards_received': 0,
        'created_utc': createdUtc,
        'permalink': permalink,
        'post_hint': _atomPostHint(categoryTerm),
      },
    };
  }

  Map<String, dynamic> _rssItemToChild(XmlElement item) {
    final id = _rssText(item, 'guid') ?? '';
    final shortId = id.replaceFirst(RegExp(r'^t3_'), '');
    final title = _rssText(item, 'title') ?? '';
    final authorText = _rssText(item, 'author') ?? _dcCreator(item) ?? '';
    final pubDate = _rssText(item, 'pubDate') ?? '';
    final link = _rssText(item, 'link') ?? '';
    final description = _rssText(item, 'description') ?? '';

    final createdUtc = _parseRssDate(pubDate);
    final permalink = _extractPermalink(link, shortId);

    return {
      'kind': 't3',
      'data': {
        'id': shortId,
        'title': title,
        'author': authorText,
        'subreddit': _extractSubreddit(link),
        'subreddit_id': '',
        'selftext': _stripHtml(description),
        'url': link,
        'thumbnail': 'self',
        'score': 0,
        'num_comments': 0,
        'likes': null,
        'over_18': false,
        'spoiler': false,
        'saved': false,
        'stickied': false,
        'locked': false,
        'total_awards_received': 0,
        'created_utc': createdUtc,
        'permalink': permalink,
      },
    };
  }

  String? _extractAtomAfter(XmlElement feed) {
    for (final link in feed.findElements('link')) {
      final rel = link.getAttribute('rel');
      if (rel == 'next') {
        final href = link.getAttribute('href');
        if (href != null && href.contains('after=')) {
          final uri = Uri.tryParse(href);
          if (uri != null) {
            return uri.queryParameters['after'];
          }
        }
      }
    }
    return null;
  }

  String? _atomText(XmlElement parent, String tag) {
    final element = parent.findElements(tag).firstOrNull;
    return element?.innerText;
  }

  String? _atomAuthor(XmlElement entry) {
    final author = entry.findElements('author').firstOrNull;
    if (author == null) return '[deleted]';
    return _atomText(author, 'name') ?? '[deleted]';
  }

  String? _atomLink(XmlElement entry) {
    for (final link in entry.findElements('link')) {
      final rel = link.getAttribute('rel') ?? 'alternate';
      if (rel == 'alternate') {
        return link.getAttribute('href');
      }
    }
    final first = entry.findElements('link').firstOrNull;
    return first?.getAttribute('href');
  }

  String? _atomCategoryTerm(XmlElement entry) {
    final category = entry.findElements('category').firstOrNull;
    return category?.getAttribute('term');
  }

  String? _rssText(XmlElement parent, String tag) {
    final element = parent.findElements(tag).firstOrNull;
    return element?.innerText;
  }

  String? _dcCreator(XmlElement item) {
    for (final elem in item.children) {
      if (elem is XmlElement &&
          elem.name.local == 'creator' &&
          elem.name.namespaceUri?.contains('purl.org/dc') == true) {
        return elem.innerText;
      }
    }
    return null;
  }

  int _parseAtomDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return dt.millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return 0;
    }
  }

  int _parseRssDate(String date) {
    try {
      final dt = DateTime.tryParse(date);
      if (dt != null) return dt.millisecondsSinceEpoch ~/ 1000;
      return _parseHttpDate(date);
    } catch (_) {
      return 0;
    }
  }

  int _parseHttpDate(String date) {
    try {
      final months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };
      final parts = date.replaceAll(',', '').split(' ');
      int day = 1, month = 1, year = 1970, hour = 0, min = 0, sec = 0;
      for (int i = 0; i < parts.length; i++) {
        final p = parts[i];
        if (months.containsKey(p) && i + 1 < parts.length) {
          month = months[p]!;
          day = int.tryParse(parts[i - 1]) ?? day;
          year = int.tryParse(parts[i + 1]) ?? year;
        } else if (p.contains(':')) {
          final timeParts = p.split(':');
          if (timeParts.length >= 2) {
            hour = int.tryParse(timeParts[0]) ?? 0;
            min = int.tryParse(timeParts[1]) ?? 0;
            if (timeParts.length >= 3) sec = int.tryParse(timeParts[2]) ?? 0;
          }
        }
      }
      final dt = DateTime.utc(year, month, day, hour, min, sec);
      return dt.millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return 0;
    }
  }

  String? _extractPermalink(String? link, String shortId) {
    if (link == null) return '/r/unknown/comments/$shortId';
    final uri = Uri.tryParse(link);
    if (uri != null) {
      return '${uri.path}${uri.path.endsWith('/') ? '' : '/'}';
    }
    return '/r/unknown/comments/$shortId';
  }

  String _extractSubreddit(String? link) {
    if (link == null) return 'unknown';
    final uri = Uri.tryParse(link);
    if (uri == null) return 'unknown';
    final parts = uri.pathSegments;
    if (parts.length >= 2 && parts[0] == 'r') return parts[1];
    return 'unknown';
  }

  String _stripContentTags(String content) {
    return content
        .replaceAll('<!-- SC_OFF -->', '')
        .replaceAll('<!-- SC_ON -->', '')
        .trim();
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String? _atomPostHint(String? categoryTerm) {
    if (categoryTerm == null) return null;
    if (categoryTerm == 'link') return 'link';
    if (categoryTerm == 'image') return 'image';
    if (categoryTerm == 'video') return 'hosted:video';
    return null;
  }

  Map<String, dynamic> _emptyListing() {
    return {
      'data': {
        'children': <dynamic>[],
        'after': null,
        'before': null,
      },
    };
  }
}
