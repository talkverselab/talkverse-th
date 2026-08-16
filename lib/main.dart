import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'screens/main_screen.dart';

late final AppDatabase appDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
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
