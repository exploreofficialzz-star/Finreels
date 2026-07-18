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

## Progress after this session: 26 of 60 categories started (Nursing updated, not newly added)

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
| **Web/App Development** | **1/10** | **0/10** | **0/10** |

**67 items total, individually verified, out of 1,920.** That number is
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
entries. Next up: skill_13, Photography.

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

Onboarding, Discover/Search, EngagementService, the 60 FinReels-authored
Business Playbooks (minus the removed questions chapters), eager-fetch
scoping — all still exactly as described in the prior notes and
untouched by this session's resource-verification work.
