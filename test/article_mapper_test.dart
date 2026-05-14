import 'package:dart_rss/dart_rss.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_news/data/models/article_mapper.dart';

void main() {
  group('ArticleMapper', () {
    test('should map RssItem to Article correctly', () {
      const xml = '''
      <rss version="2.0">
        <channel>
          <item>
            <title>Security Breach Alert</title>
            <link>https://example.com/breach</link>
            <description>A major breach occurred.</description>
            <pubDate>Wed, 13 May 2026 10:00:00 GMT</pubDate>
          </item>
        </channel>
      </rss>
      ''';

      final feed = RssFeed.parse(xml);
      final item = feed.items.first;
      final article = item.toArticle('Test Source');

      expect(article.title, 'Security Breach Alert');
      expect(article.url, 'https://example.com/breach');
      expect(article.sourceName, 'Test Source');
      expect(article.description, contains('A major breach occurred.'));
    });
  });
}
