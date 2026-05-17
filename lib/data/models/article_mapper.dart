import 'package:dart_rss/dart_rss.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/models/news_source.dart';

extension RssItemMapper on RssItem {
  Article toArticle(String sourceName, {String? sourceIconUrl, NewsCategory? category}) {
    return Article(
      title: title ?? 'No Title',
      description: description ?? '',
      content: content?.value ?? '',
      url: link ?? '',
      sourceName: sourceName,
      sourceIconUrl: sourceIconUrl,
      category: category,
      publishedDate: pubDate != null ? _parseDate(pubDate!) : null,
      imageUrl: _extractImage(),
    );
  }

  DateTime? _parseDate(String dateString) {
    try {
      // 1. Try standard ISO 8601
      final parsed = DateTime.tryParse(dateString);
      if (parsed != null) return parsed;

      // 2. Try common RSS format (RFC 822/1123)
      // Example: "Wed, 13 May 2026 13:38:54 +0530" or "Sun, 17 May 2026 07:50:54 GMT"
      // DateFormat doesn't handle all variations perfectly, so we'll try a few patterns
      final patterns = [
        'EEE, dd MMM yyyy HH:mm:ss Z',
        'EEE, dd MMM yyyy HH:mm:ss zzz',
        'dd MMM yyyy HH:mm:ss Z',
        'yyyy-MM-ddTHH:mm:ssZ',
        'yyyy-MM-dd HH:mm:ss',
      ];

      for (var pattern in patterns) {
        try {
          return DateFormat(pattern).parse(dateString);
        } catch (_) {}
      }

      // 3. Fallback for mixed formats like "Sat, 16 May 2026 20:50:48 +0530"
      // where +0530 might need manual cleaning or specific pattern
      final cleanDate = dateString.replaceAll(RegExp(r'\s+'), ' ').trim();
      return DateTime.tryParse(cleanDate);
    } catch (_) {
      return null;
    }
  }

  String? _extractImage() {
    // 1. Check enclosure
    if (enclosure != null && enclosure!.url != null) {
      return _proxyIfWeb(enclosure!.url!);
    }
    // 2. Check media:content
    if (media != null && media!.contents.isNotEmpty) {
      final url = media!.contents.first.url;
      if (url != null) return _proxyIfWeb(url);
    }
    // 3. Check media:thumbnail
    if (media != null && media!.thumbnails.isNotEmpty) {
      final url = media!.thumbnails.first.url;
      if (url != null) return _proxyIfWeb(url);
    }
    // 4. Try to extract from description or content (handle encoded and raw HTML)
    final htmlContent = (content?.value ?? '') + (description ?? '');
    return _extractImageFromHtml(htmlContent);
  }

  String _proxyIfWeb(String url) {
    if (kIsWeb && !url.startsWith('data:')) {
      return 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
    }
    return url;
  }
}

extension AtomItemMapper on AtomItem {
  Article toArticle(String sourceName, {String? sourceIconUrl, NewsCategory? category}) {
    return Article(
      title: title ?? 'No Title',
      description: summary ?? '',
      content: content ?? '',
      url: links.isNotEmpty ? links.first.href ?? '' : '',
      sourceName: sourceName,
      sourceIconUrl: sourceIconUrl,
      category: category,
      publishedDate: updated != null ? DateTime.tryParse(updated!) : (published != null ? DateTime.tryParse(published!) : null),
      imageUrl: _extractImage(),
    );
  }

  String? _extractImage() {
    // 1. Check media:content/thumbnail via standard extensions if available
    if (media != null) {
      if (media!.contents.isNotEmpty) {
        final url = media!.contents.first.url;
        if (url != null) return _proxyIfWeb(url);
      }
      if (media!.thumbnails.isNotEmpty) {
        final url = media!.thumbnails.first.url;
        if (url != null) return _proxyIfWeb(url);
      }
    }
    // 2. Check links for enclosures
    try {
      final imageLink = links.firstWhere(
        (link) => link.rel == 'enclosure' && (link.type?.contains('image') ?? false),
      );
      return _proxyIfWeb(imageLink.href!);
    } catch (_) {}

    // 3. Try to extract from summary or content
    final htmlContent = (content ?? '') + (summary ?? '');
    return _extractImageFromHtml(htmlContent);
  }

  String _proxyIfWeb(String url) {
    if (kIsWeb && !url.startsWith('data:')) {
      return 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
    }
    return url;
  }
}

String? _extractImageFromHtml(String htmlContent) {
  if (htmlContent.isEmpty) return null;

  // Improved regex to handle various quote styles and encoded HTML
  // Focuses on extracting the first URL that looks like an image source
  final match = RegExp(
    r'<img[^>]+src=["' "'" r']([^"' "'" r'>\s]+)',
    caseSensitive: false,
  ).firstMatch(htmlContent) ??
  RegExp(
    r'&lt;img[^&]+src=["' "'" r']([^"' "'" r'&>\s]+)',
    caseSensitive: false,
  ).firstMatch(htmlContent);

  if (match != null) {
    String url = match.group(1)!;
    // Basic cleanup of encoded entities if present
    url = url.replaceAll('&amp;', '&');
    return url;
  }
  return null;
}
