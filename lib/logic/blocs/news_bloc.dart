import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/repositories/news_repository.dart';
import 'news_bloc_state.dart';

const _debounceDuration = Duration(milliseconds: 300);

EventTransformer<Event> debounce<Event>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsRepository _newsRepository;

  NewsBloc({required NewsRepository newsRepository})
      : _newsRepository = newsRepository,
        super(NewsInitial()) {
    on<FetchNews>(_onFetchNews);
    on<ToggleBookmark>(_onToggleBookmark);
    on<SearchNews>(_onSearchNews, transformer: debounce(_debounceDuration));
  }

  Future<void> _onFetchNews(FetchNews event, Emitter<NewsState> emit) async {
    emit(NewsLoading());
    try {
      await emit.forEach(
        _newsRepository.streamNewsByCategory(event.category),
        onData: (List<Article> articles) {
          return NewsLoaded(
            articles: articles,
            allArticles: articles,
            category: event.category,
          );
        },
        onError: (error, stackTrace) {
          return NewsError('Failed to fetch news: $error', event.category);
        },
      );
    } catch (e) {
      emit(NewsError('Failed to fetch news: $e', event.category));
    }
  }

  void _onSearchNews(SearchNews event, Emitter<NewsState> emit) {
    final currentState = state;
    if (currentState is NewsLoaded) {
      if (event.query.isEmpty) {
        emit(NewsLoaded(
          articles: currentState.allArticles,
          allArticles: currentState.allArticles,
          category: currentState.category,
          searchQuery: '',
        ));
        return;
      }

      final query = event.query.toLowerCase();
      final filtered = currentState.allArticles.where((a) {
        return a.title.toLowerCase().contains(query) ||
            a.description.toLowerCase().contains(query) ||
            a.sourceName.toLowerCase().contains(query);
      }).toList();

      emit(NewsLoaded(
        articles: filtered,
        allArticles: currentState.allArticles,
        category: currentState.category,
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onToggleBookmark(ToggleBookmark event, Emitter<NewsState> emit) async {
    final currentState = state;
    if (currentState is NewsLoaded) {
      final updatedArticle = event.article.copyWith(isBookmarked: !event.article.isBookmarked);
      
      // Update repository
      await _newsRepository.toggleBookmark(event.article);

      // Update local state for immediate feedback
      final updatedAllArticles = currentState.allArticles.map((a) {
        return a.url == event.article.url ? updatedArticle : a;
      }).toList();

      final updatedFilteredArticles = currentState.articles.map((a) {
        return a.url == event.article.url ? updatedArticle : a;
      }).toList();

      emit(NewsLoaded(
        articles: updatedFilteredArticles,
        allArticles: updatedAllArticles,
        category: currentState.category,
        searchQuery: currentState.searchQuery,
      ));
    }
  }
}
