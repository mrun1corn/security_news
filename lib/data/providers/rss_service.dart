import 'package:dart_rss/dart_rss.dart';
import 'package:dio/dio.dart';
import 'package:security_news/core/network_utils.dart';
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/models/article_mapper.dart';
import 'package:security_news/data/models/news_source.dart';

class RssService {
  RssService({Dio? dio});

  Future<List<Article>> fetchArticles(
    String url,
    String sourceName, {
    String? sourceIconUrl,
    NewsCategory? category,
  }) async {
    try {
      final data = await NetworkUtils.fetchWithFallback(url);
      if (data == null) throw Exception('Failed to fetch feed data');

      if (data.contains('<rss') || data.contains('<channel')) {
        final feed = RssFeed.parse(data);
        return feed.items
            .map((item) => item.toArticle(
                  sourceName,
                  sourceIconUrl: sourceIconUrl,
                  category: category,
                ))
            .toList();
      } else if (data.contains('<feed')) {
        final feed = AtomFeed.parse(data);
        return feed.items
            .map((item) => item.toArticle(
                  sourceName,
                  sourceIconUrl: sourceIconUrl,
                  category: category,
                ))
            .toList();
      } else {
        throw Exception('Unknown feed format');
      }
    } catch (e) {
      throw Exception('Error fetching feed: $e');
    }
  }
}
