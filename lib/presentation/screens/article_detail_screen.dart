import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/repositories/news_repository.dart';
import 'package:security_news/logic/blocs/news_bloc.dart';
import 'package:security_news/logic/blocs/news_bloc_state.dart';
import 'package:share_plus/share_plus.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  String? _fullContent;
  bool _isLoadingFullArticle = false;
  String? _errorMessage;

  Future<void> _loadFullArticle() async {
    setState(() {
      _isLoadingFullArticle = true;
      _errorMessage = null;
    });

    try {
      final repository = context.read<NewsRepository>();
      final content = await repository.fetchFullArticle(widget.article.url);
      
      if (mounted) {
        setState(() {
          _fullContent = content;
          _isLoadingFullArticle = false;
          if (content == null) {
            _errorMessage = "Could not extract full article content.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFullArticle = false;
          _errorMessage = "Error loading full article: $e";
        });
      }
    }
  }

  int _calculateReadingTime(String text) {
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');
    final words = cleanText.split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return minutes > 0 ? minutes : 1;
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: article.imageUrl != null
                  ? Hero(
                      tag: 'article_image_${article.url}',
                      child: Image.network(
                        article.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(color: const Color(0xFF1F1F1F)),
            ),
            actions: [
              BlocBuilder<NewsBloc, NewsState>(
                builder: (context, state) {
                  final isBookmarked = (state is NewsLoaded)
                      ? state.articles.firstWhere((a) => a.url == article.url, orElse: () => article).isBookmarked
                      : article.isBookmarked;
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.cyanAccent : null,
                    ),
                    onPressed: () {
                      context.read<NewsBloc>().add(ToggleBookmark(article));
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share('${article.title}\n\nRead more at: ${article.url}');
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (article.sourceIconUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Image.network(
                              article.sourceIconUrl!,
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.article,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.sourceName.toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (article.publishedDate != null)
                              Text(
                                timeago.format(article.publishedDate!),
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        '${_calculateReadingTime(_fullContent ?? article.content + article.description)} min read',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 4,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 32),
                  HtmlWidget(
                    _fullContent ?? (article.content.isNotEmpty ? article.content : article.description),
                    textStyle: TextStyle(
                      fontSize: 19,
                      height: 1.7,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w400,
                    ),
                    customStylesBuilder: (element) {
                      if (element.localName == 'a') {
                        return {
                          'color': '#00E5FF',
                          'text-decoration': 'none',
                          'font-weight': 'bold'
                        };
                      }
                      if (element.localName == 'p') {
                        return {'margin-bottom': '24px'};
                      }
                      if (element.localName == 'li') {
                        return {'margin-bottom': '12px'};
                      }
                      if (element.localName == 'img') {
                        return {'max-width': '100%', 'height': 'auto', 'border-radius': '8px'};
                      }
                      return null;
                    },
                  ),
                  if (_fullContent == null && !_isLoadingFullArticle)
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                              ),
                            ElevatedButton.icon(
                              onPressed: _loadFullArticle,
                              icon: const Icon(Icons.auto_stories),
                              label: const Text('GET FULL ARTICLE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(40),
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_isLoadingFullArticle)
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Extracting full article...', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
