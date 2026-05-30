import 'package:flutter/material.dart';

import 'alphabet_screen.dart';
import 'home_screen.dart';
import 'tones_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _tabs = <_Tab>[
    _Tab('홈', Icons.home_outlined, Icons.home_rounded),
    _Tab('알파벳', Icons.abc_outlined, Icons.abc_rounded),
    _Tab('성조', Icons.graphic_eq_outlined, Icons.graphic_eq_rounded),
    _Tab('회화', Icons.forum_outlined, Icons.forum_rounded),
    _Tab('내 학습', Icons.person_outline, Icons.person_rounded),
  ];

  Widget _body() {
    switch (_index) {
      case 0:
        return HomeScreen(onNavigate: (i) => setState(() => _index = i));
      case 1:
        return const AlphabetScreen();
      case 2:
        return const TonesScreen();
      default:
        return _Placeholder(label: _tabs[_index].label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selected),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData selected;
  const _Tab(this.label, this.icon, this.selected);
}

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(
          '$label — 준비 중',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
