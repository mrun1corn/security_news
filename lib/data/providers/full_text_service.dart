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
        return FullArticleData(
          content: _extractMainContent(document),
          imageUrl: _extractOgImage(document),
        );
      }
    } catch (e) {
      // Logic for logging can be added here if needed
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
