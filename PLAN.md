# Implementation Plan: CyberWatch App

## Overview
A vertical-slice implementation of a Flutter news app for cybersecurity and tech. We will start with a single RSS source and expand to multiple categories.

## Architecture Decisions
- **BLoC Pattern:** For state management, ensuring a clean separation between data and UI.
- **Repository Pattern:** To abstract the source of news (RSS vs. API).
- **Client-Side Parsing:** Using `dart_rss` for parsing XML feeds directly in the app.

## Task List

### Phase 1: Foundation
- [x] **Task 1: Flutter Project Initialization**
  - Create the Flutter project, setup folders, and add dependencies (`dio`, `dart_rss`, `flutter_bloc`, `url_launcher`, `intl`).
  - Verify: `flutter run` works on Web/Chrome.
- [x] **Task 2: Data Models**
  - Create `Article` and `NewsSource` models with JSON serialization (if needed) and factory methods for RSS items.
  - Verify: Unit test for parsing a sample RSS item into an `Article`.

### Phase 2: Core News Flow
- [x] **Task 3: News Repository & RSS Service**
  - Implement `RssService` to fetch XML and `NewsRepository` to return a list of `Article` objects.
  - Verify: Repository test with mocked network response.
- [x] **Task 4: News BLoC**
  - Implement `NewsBloc` with `FetchNews` event and `NewsLoading`, `NewsLoaded`, `NewsError` states.
  - Verify: Bloc test showing state transitions.
- [x] **Task 5: Basic UI (Home Screen)**
  - Build a simple list view to display articles with titles and sources.
  - Verify: Articles from a live RSS feed (e.g., The Hacker News) show up on screen.

### Phase 3: Features & Categories
- [x] **Task 6: Category Filtering**
  - Add category chips to filter news by Cybersecurity, Tech, or AV.
  - Verify: Clicking a chip fetches news for that category.
- [x] **Task 7: Article Detail / WebView**
  - Use `url_launcher` to open articles in the default browser. (Note: Implemented as in-app detail view as requested).
  - Verify: Tapping a card opens the correct URL.

### Phase 4: Polish & Performance
- [x] **Task 8: Theming & Dark Mode**
  - Implement a sleek "Security" theme with dark mode by default.
  - Verify: UI looks modern and is readable in both modes.
- [x] **Task 9: Offline Caching (Simple)**
  - Use `shared_preferences` to cache the last list of articles.
  - Verify: App shows cached data when offline.

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| RSS Feed formats vary | Med | Use a robust parser like `dart_rss` and handle missing fields gracefully. |
| CORS issues on Web | High | Use a CORS proxy (e.g., corsproxy.io) in RssService when kIsWeb is true. |
| Rate limiting from APIs | Low | Cache results locally and avoid frequent refreshes. |

## Open Questions
- Should we use a specific CORS proxy for the web version, or focus on Mobile first?
