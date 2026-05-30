import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThaiUniverseApp());
}

class ThaiUniverseApp extends StatelessWidget {
  const ThaiUniverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '태국어유니버스',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const MainScreen(),
    );
  }
}
