import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/repositories/news_repository.dart';
import 'news_bloc_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsRepository _newsRepository;

  NewsBloc({required NewsRepository newsRepository})
      : _newsRepository = newsRepository,
        super(NewsInitial()) {
    on<FetchNews>(_onFetchNews);
    on<ToggleBookmark>(_onToggleBookmark);
  }

  Future<void> _onFetchNews(FetchNews event, Emitter<NewsState> emit) async {
    emit(NewsLoading());
    try {
      await emit.forEach(
        _newsRepository.streamNewsByCategory(event.category),
        onData: (List<Article> articles) {
          return NewsLoaded(articles, event.category);
        },
        onError: (error, stackTrace) {
          return NewsError('Failed to fetch news: $error', event.category);
        },
      );
    } catch (e) {
      emit(NewsError('Failed to fetch news: $e', event.category));
    }
  }

  Future<void> _onToggleBookmark(ToggleBookmark event, Emitter<NewsState> emit) async {
    final currentState = state;
    if (currentState is NewsLoaded) {
      final updatedArticle = event.article.copyWith(isBookmarked: !event.article.isBookmarked);
      
      // Update repository
      await _newsRepository.toggleBookmark(event.article);

      // Update local state for immediate feedback
      final updatedArticles = currentState.articles.map((a) {
        return a.url == event.article.url ? updatedArticle : a;
      }).toList();

      emit(NewsLoaded(updatedArticles, currentState.category));
    }
  }
}
