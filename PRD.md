# Spec: CyberSecurity & Tech News App (CyberWatch)

## Objective
Build a multi-platform (Web & Mobile) news aggregator that provides real-time updates on cybersecurity, new technologies, antivirus signatures, and threat intelligence. The app will fetch data from various RSS feeds and APIs, providing a unified dashboard for security professionals and tech enthusiasts.

## Tech Stack
- **Framework:** Flutter (Web & Mobile)
- **Language:** Dart
- **State Management:** Flutter BLoC (or Provider, based on simplicity)
- **Networking:** `dio` or `http`
- **RSS Parsing:** `dart_rss` or `xml`
- **Storage (Local):** `shared_preferences` or `hive` (for offline reading/bookmarks)
- **Backend (Optional/Future):** Firebase for push notifications and sync.

## Commands
- **Run Web:** `flutter run -d chrome`
- **Run Mobile (Android):** `flutter run -d android`
- **Build Web:** `flutter build web`
- **Build Android:** `flutter build apk`
- **Test:** `flutter test`
- **Lint:** `flutter analyze`

## Project Structure
```
lib/
  core/           → Utilities, constants, theme
  data/
    models/       → Article, NewsSource models
    repositories/ → NewsRepository (abstract + impl)
    providers/    → API/RSS fetchers
  logic/
    blocs/        → NewsBloc (fetching, filtering)
  presentation/
    screens/      → Home, ArticleDetail, Settings
    widgets/      → NewsCard, CategoryFilter
  main.dart       → Entry point
```

## Code Style
- Follow Official Flutter/Dart lint rules (`flutter_lints`).
- Use `PascalCase` for classes, `camelCase` for variables/methods.
- Example:
```dart
class NewsCard extends StatelessWidget {
  final Article article;
  const NewsCard({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(article.title),
      subtitle: Text(article.source),
    );
  }
}
```

## Testing Strategy
- **Unit Tests:** For repository logic and RSS parsing.
- **Widget Tests:** For core UI components (NewsCard, CategoryFilter).
- **Integration Tests:** (Optional) for full-flow verification.

## Boundaries
- **Always do:** Handle network errors gracefully, show loading states, cache articles for offline use.
- **Ask first:** Adding heavy dependencies (like Firebase), complex animations.
- **Never do:** Store sensitive API keys in public repos (use `.env`), block the UI thread with heavy parsing.

## Success Criteria
- [ ] App runs on Chrome and Android Emulator.
- [ ] Fetches and displays articles from at least 3 cybersecurity RSS feeds.
- [ ] Users can filter news by category (Cybersecurity, Tech, AV).
- [ ] Articles open in an in-app browser or deep link.
- [ ] Basic offline support (showing last fetched news).

## Open Questions
- Do we need a custom backend for scraping, or is client-side RSS parsing sufficient?
- Should we include a "Dark Mode" as a primary feature (highly requested by security folks)?
- Which Tech News API should we prioritize (NewsAPI.org requires an API key)?
