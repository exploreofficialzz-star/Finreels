/// Models for FinReels' 60-category "Business of Your Skill/Business/
/// Profession" taxonomy — the direct app-side representation of the
/// founder's own research (20 Skills, 20 Businesses, 20 Professions +
/// the 10-module curriculum + the 2026 tax-reform fact bank).
///
/// Data is loaded once at startup from `assets/data/resource_categories.json`
/// by [ResourceCategoryData] (see `lib/data/resource_category_data.dart`).
/// This file only defines the shapes.

enum ResourceSection { skill, business, profession }

extension ResourceSectionX on ResourceSection {
  static ResourceSection fromJson(String raw) => switch (raw) {
        'skill' => ResourceSection.skill,
        'business' => ResourceSection.business,
        'profession' => ResourceSection.profession,
        _ => throw ArgumentError('Unknown ResourceSection: $raw'),
      };

  /// User-facing label, e.g. for section headers in the picker screen.
  String get label => switch (this) {
        ResourceSection.skill => 'Skill / Trade',
        ResourceSection.business => 'Business',
        ResourceSection.profession => 'Profession',
      };

  String get pluralLabel => switch (this) {
        ResourceSection.skill => 'Skills & Trades',
        ResourceSection.business => 'Businesses',
        ResourceSection.profession => 'Professions',
      };
}

/// One of the 10 universal curriculum modules (M1–M10) every category's
/// content is tagged against — see curriculum Part 1, "The Universal
/// Scheme of Work". These double as content pillars/playlists.
class CurriculumModule {
  final String code; // 'M1'..'M10'
  final String name;
  final String description;

  const CurriculumModule({
    required this.code,
    required this.name,
    required this.description,
  });

  factory CurriculumModule.fromJson(Map<String, dynamic> j) => CurriculumModule(
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
      );
}

/// One answered question from the 20-Businesses framework — a real,
/// ready-to-read Q&A pair (not a prompt to go find the answer elsewhere).
class BusinessQA {
  final String question;
  final String answer;
  const BusinessQA({required this.question, required this.answer});

  factory BusinessQA.fromJson(Map<String, dynamic> j) => BusinessQA(
        question: j['question'] as String,
        answer: j['answer'] as String,
      );
}

/// Nigeria's 2026 tax-reform fact bank (curriculum Part 2). Cuts across all
/// 20 professions and all 20 skills/trades — the single sharpest, most
/// differentiated content hook in the whole research set.
class TaxReform {
  final String headline;
  final List<String> facts;
  final String? whyItMatters;

  const TaxReform({
    required this.headline,
    required this.facts,
    this.whyItMatters,
  });

  factory TaxReform.fromJson(Map<String, dynamic> j) => TaxReform(
        headline: j['headline'] as String,
        facts: (j['facts'] as List).cast<String>(),
        whyItMatters: j['whyItMatters'] as String?,
      );
}

/// One of the 60 categories (20 Skills + 20 Businesses + 20 Professions).
/// Field population differs by [section] — see the three "shape" groups
/// below — because the three source documents captured genuinely different
/// things: skills got open questions, businesses got answered Q&A,
/// professions got a real-world problem + questions + a "don't know" fact.
class ResourceCategory {
  final String id; // e.g. 'skill_01_tailoring_fashion_design'
  final ResourceSection section;
  final int number; // 1-20 within its section
  final String name; // canonical name, verified against the resource directory

  // ── Skill shape (Section I) ───────────────────────────────────────────
  final List<String>? skillQuestions; // 5 open questions

  // ── Business shape (Section II) ───────────────────────────────────────
  final List<BusinessQA>? businessQA; // 10 answered Q&A pairs

  // ── Profession shape (Section III) ────────────────────────────────────
  final String? realProblem;
  final List<String>? businessQuestions; // 4 open questions
  final String? dontKnowFact;
  final String? dontKnowModule; // primary module code, e.g. 'M6'
  final List<String>? dontKnowModules; // all tagged modules (usually 1, sometimes 2)

  const ResourceCategory({
    required this.id,
    required this.section,
    required this.number,
    required this.name,
    this.skillQuestions,
    this.businessQA,
    this.realProblem,
    this.businessQuestions,
    this.dontKnowFact,
    this.dontKnowModule,
    this.dontKnowModules,
  });

  factory ResourceCategory.fromJson(Map<String, dynamic> j) => ResourceCategory(
        id: j['id'] as String,
        section: ResourceSectionX.fromJson(j['section'] as String),
        number: j['number'] as int,
        name: j['name'] as String,
        skillQuestions: (j['skillQuestions'] as List?)?.cast<String>(),
        businessQA: (j['businessQA'] as List?)
            ?.map((e) => BusinessQA.fromJson(e as Map<String, dynamic>))
            .toList(),
        realProblem: j['realProblem'] as String?,
        businessQuestions: (j['businessQuestions'] as List?)?.cast<String>(),
        dontKnowFact: j['dontKnowFact'] as String?,
        dontKnowModule: j['dontKnowModule'] as String?,
        dontKnowModules: (j['dontKnowModules'] as List?)?.cast<String>(),
      );

  /// Short one-line description for list tiles / cards — first skill
  /// question, first business answer, or the real-world problem,
  /// depending on shape. Always non-null because every category has at
  /// least one of the three shapes populated.
  String get shortDescription {
    if (realProblem != null) return realProblem!;
    if (businessQA != null && businessQA!.isNotEmpty) return businessQA!.first.answer;
    if (skillQuestions != null && skillQuestions!.isNotEmpty) return skillQuestions!.first;
    return name;
  }
}
