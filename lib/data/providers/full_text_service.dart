import 'package:flutter/foundation.dart';
import 'package:security_news/core/network_utils.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class FullArticleData {
  final String? content;
  final String? imageUrl;

  FullArticleData({this.content, this.imageUrl});
}

class FullTextService {
  Future<FullArticleData?> fetchFullArticle(String url) async {
    try {
      final responseData = await NetworkUtils.fetchWithFallback(url);
      if (responseData != null) {
        final document = html_parser.parse(responseData);
        String? content = _extractMainContent(document);
        
        // If content is very short or looks like a navigation menu/garbage, return null
        // so the UI can fall back to the original article.description
        if (content != null && content.length < 250) {
          content = null;
        }

        return FullArticleData(
          content: content,
          imageUrl: _extractOgImage(document),
        );
      }
    } catch (e) {
      debugPrint('Error fetching full article: $e');
    }
    return null;
  }

  String? _extractOgImage(dom.Document document) {
    final metaTags = [
      'meta[property="og:image"]',
      'meta[name="twitter:image"]',
      'meta[property="og:image:secure_url"]',
      'link[rel="image_src"]',
    ];

    for (var selector in metaTags) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'] ?? element.attributes['href'];
        if (content != null && content.isNotEmpty) return content;
      }
    }
    return null;
  }

  String? _extractMainContent(dom.Document document) {
    // 1. Try common specific content classes/ids FIRST
    final specificSelectors = [
      '.entry-content',
      '.post-content',
      '.article-body',
      '.article-content',
      '.td-post-content',
      '.story-content',
      '.article-text',
      '.article__body',
      '.post-text',
      '#article-body',
      '#article-content',
      'main',
    ];

    for (var selector in specificSelectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        // Pick the one with the most text to avoid tiny matches
        elements.sort((a, b) => b.text.length.compareTo(a.text.length));
        if (elements.first.text.length > 300) {
          return _cleanAndGetHtml(elements.first);
        }
      }
    }

    // 2. Try standard article tags
    final articleTags = document.querySelectorAll('article');
    if (articleTags.isNotEmpty) {
      articleTags.sort((a, b) => b.text.length.compareTo(a.text.length));
      if (articleTags.first.text.length > 300) {
        return _cleanAndGetHtml(articleTags.first);
      }
    }

    // 3. Advanced Heuristic: Find element with highest text density/length
    final bodies = document.querySelectorAll('body');
    if (bodies.isEmpty) return null;

    dom.Element? bestElement;
    double maxScore = 0;

    void traverse(dom.Element element) {
      final tag = element.localName;
      if (tag == 'nav' || tag == 'footer' || tag == 'header' || tag == 'aside' || 
          tag == 'script' || tag == 'style' || tag == 'noscript' || tag == 'form' ||
          tag == 'ul' || tag == 'ol' || tag == 'button') {
        return;
      }

      final className = (element.attributes['class'] ?? '').toLowerCase();
      final id = (element.attributes['id'] ?? '').toLowerCase();
      final noiseKeywords = ['nav', 'footer', 'header', 'sidebar', 'comment', 'share', 'related', 'ads', 'cookie', 'banner', 'breadcrumb', 'menu'];
      
      if (noiseKeywords.any((k) => className.contains(k) || id.contains(k))) {
        return;
      }

      // Simple Readability-like scoring
      // Paragraph count + text length / 100
      final pCount = element.querySelectorAll('p').length;
      final textLength = element.text.trim().length;
      
      if (textLength > 100) {
        // Favor elements with many paragraphs
        double score = (pCount * 25.0) + (textLength / 40.0);
        
        // Penalize very deep nesting or elements that are too wide (like body)
        if (tag == 'body' || tag == 'html') score = 0;

        if (score > maxScore) {
          maxScore = score;
          bestElement = element;
        }
      }

      for (var child in element.children) {
        traverse(child);
      }
    }

    traverse(bodies.first);

    if (bestElement != null && maxScore > 60) {
      return _cleanAndGetHtml(bestElement!);
    }

    return null;
  }

  String _cleanAndGetHtml(dom.Element element) {
    // Clone element to avoid modifying the original document during heuristic passes if needed
    // But since we use it once at the end, direct modification is fine for memory efficiency
    
    // Remove unwanted elements
    final noiseSelectors = [
      'nav', 'footer', 'header', 'aside', 'script', 'style', 'noscript', 'form',
      '.ads', '.advertisement', '.social-share', '.related-posts', '.comments', 
      '.newsletter-signup', 'iframe', 'button', '.author-bio', '.tags', '.breadcrumb',
      '.wp-caption-text', '.entry-meta', '.post-meta', '.cookie-consent', '.popup',
      '#comments', '.sidebar', '.widget'
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
    return result;
  }
}
