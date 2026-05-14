import 'package:dart_rss/dart_rss.dart';
import 'package:flutter/foundation.dart';
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/models/news_source.dart';

extension RssItemMapper on RssItem {
  Article toArticle(String sourceName, {String? sourceIconUrl, NewsCategory? category}) {
    return Article(
      title: title ?? 'No Title',
      description: _stripHtml(description ?? ''),
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
      // Try standard ISO 8601 first
      final parsed = DateTime.tryParse(dateString);
      if (parsed != null) return parsed;

      // Manually handle common RSS format: "Wed, 13 May 2026 13:38:54 +0530"
      // Most RSS parsers recommend using HttpDate from dart:io, but it's not available on web
      // Simple fallback: remove the day name and try again
      final cleanDate = dateString.contains(',') 
          ? dateString.split(',')[1].trim() 
          : dateString;
      
      // Handle "+0530" or "GMT"
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
    // Support both raw <img src="..."> and encoded &lt;img src=&quot;...&quot;&gt;
    final match = RegExp(r'(?:<img|&lt;img)[^>]+src=(?:"|&quot;)([^">]+)(?:"|&quot;)', caseSensitive: false)
        .firstMatch(htmlContent);
    
    if (match != null) {
      String url = match.group(1)!;
      // Decode if it was &amp; encoded
      url = url.replaceAll('&amp;', '&');
      return _proxyIfWeb(url);
    }
    return null;
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
      description: _stripHtml(summary ?? ''),
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
    final match = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(htmlContent);
    if (match != null) {
      return _proxyIfWeb(match.group(1)!);
    }
    return null;
  }

  String _proxyIfWeb(String url) {
    if (kIsWeb && !url.startsWith('data:')) {
      return 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
    }
    return url;
  }
}

String _stripHtml(String htmlString) {
  // 1. Remove scripts, styles
  String result = htmlString.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>'), '');
  result = result.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>'), '');
  
  // 2. Remove common WordPress boilerplate at the end of many feeds (Sophos, Krebs, etc.)
  // e.g., "The post [Title] appeared first on [Source]."
  result = result.replaceAll(RegExp(r'The post.*?appeared first on.*?(\.|$)', caseSensitive: false), '');
  
  // 3. Remove "Read more", "Continue reading", "[...]" markers
  result = result.replaceAll(RegExp(r'(?:Read more|Continue reading|View Article).*?(\.|$)', caseSensitive: false), '');

  // 4. Remove all other tags and decode common entities
  result = result.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  
  // 5. Normalize whitespace
  result = result.trim().replaceAll(RegExp(r'\s+'), ' ');

  // 6. Remove common RSS truncation markers
  result = result.replaceAll(RegExp(r'\s?\[\.\.\.\]$'), '');
  result = result.replaceAll(RegExp(r'\s?\.\.\.$'), '');
  result = result.replaceAll(RegExp(r'\s?\[\u2026\]$'), ''); // Unicode ellipsis

  return result.trim();
}
