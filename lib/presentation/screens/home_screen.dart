import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:security_news/data/models/news_source.dart';
import 'package:security_news/logic/blocs/news_bloc.dart';
import 'package:security_news/logic/blocs/news_bloc_state.dart';
import 'package:security_news/presentation/widgets/news_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search news...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (value) {
                  context.read<NewsBloc>().add(SearchNews(value));
                },
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CYBERWATCH',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<NewsBloc>().add(const SearchNews(''));
                }
              });
            },
          ),
          BlocBuilder<NewsBloc, NewsState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final category = (state is NewsLoaded)
                      ? state.category
                      : NewsCategory.cybersecurity;
                  context.read<NewsBloc>().add(FetchNews(category));
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilters(context),
          Expanded(
            child: BlocBuilder<NewsBloc, NewsState>(
              builder: (context, state) {
                if (state is NewsLoading) {
                  return _buildShimmerLoading();
                } else if (state is NewsLoaded) {
                  final articles = state.articles;
                  
                  if (articles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            state.searchQuery.isNotEmpty 
                                ? 'No results for "${state.searchQuery}"'
                                : 'No news found.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (state.searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                context.read<NewsBloc>().add(const SearchNews(''));
                              },
                              child: const Text('Clear Search'),
                            ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<NewsBloc>().add(FetchNews(state.category));
                    },
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: ListView.builder(
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            return NewsCard(article: articles[index]);
                          },
                        ),
                      ),
                    ),
                  );
                } else if (state is NewsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<NewsBloc>().add(FetchNews(state.category));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Select a category to start.'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: NewsCategory.values.map((category) {
          final isSelected = context.watch<NewsBloc>().state is NewsLoaded &&
              (context.watch<NewsBloc>().state as NewsLoaded).category == category;
          
          final isBookmarks = category == NewsCategory.bookmarks;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: isBookmarks 
                  ? Icon(Icons.bookmark, size: 16, color: isSelected ? Colors.cyanAccent : Colors.white54)
                  : null,
              label: Text(_capitalize(category.name)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  context.read<NewsBloc>().add(FetchNews(category));
                }
              },
              backgroundColor: const Color(0xFF1E1E1E),
              selectedColor: isBookmarks 
                  ? Colors.amberAccent.withAlpha(40)
                  : Colors.cyanAccent.withAlpha(40),
              labelStyle: TextStyle(
                color: isSelected 
                    ? (isBookmarks ? Colors.amberAccent : Colors.cyanAccent) 
                    : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected 
                    ? (isBookmarks ? Colors.amberAccent : Colors.cyanAccent) 
                    : Colors.white12,
                width: 1,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          itemCount: 6,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: const Color(0xFF1E1E1E),
              highlightColor: const Color(0xFF2C2C2C),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 100, height: 12, color: Colors.white),
                      const SizedBox(height: 14),
                      Container(width: double.infinity, height: 200, color: Colors.white),
                      const SizedBox(height: 14),
                      Container(width: double.infinity, height: 20, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 200, height: 20, color: Colors.white),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
