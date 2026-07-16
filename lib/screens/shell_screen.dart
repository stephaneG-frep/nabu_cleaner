import 'package:flutter/material.dart';

import 'duplicates_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  void _goTo(int index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onOpenResults: () => _goTo(1),
        onOpenDuplicates: () => _goTo(2),
      ),
      const ResultsScreen(),
      const DuplicatesScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: KeyedSubtree(key: ValueKey(_index), child: screens[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            label: 'Resultats',
          ),
          NavigationDestination(
            icon: Icon(Icons.copy_all_outlined),
            label: 'Doublons',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Reglages',
          ),
        ],
      ),
    );
  }
}
