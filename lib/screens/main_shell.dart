import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'channels_screen.dart';
import 'home_screen.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    ChannelsScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Full screen content — visible behind the floating nav
          IndexedStack(index: _index, children: _screens),

          // Floating bottom nav
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: _FloatingNavBar(
              currentIndex: _index,
              isDark: isDark,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Nav Bar ──────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_outlined,    Icons.home_rounded,              'Feed'),
    (Icons.play_circle_outline_rounded, Icons.play_circle_rounded, 'Channels'),
    (Icons.bookmark_outline_rounded,    Icons.bookmark_rounded,    'Saved'),
    (Icons.settings_outlined,           Icons.settings_rounded,    'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A1A).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final isActive = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isActive ? item.$2 : item.$1,
                      key: ValueKey(isActive),
                      color: isActive
                          ? AppTheme.gold
                          : (isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted),
                      size: isActive ? 26 : 24,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$3,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.gold
                          : (isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted),
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
