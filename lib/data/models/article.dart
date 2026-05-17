import 'package:equatable/equatable.dart';
import 'package:security_news/data/models/news_source.dart';

class Article extends Equatable {
  final String title;
  final String description; // Raw HTML or plain text
  final String content;
  final String url;
  final String sourceName;
  final String? sourceIconUrl;
  final NewsCategory? category;
  final DateTime? publishedDate;
  final String? imageUrl;
  final bool isBookmarked;

  const Article({
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    required this.sourceName,
    this.sourceIconUrl,
    this.category,
    this.publishedDate,
    this.imageUrl,
    this.isBookmarked = false,
  });

  // Getter to provide a plain text snippet for UI previews
  String get snippet {
    // Basic tag stripping if description contains HTML
    final stripped = description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    return stripped.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Centralized reading time logic
  int get readingTime => calculateReadingTime(content.isNotEmpty ? content : description);

  static int calculateReadingTime(String text) {
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');
    final words = cleanText.split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return minutes > 0 ? minutes : 1;
  }

  Article copyWith({
    String? title,
    String? description,
    String? content,
    String? url,
    String? sourceName,
    String? sourceIconUrl,
    NewsCategory? category,
    DateTime? publishedDate,
    String? imageUrl,
    bool? isBookmarked,
  }) {
    return Article(
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      url: url ?? this.url,
      sourceName: sourceName ?? this.sourceName,
      sourceIconUrl: sourceIconUrl ?? this.sourceIconUrl,
      category: category ?? this.category,
      publishedDate: publishedDate ?? this.publishedDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        content,
        url,
        sourceName,
        sourceIconUrl,
        category,
        publishedDate,
        imageUrl,
        isBookmarked,
      ];
}
