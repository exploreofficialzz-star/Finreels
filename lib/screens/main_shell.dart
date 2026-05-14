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

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Feed',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.play_circle_outline_rounded),
      activeIcon: Icon(Icons.play_circle_rounded),
      label: 'Channels',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bookmark_outline_rounded),
      activeIcon: Icon(Icons.bookmark_rounded),
      label: 'Saved',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: _items,
      ),
    );
  }
}
