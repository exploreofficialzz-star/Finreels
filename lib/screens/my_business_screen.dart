import 'package:flutter/material.dart';

import '../data/resource_category_data.dart';
import '../models/resource_category.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';

/// Lets the person tell FinReels what they actually do — their trade,
/// their side business, their profession — from the 60-category research
/// (see resource_category.dart). This is the one piece of information the
/// app was missing to turn "broad, unfiltered content for everyone" into
/// "the specific stuff that answers *your* pain point" — the exact gap
/// described in the founding notes.
///
/// Multi-select on purpose: someone can be a nurse who also does makeup
/// artistry on the side, and both should get priority.
///
/// Built entirely from existing AppTheme colors/typography/spacing —
/// no new visual language, just this app's existing look applied to a
/// new screen.
class MyBusinessScreen extends StatefulWidget {
  /// True when this is shown as part of first-run onboarding (no screen to
  /// pop back to yet) rather than opened from Settings. Changes what
  /// happens on save/skip and softens the copy accordingly.
  final bool isOnboarding;

  /// Called instead of Navigator.pop() when [isOnboarding] is true, after
  /// the selection is saved and onboarding is marked complete — lets the
  /// caller (main.dart) decide how to enter the shell without this screen
  /// needing to import MainShell itself (main_shell.dart -> settings_screen.dart
  /// -> my_business_screen.dart already forms a chain; this avoids turning
  /// it into a cycle).
  final VoidCallback? onDone;

  const MyBusinessScreen({this.isOnboarding = false, this.onDone, super.key});

  @override
  State<MyBusinessScreen> createState() => _MyBusinessScreenState();
}

class _MyBusinessScreenState extends State<MyBusinessScreen> {
  late Set<String> _selected;
  String _query = '';
  bool _loading = !ResourceCategoryData.isLoaded;

  @override
  void initState() {
    super.initState();
    _selected = {...UserProfileService.instance.selectedCategoryIds};
    if (_loading) {
      ResourceCategoryData.load().then((_) {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  Future<void> _save() async {
    await UserProfileService.instance.setSelection(_selected);
    if (!mounted) return;
    if (widget.isOnboarding) {
      await UserProfileService.instance.completeOnboarding();
      if (!mounted) return;
      widget.onDone?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded,
                    color: AppTheme.textColor(context), size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(widget.isOnboarding ? 'What\'s your hustle?' : 'My Business',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Text(
                    'Pick your skill, business or profession so FinReels can '
                    'prioritize content for what you actually do — not just '
                    'generic advice.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary(context)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchField(
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildList(context)),
                _buildSaveBar(context),
              ],
            ),
    );
  }

  Widget _buildList(BuildContext context) {
    final sections = [
      ResourceSection.skill,
      ResourceSection.business,
      ResourceSection.profession,
    ];

    final children = <Widget>[];
    for (final section in sections) {
      final items = ResourceCategoryData.bySection(section).where((c) {
        if (_query.isEmpty) return true;
        return c.name.toLowerCase().contains(_query);
      }).toList();
      if (items.isEmpty) continue;
      children.add(_SectionLabel(section.pluralLabel));
      for (final c in items) {
        children.add(_CategoryTile(
          category: c,
          selected: _selected.contains(c.id),
          onTap: () => _toggle(c.id),
        ));
      }
    }

    if (children.isEmpty) {
      return Center(
        child: Text('No match for "$_query"',
            style: TextStyle(color: AppTheme.textMuted(context))),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: children,
    );
  }

  Widget _buildSaveBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppTheme.bgColor(context),
        border: Border(top: BorderSide(color: AppTheme.dividerColor(context), width: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(
            _selected.isEmpty ? 'Skip for now' : 'Save (${_selected.length} selected)',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor(context), width: 0.5),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: AppTheme.textColor(context)),
        decoration: InputDecoration(
          hintText: 'Search skills, businesses, professions…',
          hintStyle: TextStyle(color: AppTheme.textMuted(context)),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.gold,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ResourceCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.gold.withValues(alpha: 0.10)
                : AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.gold : AppTheme.dividerColor(context),
              width: selected ? 1.2 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      category.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppTheme.gold : AppTheme.textMuted(context),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
