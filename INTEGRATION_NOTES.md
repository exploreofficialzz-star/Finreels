# FinReels — "Business of Your Skill/Business/Profession" Integration

## What this patch does

Gives FinReels the piece it was missing to match its own founding thesis:
a way to know what a person actually does, feed algorithms that learn
from what they engage with, a way to find/explore all 60 categories, and
first-run onboarding that asks — instead of showing everyone the same
generic feed.

## The three layers, in the order they were built

### 1. Data foundation (100% verified, zero hallucination risk)
- `resource_categories.json` — all 60 categories, mechanically parsed
  (not hand-typed) from your three source docs via `parse_curriculum.py`.
  100 skill questions, 200 answered business Q&As, 20 profession real-
  problems + questions + "don't know" facts, the 10-module curriculum,
  the full tax-reform fact bank. Every category name cross-checked
  against the PDF directory's own table of contents.
- `verified_resources.json` — real, individually-checked channels and
  blogs, growing incrementally (see "What's verified" below). Kept
  **separate** from resource_categories.json on purpose: one file is
  deterministic research (safe to regenerate), the other only ever grows
  one confirmed entry at a time.

### 2. Personalization (the actual missing piece)
- First-run onboarding — the category picker now runs once, before the
  main shell, then remembers it's done (`UserProfileService.onboardingComplete`).
  Multi-select on purpose: someone can be a nurse who also braids hair on
  the side.
- Every category becomes a "Business Playbook" using your **existing**
  books/insights UI, untouched — zero new screens for that part.
- Selected categories bias the channel round-robin and jump to the front
  of Books, live — no restart needed for Books.

### 3. On-device engagement ranking (honest scope, stated plainly)
`EngagementService` tracks what *this person* actually watches, saves,
and opens, and re-ranks their own feed accordingly — more of what they
engage with, less of what they scroll past. This is on-device implicit-
feedback ranking (weighted counts, decaying ~21-day half-life), **not** a
trained cross-user model — FinReels has no backend to collect that kind
of data or train one. Same *family* of signal Facebook/YouTube use, at
the scale that's actually buildable today. Wired into:
video opens, short auto-plays, book/playbook opens, blog article opens,
and saves (weighted 3x heavier than a plain view).

### 4. Discover / Search — "access everything" without breaking performance
New search icon on the main feed header → `DiscoverScreen` → search or
browse all 60 categories → `CategoryDetailScreen` (playbook + verified
channels + verified blogs for that one category).

**This is the answer to "load all the channels/blogs/books without
hanging or burning data":** `ChannelData.eagerFor(selectedCategoryIds)`
is the one rule everything now goes through — general channels always
fetch, category-tagged channels only fetch if the person actually
selected that category. Browsing a category in Discover fetches *that
category only*, on demand, the moment you tap in — never at launch. Data
model can hold all 60 categories' worth of channels; network traffic
stays flat as more get added. Applied consistently to:
- `FeedProvider.refresh()` (the main feed)
- The background new-upload notification checker (`notification_service.dart`)
  — this runs in its **own isolate** (see background_service.dart), so it
  re-initializes `ResourceCategoryData`/`UserProfileService` itself rather
  than assuming the main app's already-loaded state carries over.

## Files in this patch

**New:**
- `lib/models/resource_category.dart`, `lib/data/resource_category_data.dart`
- `assets/data/resource_categories.json`, `assets/data/verified_resources.json`
- `lib/data/category_playbook_data.dart`
- `lib/services/user_profile_service.dart`, `lib/services/engagement_service.dart`
- `lib/screens/my_business_screen.dart`, `discover_screen.dart`, `category_detail_screen.dart`
- `parse_curriculum.py` (not shipped in the app — regenerates resource_categories.json when the source docs change)

**Modified (all additive — nothing existing removed or renamed):**
- `lib/models/channel.dart` — optional `resourceCategoryId` field
- `lib/data/channel_data.dart` — `combined` / `eagerFor()` — merges the
  original 12 with verified_resources.json, scoped for launch performance
- `lib/services/blog_rss_service.dart` — `combinedBlogFeeds`; `BlogArticle`
  now carries `categoryId` end to end (threaded through the compute()
  isolate boundary) so the reader screen can attribute engagement correctly
- `lib/providers/feed_provider.dart` — eager-fetch scoping, engagement-
  based channel ranking, live Books re-sort on selection change (listens
  to `UserProfileService`, clears just that tab's cache)
- `lib/screens/book_detail_screen.dart` — combined insight lookup; hides
  the "Get Full Book" CTA for original (non-purchasable) playbooks
- `lib/screens/video_player_screen.dart`, `shorts_player_screen.dart`,
  `blog_reader_screen.dart` — engagement-tracking hooks at the screen
  level (catches every navigation path, not just one call site)
- `lib/screens/home_screen.dart` — search icon in the header
- `lib/screens/settings_screen.dart` — "Personalize → My Business" entry
- `lib/services/notification_service.dart` — scoped to eagerFor(), and
  explicitly re-initializes state for its separate isolate
- `lib/main.dart` — startup init, onboarding gate, provider registration
- `lib/config/app_config.dart` — 5 new SharedPreferences keys
- `pubspec.yaml` — bundles `assets/data/`

## What's verified vs. placeholder — no glossing

**Real, live-verified on 2026-07-11** (fetched the actual channel page or
cross-corroborated across multiple independent sources — not copied from
the directory unchecked):

| Category | Channels | Blogs |
|---|---|---|
| Tailoring & Fashion Design | Kim Dave, Ann Usman | Entrepreneurs.ng |
| Hairdressing & Hairstyling | Louis Ihuefo | — |
| Barbing | — | The Splice Blog |
| Makeup Artistry | Damilare Oshodi | — |

Each entry in `verified_resources.json` carries its own
`verificationMethod` field documenting exactly how it was checked — this
is a permanent audit trail, not just a claim in this chat.

**Two feeds (Entrepreneurs.ng, Splice Blog) were confirmed by strong
indirect evidence — a live matching article plus platform/CMS fingerprint
— but not by fetching the raw RSS XML directly**, since this build
sandbox has no outbound network access. One `curl -I` each before
shipping closes that last gap.

**Placeholder, safe, won't crash:** the 60 playbook "books" use
`assets/books/playbook_skill_cover.jpg` / `_business_cover.jpg` /
`_profession_cover.jpg` as cover art. None of those three files exist yet
— `BookCoverImage`'s existing error handling shows the same gold
fallback icon every other book without art shows. Add three images at
those paths whenever you want real covers.

**Not yet done — the other 56 categories' channels/blogs:** real,
per-item verification work, not a bulk copy-paste. Concretely, roughly a
third of the directory's "channel" entries turn out not to be real
YouTube channels at all once checked (podcasts, platforms, media outlets
mislabeled), and several searches this session (welding, graphic design)
didn't surface a clean match — that's an honest, reportable gap, not
something worth forcing a weak match to paper over. The data model and
UI both already support 60/60; content coverage will fill in candidate by
candidate.

## One thing to verify on your end before shipping

```
curl -I https://entrepreneurs.ng/feed/
curl -I https://blog.withsplice.com/feed/
```
If either 404s, remove that entry from `verified_resources.json`;
nothing else depends on it — `ChannelData`/`BlogRssService` both degrade
gracefully to whatever's left.

## Regenerating resource_categories.json later

`parse_curriculum.py` reads your three source markdown docs and
regenerates the file deterministically, with sanity assertions (every
business has exactly 10 Q&A, every profession exactly 4 questions) that
fail loudly instead of silently producing half-populated data. Re-run it
any time those docs change. `verified_resources.json` is untouched by
this script — it's hand/tool-maintained and only ever grows.
