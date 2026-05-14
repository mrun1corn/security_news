import 'package:dart_rss/dart_rss.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/models/article_mapper.dart';
import 'package:security_news/data/models/news_source.dart';

class RssService {
  final Dio _dio;

  RssService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
  }

  Future<List<Article>> fetchArticles(
    String url,
    String sourceName, {
    String? sourceIconUrl,
    NewsCategory? category,
  }) async {
    try {
      String effectiveUrl = url;
      if (kIsWeb) {
        effectiveUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      }

      final response = await _dio.get(effectiveUrl);
      if (response.statusCode == 200) {
        final data = response.data.toString();

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
      } else {
        throw Exception('Failed to load feed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching feed: $e');
    }
  }
}
