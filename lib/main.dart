import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:security_news/core/constants.dart';
import 'package:security_news/data/models/news_source.dart';
import 'package:security_news/data/providers/full_text_service.dart';
import 'package:security_news/data/providers/rss_service.dart';
import 'package:security_news/data/repositories/news_repository.dart';
import 'package:security_news/logic/blocs/news_bloc.dart';
import 'package:security_news/logic/blocs/news_bloc_state.dart';
import 'package:security_news/presentation/screens/home_screen.dart';

void main() {
  runApp(const CyberWatchApp());
}

class CyberWatchApp extends StatelessWidget {
  const CyberWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<NewsRepository>(
      create: (context) => NewsRepositoryImpl(
        rssService: RssService(),
        fullTextService: FullTextService(),
        sources: AppConstants.defaultSources,
      ),
      child: BlocProvider<NewsBloc>(
        create: (context) => NewsBloc(
          newsRepository: context.read<NewsRepository>(),
        )..add(const FetchNews(NewsCategory.cybersecurity)),
        child: MaterialApp(
          title: 'CyberWatch',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            textTheme: GoogleFonts.exo2TextTheme(ThemeData.dark().textTheme),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF151515),
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.cyan,
              brightness: Brightness.dark,
              primary: Colors.cyanAccent,
              surface: const Color(0xFF151515),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              selectedColor: Colors.cyanAccent.withAlpha(40),
              labelStyle: const TextStyle(color: Colors.white70),
              secondaryLabelStyle: const TextStyle(color: Colors.cyanAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
