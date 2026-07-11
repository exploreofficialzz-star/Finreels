import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import '../models/channel.dart';
import '../models/resource_category.dart';

/// Loads and indexes `assets/data/resource_categories.json` — the app-side
/// copy of FinReels' 60-category "Business of Your Skill/Business/
/// Profession" research (see resource_category.dart for the shapes) —
/// AND `assets/data/verified_resources.json`, the incrementally-growing
/// set of real, individually-verified channels and blog feeds per
/// category (see [verifiedChannels] / [verifiedBlogs]).
///
/// These are deliberately two separate files with two separate lifecycles:
/// `resource_categories.json` is fully regenerated from the three source
/// docs any time parse_curriculum.py runs (deterministic, hand-authored
/// research). `verified_resources.json` only ever grows, one confirmed
/// entry at a time — it's never bulk-regenerated, because every entry in
/// it represents an individual channel page or feed URL that was actually
/// checked, not copied from the directory unverified.
///
/// Loaded once during startup (see main.dart's service-init group) so that
/// by the time any screen needs it — the "My Business" picker, the feed
/// provider building category playbooks — [all] is already populated and
/// every access below is synchronous.
class ResourceCategoryData {
  ResourceCategoryData._();

  static List<ResourceCategory> _all = const [];
  static List<CurriculumModule> _modules = const [];
  static TaxReform? _taxReform;
  static bool _loaded = false;

  static bool get isLoaded => _loaded;
  static List<ResourceCategory> get all => _all;
  static List<CurriculumModule> get modules => _modules;
  static TaxReform? get taxReform => _taxReform;

  static final Map<String, ResourceCategory> _byId = {};

  static List<Channel> _verifiedChannels = const [];
  static List<Map<String, String>> _verifiedBlogs = const [];
  static Map<String, dynamic> _verifiedRaw = const {};

  static List<Channel> get verifiedChannels => _verifiedChannels;
  static List<Map<String, String>> get verifiedBlogs => _verifiedBlogs;

  /// Idempotent — safe to call more than once (e.g. a screen calling it
  /// defensively); only the first call does real work.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/resource_categories.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;

      _modules = (json['modules'] as List)
          .map((m) => CurriculumModule.fromJson(m as Map<String, dynamic>))
          .toList(growable: false);

      _taxReform = TaxReform.fromJson(json['taxReform'] as Map<String, dynamic>);

      _all = (json['categories'] as List)
          .map((c) => ResourceCategory.fromJson(c as Map<String, dynamic>))
          .toList(growable: false);

      _byId
        ..clear()
        ..addEntries(_all.map((c) => MapEntry(c.id, c)));

      _loaded = true;
    } on Object catch (e) {
      // Never let a bad/missing asset take the app down — the picker and
      // the playbook books just degrade to "not available yet" instead.
      debugPrint('[ResourceCategoryData] load failed (non-fatal): $e');
    }
    await _loadVerifiedResources();
  }

  static Future<void> _loadVerifiedResources() async {
    try {
      final raw = await rootBundle.loadString('assets/data/verified_resources.json');
      _verifiedRaw = jsonDecode(raw) as Map<String, dynamic>;

      final channels = <Channel>[];
      final blogs = <Map<String, String>>[];

      _verifiedRaw.forEach((categoryId, entry) {
        final map = entry as Map<String, dynamic>;
        for (final c in (map['channels'] as List? ?? [])) {
          final ch = c as Map<String, dynamic>;
          channels.add(Channel(
            id: ch['id'] as String,
            name: ch['name'] as String,
            handle: ch['handle'] as String,
            description: ch['description'] as String? ?? '',
            accentColor: Color(int.parse((ch['accentColor'] as String? ?? '0xFFF59E0B'))),
            category: 'Business of Your Skill',
            focus: ch['focus'] as String? ?? '',
            initials: ch['initials'] as String? ?? '',
            resourceCategoryId: categoryId,
          ));
        }
        for (final b in (map['blogs'] as List? ?? [])) {
          final bl = b as Map<String, dynamic>;
          blogs.add({
            'name': bl['name'] as String,
            'url': bl['url'] as String,
            'categoryId': categoryId,
          });
        }
      });

      _verifiedChannels = List.unmodifiable(channels);
      _verifiedBlogs = List.unmodifiable(blogs);
    } on Object catch (e) {
      // Same non-fatal philosophy as above — worst case, only the const
      // 12 general channels / 5 general blogs are available, exactly
      // today's behavior, nothing crashes.
      debugPrint('[ResourceCategoryData] verified_resources load failed (non-fatal): $e');
    }
  }

  /// Raw verified-resources entry for one category, e.g. to check "does
  /// this category have any verified books yet" from CategoryPlaybookData.
  static Map<String, dynamic>? verifiedFor(String categoryId) =>
      _verifiedRaw[categoryId] as Map<String, dynamic>?;

  static ResourceCategory? byId(String id) => _byId[id];

  static List<ResourceCategory> bySection(ResourceSection section) =>
      _all.where((c) => c.section == section).toList(growable: false);

  static CurriculumModule? moduleByCode(String code) =>
      _modules.where((m) => m.code == code).firstOrNull;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
