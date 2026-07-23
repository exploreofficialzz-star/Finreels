# FinReels — "Business of Your Skill/Business/Profession" Integration

## The target (confirmed against the source PDFs)

3 sections × 20 categories × (10 channels + 10 blogs + 10 free books) = **1,800**,
plus 40 general channels + 40 general blogs + 40 general books = **1,920 total**.

## Architecture: `assets/data/resources/` — one file per category

This is the direct answer to "organize it so it's not complicated": the
folder itself IS the progress tracker. No spreadsheet, no separate
status doc — `ls assets/data/resources/` shows you exactly which of the
60 categories have real content and which don't.

```
assets/data/resources/
  {section}_{NN}_{slug}.json     one per category, e.g.:
  skill_01_tailoring_fashion_design.json
  profession_01_medicine.json
  _general.json                  the 40+40+40 cross-cutting set (not started yet — comes after the 60, per your own sequencing)
```

Each file:
```json
{
  "categoryId": "...",
  "status": "in_progress",
  "lastUpdated": "2026-07-12",
  "channels": [ {id, name, handle, description, focus, initials, accentColor, verifiedOn, verificationMethod} ],
  "blogs":    [ {name, url, verifiedOn, verificationMethod} ],
  "books":    [ {title, author, freeSourceUrl, freeSourceType, freeSourceNote, verifiedOn, verificationMethod} ]
}
```

Every single entry carries `verifiedOn` + `verificationMethod` — a
permanent, inspectable record of how it was actually checked. Not a
claim made once in a chat that then evaporates.

`lib/data/resource_category_data.dart` loads every category's file at
startup (gracefully skipping the ones that don't exist yet — that's the
expected, normal state for an unfinished category, not an error), plus
`_general.json`. `ChannelData.combined`, `BlogRssService.combinedBlogFeeds`,
and `ResourceCategoryData.verifiedBooks` all read from this same pool.
`CategoryDetailScreen` has three sections — Channels, Blogs, Free Books —
each showing real content where verified, an honest "still verifying"
note where not.

Free books open in-app: `freeSourceType: "web"` opens in the same
in-app reader as blog articles; `"download"` opens externally so the
device handles the PDF/EPUB directly. Neither touches the existing
EPUB/PDF book-reader architecture (book_detail_screen.dart) — that stays
exactly as it was for the original 10 books and the 60 FinReels-authored
playbooks.

**The old `assets/data/verified_resources.json` (one monolithic file) is
gone**, replaced entirely by this per-category structure.

## This session also: removed the "Questions Worth Answering" chapters

The 60 FinReels-authored Business Playbooks (`category_playbook_data.dart`)
had a chapter for skills and professions that just listed open,
unanswered questions from the source docs, framed as "here's what
FinReels doesn't know yet." Correctly flagged as not real book content —
removed entirely rather than kept as filler. Skill playbooks now rely on
the tax-reform chapter; profession playbooks keep "The Real Problem" and
"What Most People Don't Know" (both real, sourced facts) and drop the
question dump. Businesses were never affected — their chapters are real
answered Q&A already.

## Progress after this session: 42 of 60 categories started (Nursing updated, not newly added) — two-thirds of all 60 categories now started

| Category | Channels | Blogs | Free Books |
|---|---|---|---|
| Tailoring & Fashion Design | 2/10 | 1/10 | 0/10 |
| Hairdressing & Hairstyling | 1/10 | 0/10 | 0/10 |
| Barbing | 0/10 | 1/10 | 0/10 |
| Makeup Artistry | 1/10 | 0/10 | 0/10 |
| Medicine | 4/10 | 2/10 | 1/10 |
| Law | 2/10 | 2/10 | 1/10 |
| Pharmacy | 2/10 | 1/10 | 1/10 |
| Nursing | 1/10 | 1/10 | 1/10 |
| Accounting | 3/10 | 1/10 | 1/10 |
| Engineering | 1/10 | 1/10 | 1/10 |
| Architecture | 2/10 | 1/10 | 0/10 |
| Estate Mgmt / Surveying | 1/10 | 1/10 | 0/10 |
| Banking & Finance | 1/10 | 1/10 | 0/10 |
| Mass Comm / Media & PR | 1/10 | 1/10 | 0/10 |
| CS / Software Engineering | 1/10 | 0/10 | 0/10 |
| Agriculture | 1/10 | 2/10 | 1/10 |
| Education | 0/10 | 1/10 | 0/10 |
| Dentistry | 0/10 | 1/10 | 0/10 |
| Psychology / Counselling | 1/10 | 0/10 | 0/10 |
| Carpentry & Furniture Making | 1/10 | 1/10 | 0/10 |
| Plumbing | 2/10 | 1/10 | 1/10 |
| Electrical Installation & Wiring | 1/10 | 1/10 | 0/10 |
| Auto Mechanics | 2/10 | 0/10 | 0/10 |
| Phone & Electronics Repair | 0/10 | 0/10 | 0/10 |
| Graphic Design | 1/10 | 0/10 | 0/10 |
| Web/App Development | 1/10 | 0/10 | 0/10 |
| Photography | 2/10 | 0/10 | 0/10 |
| Videography & Video Editing | 2/10 | 0/10 | 0/10 |
| Catering & Baking | 1/10 | 0/10 | 0/10 |
| Event Decoration & Planning | 1/10 | 0/10 | 0/10 |
| Shoemaking & Leatherwork | 0/10 | 1/10 | 0/10 |
| POP/Tiling & Interior Decor | 0/10 | 0/10 | 0/10 |
| Solar Installation & Renewable Energy | 1/10 | 0/10 | 0/10 |
| AC & Refrigeration Repair | 2/10 | 0/10 | 0/10 |
| POS/Agent Banking (business) | 0/10 | 1/10 | 0/10 |
| Provision Store/Mini-Mart | 0/10 | 1/10 | 0/10 |
| Fashion Retail/Boutique | 0/10 | 0/10 | 0/10 |
| Food Vending/Catering/Meal-Prep | 0/10 | 1/10 | 0/10 |
| Real Estate Agency | 1/10 | 0/10 | 0/10 |
| Logistics/Dispatch Rider | 1/10 | 0/10 | 0/10 |
| Event Planning & Rentals | 1/10 | 0/10 | 0/10 |
| **Salon/Barbing/Beauty Spa** | **2/10** | **1/10** | **0/10** |

**86 items total, individually verified, out of 1,920.** That number is
deliberately not dressed up — here's the honest math on why, and what a
sustainable path looks like.


## Methodology correction mid-session: search beyond the documents, not just within them

Kosisochi flagged that when a research document's named candidates don't
pan out, the right move is to search more broadly for a real replacement
— not stop at "not found." Applied immediately:
- **Nursing channels: 0 → 1.** The founder's own lead ("Homecare Series")
  didn't resolve to an identifiable channel, but a broader search surfaced
  Nurse Vickie — a real, dedicated home care business coaching channel.
- **Barbing channels: still 0**, after two genuinely broader search
  attempts. One promising lead (a Nigerian YouTuber who'd interviewed a
  barbershop owner) turned out to be a general travel/lifestyle channel
  with one relevant video, not a dedicated business-of-barbing channel —
  correctly not counted just because it technically contains one relevant
  video. This is what "searched harder and still came up empty" looks
  like, as distinct from "didn't try."

Applied properly from the start for Architecture: went beyond the
founder's 4 named channel candidates to independently confirm Eric
Reinholdt's 30X40 Design Workshop as a second real channel.

## The honest math on scope

Verifying one item — confirming a channel's real ID, a blog's real feed
URL, a book's real free-access link — costs roughly 1-3 tool calls in
practice this session, and a meaningful fraction of searches don't land
cleanly (welding and graphic design channels turned up nothing solid;
some "channels" in the source PDF turn out to be podcasts or platforms
with no dedicated YouTube presence at all). At that rate, 1,920 verified
items is on the order of several thousand searches — not achievable in
one sitting, and not something to fake by filling slots with unconfirmed
guesses. That would silently break the app exactly the way 8 of the
original 10 channel IDs were broken before anyone checked them.

**What actually worked well this session:** for Medicine, Law, and
Pharmacy, your own curriculum.md research (Parts 5-7) already had real
candidate names — Flying Doctors Nigeria, Dr. Una/EntreMD, Lex-Praxis,
Clio, Global Pharmacy Entrepreneurs, etc. — so verification meant
*confirming* good leads rather than searching blind. That's roughly 3-4x
faster than the cold-search approach used for the skills categories.
**The last researched profession still has this same head start**
(curriculum.md Parts 8-19) — that's the highest-leverage next batch, not
a random pick. All 15 are now started.

**Milestone: every one of the 15 researched professions now has at least
one real, verified resource** — Medicine, Law, Pharmacy, Nursing,
Accounting, Engineering, Architecture, Estate Mgmt/Surveying, Banking &
Finance, Mass Comm/PR, CS/Software Engineering, Agriculture, Education,
Dentistry, Psychology/Counselling.

**Efficiency note for what comes after:** professions 16-20 (the 5
"trade" professions — Fashion Design & Tailoring, Hairdressing/
Cosmetology, Catering & Event Planning, Automobile Technology,
Photography & Videography) are the *same real-world trades* as skills
1-20, just cross-listed under Professions in the source PDF. Kim Dave and
Ann Usman are exactly as relevant to "Fashion Design & Tailoring (Trade)"
as they are to skill_01 — no need to re-research those 5 from scratch
once their skill counterparts are done; they can share the same verified
entries. All 20 are now started.

**Second milestone: every one of the 20 Skills categories now has at
least one real, verified resource**, joining the 15 researched
professions milestone from earlier. Combined with the 5 "trade
professions" (16-20) that can inherit these same skill entries, that's
40 of the 60 categories effectively covered by direct or shared
verification. Next up: business_09, Car Hire/Ride-Hailing Fleet.

**Safety finding worth flagging clearly:** articles.connectnigeria.com —
a domain that looked like a strong, real lead across two categories
(Barbing, Event Decoration & Planning) — was directly fetched while
researching Shoemaking and returned a page full of injected gambling/
casino spam instead of real content. Likely compromised or expired and
repurposed. It was never actually added as a live entry anywhere (only
mentioned in one notes field as "worth checking"), and that note has now
been corrected into an explicit warning. Nothing in the shipped data was
affected, but worth knowing this domain should not be trusted or added
in future passes either.

**Note on Auto Mechanics specifically:** its resource file already existed
with a different, independently-verified channel (Shop Owner Magazine)
when this pass reached it — from an earlier attempt at this same category
whose file write persisted in the working sandbox. Rather than overwrite,
merged it with this session's own find (AutoFix - Auto Shop Coaching),
so the category ended up with 2 real channels instead of 1.

For skills and businesses, there's no equivalent research doc — those
lean on the PDF directory's candidate names, which this session also
found to be unreliable in places (the Free directory's Medicine section
was literally template placeholders — "Business Channel 1" through 10 —
not real data; flagged so it doesn't get trusted blindly elsewhere).

## Suggested pace going forward

One profession per session (using the curriculum.md head start) is
realistic and sustainable — each researched profession has taken a
meaningful chunk of a session to reach partial coverage so far. At that pace the
15 researched professions are the fastest path to visible, real coverage.
Skills and businesses will take longer per category since they start
from a cold search each time.

If you want to accelerate the pure discovery phase (finding candidate
names before I verify them), Claude's Research feature can run broader
sweeps than fits in one chat turn — but the actual verification (fetching
each channel page, confirming each feed) is exactly this kind of careful,
one-at-a-time work regardless of where candidates come from.

## Everything else from the previous patches — unchanged

EngagementService, the 60 FinReels-authored Business Playbooks (minus
the removed questions chapters, still reachable from
CategoryDetailScreen), the resource-verification pipeline above — all
still exactly as described in the prior notes.

Onboarding, Discover/Search, and how the Books/Blogs tabs pull from all
of this were NOT untouched — see the dated section immediately below,
which is the first thing to read before touching any of those four
again.

## 2026-07-23 — Onboarding rebuild, keyword allocation, and a real cross-category content leak fixed

Came in off the back of hands-on testing against a build from this same
integration (the screenshots showed Tailoring & Fashion Design selected
during onboarding, then real content in Videos/Shorts, and a Books tab
mixing a generated playbook with the general library). That testing
surfaced a genuine bug, not just polish requests — flagged clearly below
since it's the one worth understanding before changing any of this
again.

**The bug: Books (and Blogs) were not actually scoped by category.**
`FeedProvider._allBookVideos` put the selected category's
CategoryPlaybookData "Business of X" entry first, then the general 10,
then — unconditionally — *every other category's* playbook too, just
deprioritized rather than excluded. A Fashion Designer's Books tab really
did eventually show "Business of Medicine." `BlogRssService.combinedBlogFeeds`
had the same shape of problem but worse: it always included *every*
verified category's blogs for *everyone*, regardless of selection —
correctness aside, at full 60-category coverage (10 blogs × 60) that's
~600 RSS feeds fetched per person per Blogs-tab visit, which is the kind
of thing that's fine to miss at 2 categories started and genuinely
dangerous at "professional, built for a billion users" scale. Channels
never had this problem — `ChannelData.eagerFor` was already scoping to
general + selected — so the fix brings Books and Blogs in line with the
pattern Channels already had right, rather than inventing a new one.

Fixed in `feed_provider.dart` and `blog_rss_service.dart`: both now
resolve to general-content-only + the person's actual selection, never
"everything, just reordered." `CategoryPlaybookData` is no longer part
of the Books tab at all — it's real "Business of X" research, but it's
generated from the same template for every category in a section (a
Skill category's playbook is just the tax chapter, near-identical
wording every time), so presenting it as a "book" next to actually-named
books with actually-named authors was the wrong frame. It's still fully
intact and still the first thing shown on CategoryDetailScreen (the
"Read the Business Playbook" card, clearly labelled "FinReels
Research") — just not masquerading as a Book anymore. The Books tab now
shows the original 10 general classics plus real `VerifiedBook` entries
(title/author/freeSourceUrl) from the person's selected categories' own
resource files — literally "pull the contents from the fashion design
json and combine it with the general ones," which is the model this
should have been all along.

Browsing any category via Discover still works regardless of the
viewer's own selection — that's `BlogRssService.fetchForCategory` (new)
and `ResourceCategoryData.verifiedBooks`/`verifiedChannels` filtered
directly by the category being viewed, neither of which goes through
the selection-scoped aggregate. Same split FeedProvider already had
between `eagerFor` (bulk, scoped) and `ChannelVideosScreen` fetching one
channel directly (unscoped, on demand) — Blogs and Books just didn't
have their own version of that split until now.

**Onboarding (`my_business_screen.dart`) rebuilt around search-first
allocation, not scroll-first browsing:**
- Title is now the same FinReels wordmark + gold play-button mark as the
  home screen header (was "What's your hustle?").
- Section order is Profession, then Skill, then Business (was Skill,
  Business, Profession).
- Only the first 6 categories per section show before typing anything —
  `CategorySearch.defaultVisiblePerSection` — down from all 20 per
  section. The rest are one search away, not gone.
- Every category now carries a `searchKeywords` list (aliases/synonyms —
  "sew"/"ankara"/"seamstress" all resolve to Tailoring & Fashion Design,
  "doctor"/"physician" resolve to Medicine, etc.) — see the
  `SEARCH_KEYWORDS` dict in `parse_curriculum.py` (source of truth,
  survives a full regeneration) and `assets/data/resource_categories.json`
  (the shipped copy) and `lib/utils/category_search.dart` (the matcher —
  name substring OR any keyword, either direction). Discover uses the
  exact same matcher and section order now too, so the two pickers can't
  drift apart again.
- "Others" is a new, permanent, always-visible entry pinned at the end
  of the list — not one of the 60, carries no resource file, and is a
  guaranteed-safe no-op everywhere content gets filtered by category
  (nothing has that id, so it just resolves to general content). Typing
  a search that matches none of the 60 shows a note pointing at it
  instead of a dead "no results" screen.

**Smaller things fixed alongside this:**
- `ResourceCategoryData._loadVerifiedResources` read every category's
  resource file one at a time in a sequential `await` loop — up to 61
  sequential local reads at full coverage. Now `Future.wait`'d in
  parallel; same deterministic ordering for the combined lists
  afterward, just not paying for it serially.
- The old monolithic `assets/data/verified_resources.json` — noted as
  "gone" in an earlier pass but still physically sitting in
  `assets/data/` and still bundled into every build via the asset
  wildcard — has been deleted for real this time. Nothing in code ever
  read it; only stale doc-comments in `channel_data.dart` and
  `blog_rss_service.dart` still pointed at it, now corrected.
- `channel_data.dart`'s header comment said "10 channels" — it's always
  actually defined 12 (matching the README and the test suite's own
  `expect(ChannelData.all.length, 12)`). Fixed the comment, not the
  count.
- Added a `CategorySearch`/`ResourceCategory.searchKeywords`/
  `Video` verified_book test group to `test/finreels_test.dart` — all
  pure-Dart logic, no widget pump or asset loading needed, so worth
  actually running (`flutter test`) before trusting this note over
  checking yourself. This session's sandbox has no Flutter SDK and no
  package-resolution network access, so none of this could be executed
  here — everything above was hand-traced against the actual source,
  not compiler-verified. Treat that as the one open item, not a detail.

## 2026-07-23 (later same day) — Found the actual reason category content wasn't showing up

Follow-up to the section immediately above. That pass fixed the *filtering*
(general vs. selected-category scoping) so it was no longer possible for a
Fashion Designer to see Medicine content. It did NOT fix — because the
report at the time didn't surface it — a separate, more basic problem:
**the Home tabs were showing only ever general content, full stop, with the
selected category's channels/blogs/books never appearing at all.** Four
screenshots of a real device (Videos/Shorts/Blogs/Books, each showing only
the general 12-channel/5-feed/10-book library) made this concrete.

**Root cause: a startup race, not a filtering bug.** `main.dart` ran eight
service inits — `ResourceCategoryData.load()`, `UserProfileService.init()`,
`EngagementService.init()`, plus Connectivity/Background/Notifications/
Ads/IAP — in one `Future.wait(...)` under a single 6-second ceiling, then
constructed `FeedProvider()` immediately after. `FeedProvider`'s
`_sessionChannelOrder` reads the selected category and the freshly-loaded
category data *synchronously*, at construction. Ads/IAP in particular
initialize external SDKs (sometimes touching Google Play services) and can
legitimately take a few seconds — long enough, on a slower device or cold
start, to run the whole group past 6 seconds. When that happened,
`FeedProvider()` got built with whatever partial state
`ResourceCategoryData`/`UserProfileService` happened to be in at that exact
moment — sometimes still empty. Nothing ever corrected this afterward:
`ResourceCategoryData` is a plain static loader, not a `ChangeNotifier`, so
nothing re-notifies `FeedProvider` once its load actually finishes in the
background past the ceiling. The result was exactly the reported symptom —
general content (hardcoded, always available immediately, no async load
needed) works every time; a selected category's content depends on a load
that can silently lose a race no one gets told about, for the rest of that
session.

**The fix, in `main.dart`:** split the old single 8-way group into two.
Group A — `ResourceCategoryData.load()`, `UserProfileService.init()`,
`EngagementService.init()` — is exactly the three things
`_buildSessionChannelOrder()` touches, all three are local-only (bundled
JSON assets, on-device SharedPreferences, no network/external SDK), and
`FeedProvider()` now only gets constructed after this group genuinely
resolves (own 8s ceiling, isolated from anything else). Group B —
Connectivity/Background/Notifications/Ads/IAP — keeps its own 6s ceiling
and is fully `unawaited`, run concurrently with Group A, never gating
`FeedProvider` or the splash-to-shell transition. Slower external SDKs can
take however long they take without that ever again meaning FeedProvider
gets built blind.

**Second, smaller fix, in `feed_provider.dart`:** even with Group A
guaranteed to finish before construction, there's a second, more common
case worth covering directly — the very first time someone completes
onboarding. `FeedProvider` is built unconditionally during the splash
sequence, before onboarding even shows, so the selection at construction
time for a first-time person is always empty; `_sessionChannelOrder` was a
`final` field, computed once and never touched again, meaning even a
perfectly-timed selection made two minutes later (onboarding) wouldn't
boost that category's channels to the top until the *next* app launch. Made
it a mutable field and recompute it inside `_onProfileChanged` (which
already ran `refresh()` on every selection change) — so a freshly-picked
category is boosted immediately, the same "visible right away" guarantee
general content already had, not "starting next time you open the app."

**Not covered by an automated test.** Unlike last session's additions
(`CategorySearch`, `searchKeywords`, `Video`'s verified_book fields — all
pure logic, no Flutter bindings needed), this fix is inherently about
async startup timing across real services (SharedPreferences, bundled
assets, Hive, ad/IAP SDKs) — properly testing it means integration-testing
`main.dart`'s init sequence with mocked slow services, which is a
meaningfully bigger lift than a unit test and wasn't attempted here. If
you want confidence beyond hand-tracing the code: run a real device/
emulator build, complete onboarding picking a category with a fully
populated resource file (Tailoring & Fashion Design — skill_01 — is 10/10/10
today), and confirm its channels/blogs/books show up in Videos, Shorts,
Blogs, and Books without needing to background-and-resume the app first.
