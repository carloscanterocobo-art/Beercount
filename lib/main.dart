import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeercountApp());
}

class BeercountApp extends StatelessWidget {
  const BeercountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beercount',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
