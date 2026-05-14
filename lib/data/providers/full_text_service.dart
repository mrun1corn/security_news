import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class FullTextService {
  final Dio _dio;

  FullTextService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> fetchFullArticle(String url) async {
    try {
      String effectiveUrl = url;
      if (kIsWeb) {
        effectiveUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      }

      final response = await _dio.get(effectiveUrl);
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.data.toString());
        return _extractMainContent(document);
      }
    } catch (e) {
      debugPrint('Error fetching full article: $e');
    }
    return null;
  }

  String? _extractMainContent(dom.Document document) {
    // 1. Try common specific content classes/ids FIRST (more precise than <article>)
    final specificSelectors = [
      '.entry-content',
      '.post-content',
      '.article-body',
      '.article-content',
      '#article-content',
      '.td-post-content',
      '.story-content',
      '.article-text',
      '.article__body',
    ];

    for (var selector in specificSelectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        return _cleanAndGetHtml(elements.first);
      }
    }

    // 2. Try standard article tags
    final articleTags = document.querySelectorAll('article');
    if (articleTags.isNotEmpty) {
      return _cleanAndGetHtml(articleTags.first);
    }

    // 3. Heuristic: Find element with most paragraphs
    final bodies = document.querySelectorAll('body');
    if (bodies.isEmpty) return null;

    dom.Element? bestElement;
    int maxParagraphs = 0;

    void traverse(dom.Element element) {
      // Ignore known noise containers
      final tag = element.localName;
      if (tag == 'nav' || tag == 'footer' || tag == 'header' || tag == 'aside' || 
          tag == 'script' || tag == 'style' || tag == 'noscript' || tag == 'form') {
        return;
      }

      // Check classes/ids for noise keywords
      final className = (element.attributes['class'] ?? '').toLowerCase();
      final id = (element.attributes['id'] ?? '').toLowerCase();
      final noiseKeywords = ['nav', 'footer', 'header', 'sidebar', 'comment', 'share', 'related', 'ads', 'cookie', 'banner', 'breadcrumb'];
      
      if (noiseKeywords.any((k) => className.contains(k) || id.contains(k))) {
        return;
      }

      final pCount = element.querySelectorAll('p').length;
      if (pCount > maxParagraphs) {
        maxParagraphs = pCount;
        bestElement = element;
      }

      for (var child in element.children) {
        traverse(child);
      }
    }

    traverse(bodies.first);

    if (bestElement != null && maxParagraphs > 1) {
      return _cleanAndGetHtml(bestElement!);
    }

    return null;
  }

  String _cleanAndGetHtml(dom.Element element) {
    // Remove unwanted elements
    final noiseSelectors = [
      'nav', 'footer', 'header', 'aside', 'script', 'style', 'noscript', 'form',
      '.ads', '.advertisement', '.social-share', '.related-posts', '.comments', 
      '.newsletter-signup', 'iframe', 'button', '.author-bio', '.tags', '.breadcrumb',
      '.wp-caption-text', '.entry-meta', '.post-meta', '.cookie-consent', '.popup'
    ];

    for (var selector in noiseSelectors) {
      element.querySelectorAll(selector).forEach((el) => el.remove());
    }

    // Fix lazy loaded images
    element.querySelectorAll('img').forEach((img) {
      final dataSrc = img.attributes['data-src'] ?? img.attributes['data-original'] ?? img.attributes['lazy-src'];
      if (dataSrc != null && (img.attributes['src'] == null || img.attributes['src']!.contains('placeholder'))) {
        img.attributes['src'] = dataSrc;
      }
    });

    // Final check: if the result is too short, we might have over-cleaned
    final result = element.innerHtml.trim();
    return result.length > 100 ? result : element.innerHtml;
  }
}
