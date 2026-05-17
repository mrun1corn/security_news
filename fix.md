# CyberWatch Drawbacks & Optimizations

## Found Drawbacks (Bugs/Issues)
- [x] **Date Parsing Failure:** Integrated `intl` with multiple RFC 822/1123 patterns for robust parsing across all feeds.
- [x] **Missing Images for BleepingComputer:** Enhanced `FullTextService` to lazily fetch `og:image` metadata when opening articles.
- [x] **Search Performance:** Implemented 300ms debounce in `NewsBloc` using `stream_transform` to prevent UI jank.
- [x] **Reading Time Inaccuracy:** Moved logic to `Article.readingTime` and added HTML tag stripping for accurate word counts.
- [x] **CORS Proxy Fragility:** Created `NetworkUtils` with multi-proxy fallback (corsproxy.io -> allorigins.win).
- [x] **Image Proxying Overhead:** Refactored network layer for cleaner, more reliable fetching.

## Optimization Opportunities
- [x] **Robust Date Parsing:** (Done)
- [x] **Search Debouncing:** (Done)
- [x] **Lazy Content Cleaning:** (Done)
- [x] **Enhanced Image Extraction:** (Done)
- [x] **Multi-Proxy Fallback:** (Done)
- [x] **Shimmer UI Refinement:** Matched shimmer layout to the actual `NewsCard` for a seamless loading experience.

## Visual/UX Drawbacks
- [x] **Image Error UI:** Replaced jumpy `SizedBox.shrink()` with a stable placeholder to maintain layout integrity.
- [x] **Empty Search State:** Improved state handling for empty results.
- [x] **Desktop Responsiveness:** Constrained main content width to 800px on desktop for improved readability.
- [x] **Duplicate Logic:** Consolidated reading time calculation into the `Article` model.
