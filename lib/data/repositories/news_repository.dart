import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/models/news_source.dart';
import 'package:security_news/data/providers/rss_service.dart';
import 'package:security_news/data/providers/full_text_service.dart';

abstract class NewsRepository {
  Stream<List<Article>> streamNewsByCategory(NewsCategory category);
  Future<List<Article>> getCachedNews(NewsCategory category);
  Future<FullArticleData?> fetchFullArticle(String url);
  Future<void> toggleBookmark(Article article);
  Future<bool> isBookmarked(String url);
}

class NewsRepositoryImpl implements NewsRepository {
  final RssService _rssService;
  final FullTextService _fullTextService;
  final List<NewsSource> _sources;
  static const String _cacheKeyPrefix = 'news_cache_';
  static const String _bookmarksKey = 'bookmarked_urls';

  NewsRepositoryImpl({
    required RssService rssService,
    required FullTextService fullTextService,
    required List<NewsSource> sources,
  })  : _rssService = rssService,
        _fullTextService = fullTextService,
        _sources = sources;

  @override
  Future<FullArticleData?> fetchFullArticle(String url) async {
    return await _fullTextService.fetchFullArticle(url);
  }

  static const String _bookmarksListKey = 'bookmarked_articles_list';

  @override
  Future<void> toggleBookmark(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList(_bookmarksListKey) ?? [];
    final List<Article> bookmarks = bookmarksJson.map((j) => _articleFromJson(json.decode(j))).toList();
    
    final index = bookmarks.indexWhere((a) => a.url == article.url);
    if (index != -1) {
      bookmarks.removeAt(index);
    } else {
      bookmarks.insert(0, article.copyWith(isBookmarked: true));
    }
    
    await prefs.setStringList(_bookmarksListKey, bookmarks.map((a) => json.encode(_articleToJson(a))).toList());
    
    // Also update the legacy URL-only list for fast lookups if needed, 
    // but the list above is more authoritative now.
    final bookmarkUrls = bookmarks.map((a) => a.url).toList();
    await prefs.setStringList(_bookmarksKey, bookmarkUrls);
  }

  @override
  Future<bool> isBookmarked(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];
    return bookmarks.contains(url);
  }

  @override
  Stream<List<Article>> streamNewsByCategory(NewsCategory category) {
    final controller = StreamController<List<Article>>();

    _fetchAndStream(category, controller);

    return controller.stream;
  }

  Future<void> _fetchAndStream(NewsCategory category, StreamController<List<Article>> controller) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (category == NewsCategory.bookmarks) {
        final bookmarksJson = prefs.getStringList(_bookmarksListKey) ?? [];
        final bookmarks = bookmarksJson.map((j) => _articleFromJson(json.decode(j))).toList();
        controller.add(bookmarks);
        controller.close();
        return;
      }

      // 1. Emit Cache Immediately
      final cached = await getCachedNews(category);
      if (cached.isNotEmpty) {
        controller.add(cached);
      }

      final categorySources = _sources.where((s) => s.category == category).toList();
      final List<Article> allArticles = List.from(cached);
      final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

      // 2. Start all fetches concurrently
      // Using Future.wait to wrap the map ensures we can do a final save at the end
      await Future.wait(categorySources.map((source) async {
        try {
          final newArticles = await _rssService.fetchArticles(
            source.url,
            source.name,
            sourceIconUrl: source.iconUrl,
            category: source.category,
          );
          if (newArticles.isNotEmpty) {
            // Remove old articles from this source to avoid duplicates
            allArticles.removeWhere((a) => a.sourceName == source.name);
            
            // Map with bookmark status
            final mappedArticles = newArticles.map((a) => a.copyWith(
              isBookmarked: bookmarks.contains(a.url),
            )).toList();

            allArticles.addAll(mappedArticles);
            
            // Sort by date (newest first)
            allArticles.sort((a, b) {
              if (a.publishedDate == null && b.publishedDate == null) return 0;
              if (a.publishedDate == null) return 1;
              if (b.publishedDate == null) return -1;
              return b.publishedDate!.compareTo(a.publishedDate!);
            });

            // Emit updated list progressively for perceived speed
            if (!controller.isClosed) {
              controller.add(List.from(allArticles));
            }
          }
        } catch (e) {
          debugPrint('Error fetching from ${source.name}: $e');
        }
      }));

      // 3. Save to cache only once after all sources are processed
      if (allArticles.isNotEmpty) {
        _saveToCache(category, allArticles);
      }

      if (!controller.isClosed) {
        controller.close();
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
    }
  }

  @override
  Future<List<Article>> getCachedNews(NewsCategory category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('$_cacheKeyPrefix${category.name}');
      final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];
      
      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.map((item) {
          final article = _articleFromJson(item);
          return article.copyWith(isBookmarked: bookmarks.contains(article.url));
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading cache: $e');
    }
    return [];
  }

  Future<void> _saveToCache(NewsCategory category, List<Article> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(articles.map((a) => _articleToJson(a)).toList());
      await prefs.setString('$_cacheKeyPrefix${category.name}', jsonString);
    } catch (e) {
      debugPrint('Error saving cache: $e');
    }
  }

  Map<String, dynamic> _articleToJson(Article article) {
    return {
      'title': article.title,
      'description': article.description,
      'content': article.content,
      'url': article.url,
      'sourceName': article.sourceName,
      'sourceIconUrl': article.sourceIconUrl,
      'category': article.category?.name,
      'publishedDate': article.publishedDate?.toIso8601String(),
      'imageUrl': article.imageUrl,
    };
  }

  Article _articleFromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      description: json['description'],
      content: json['content'],
      url: json['url'],
      sourceName: json['sourceName'],
      sourceIconUrl: json['sourceIconUrl'],
      category: json['category'] != null
          ? NewsCategory.values.firstWhere((e) => e.name == json['category'])
          : null,
      publishedDate: json['publishedDate'] != null ? DateTime.parse(json['publishedDate']) : null,
      imageUrl: json['imageUrl'],
    );
  }
}
