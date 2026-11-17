import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'counter_screen.dart';
import 'history_screen.dart';
import 'economy_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<String> titles = [
    'Contador',
    'Historial',
    'Estadísticas económicas',
    'Configuración',
  ];

  final List<Widget> screens = const [
    CounterScreen(),
    HistoryScreen(),
    EconomyScreen(),
    SettingsScreen(),
  ];

  final List<IconData> icons = [
    Icons.sports_bar,
    Icons.history,
    Icons.bar_chart,
    Icons.settings,
  ];

  void changeScreen(int index) {
    setState(() {
      selectedIndex = index;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'BEERCOUNT',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),

      drawer: Drawer(
        width: 285,
        child: SafeArea(
          child: Column(
            children: [
              // Cabecera del menú
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                decoration: const BoxDecoration(color: AppTheme.background),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.sports_bar,
                        size: 34,
                        color: AppTheme.background,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'BEERCOUNT',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'COUNT YOUR BEERS.',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Opciones de navegación
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: titles.length,
                  itemBuilder: (context, index) {
                    final bool selected = selectedIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        selected: selected,
                        selectedTileColor: AppTheme.surfaceHighlight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          icons[index],
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        title: Text(
                          titles[index],
                          style: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () => changeScreen(index),
                      ),
                    );
                  },
                ),
              ),

              const Divider(indent: 20, endIndent: 20),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'BEERCOUNT · VERSIÓN 1.0',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: IndexedStack(index: selectedIndex, children: screens),
    );
  }
}
