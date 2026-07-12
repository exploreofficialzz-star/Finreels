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
and the new `ResourceCategoryData.verifiedBooks` all read from this same
pool. `CategoryDetailScreen` now has three sections — Channels, Blogs,
Free Books — each showing real content where verified, an honest "still
verifying" note where not.

Free books open in-app: `freeSourceType: "web"` opens in the same
in-app reader as blog articles; `"download"` opens externally so the
device handles the PDF/EPUB directly. Neither touches the existing
EPUB/PDF book-reader architecture (book_detail_screen.dart) — that stays
exactly as it was for the original 10 books and the 60 FinReels-authored
playbooks.

**The old `assets/data/verified_resources.json` (one monolithic file) is
gone**, replaced entirely by this per-category structure. Nothing else
changed from the previous patch's architecture — `ChannelData.eagerFor()`,
the engagement ranking, onboarding, Discover/Search all work identically,
just reading from more files now.

## Progress after this session: 5 of 60 categories started

| Category | Channels | Blogs | Free Books |
|---|---|---|---|
| Tailoring & Fashion Design | 2/10 | 1/10 | 0/10 |
| Hairdressing & Hairstyling | 1/10 | 0/10 | 0/10 |
| Barbing | 0/10 | 1/10 | 0/10 |
| Makeup Artistry | 1/10 | 0/10 | 0/10 |
| **Medicine** | **4/10** | **2/10** | **1/10** |

**13 items total, individually verified, out of 1,920.** That number is
deliberately not dressed up — here's the honest math on why, and what a
sustainable path looks like.

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

**What actually worked well this session:** for Medicine, your own
curriculum.md research (Part 5) already had real candidate names —
Flying Doctors Nigeria, Dr. Una/EntreMD, White Coat Investor, etc. —
so verification meant *confirming* good leads rather than searching
blind. That's roughly 3-4x faster than the cold-search approach I used
for the skills categories. **The other 14 professions already have this
same head start** (curriculum.md Parts 6-19) — that's the highest-leverage
next batch, not a random pick.

For skills and businesses, there's no equivalent research doc — those
lean on the PDF directory's candidate names, which this session also
found to be unreliable in places (the Free directory's Medicine section
was literally template placeholders — "Business Channel 1" through 10 —
not real data; flagged so it doesn't get trusted blindly elsewhere).

## Suggested pace going forward

One profession per session (using the curriculum.md head start) is
realistic and sustainable — Medicine took most of a session to reach
4+2+1. At that pace the 15 researched professions are the fastest path
to visible, real coverage. Skills and businesses will take longer per
category since they start from a cold search each time.

If you want to accelerate the pure discovery phase (finding candidate
names before I verify them), Claude's Research feature can run broader
sweeps than fits in one chat turn — but the actual verification (fetching
each channel page, confirming each feed) is exactly this kind of careful,
one-at-a-time work regardless of where candidates come from.

## Everything else from the previous patch — unchanged

Onboarding, Discover/Search, EngagementService, the 60 FinReels-authored
Business Playbooks, eager-fetch scoping — all still exactly as described
in the prior notes and untouched by this session's work. This file
supersedes the resource-verification section of the earlier notes only;
everything else there still applies.
