import 'package:equatable/equatable.dart';
import 'package:security_news/data/models/article.dart';
import 'package:security_news/data/models/news_source.dart';

abstract class NewsEvent extends Equatable {
  const NewsEvent();

  @override
  List<Object> get props => [];
}

class FetchNews extends NewsEvent {
  final NewsCategory category;

  const FetchNews(this.category);

  @override
  List<Object> get props => [category];
}

class ToggleBookmark extends NewsEvent {
  final Article article;

  const ToggleBookmark(this.article);

  @override
  List<Object> get props => [article];
}

class SearchNews extends NewsEvent {
  final String query;

  const SearchNews(this.query);

  @override
  List<Object> get props => [query];
}

abstract class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object> get props => [];
}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<Article> articles; // This will be the filtered list
  final List<Article> allArticles; // This keeps the full list for searching
  final NewsCategory category;
  final String searchQuery;

  const NewsLoaded({
    required this.articles,
    required this.allArticles,
    required this.category,
    this.searchQuery = '',
  });

  @override
  List<Object> get props => [articles, allArticles, category, searchQuery];
}

class NewsError extends NewsState {
  final String message;
  final NewsCategory category;

  const NewsError(this.message, this.category);

  @override
  List<Object> get props => [message, category];
}
