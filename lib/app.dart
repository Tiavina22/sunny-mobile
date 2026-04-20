import 'package:flutter/material.dart';

import 'screens/history_page.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const Color _activeNavColor = Color(0xFFD7A6FF);
  static const Color _inactiveNavColor = Color(0xFFE6DFF3);

  int _currentIndex = 0;

  final List<Widget> _pages = const <Widget>[
    HomePage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3D3551),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
              Set<WidgetState> states,
            ) {
              final bool isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected ? _activeNavColor : _inactiveNavColor,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
              Set<WidgetState> states,
            ) {
              final bool isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                color: isSelected ? _activeNavColor : _inactiveNavColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              );
            }),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            indicatorColor: Colors.transparent,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Historique',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Parametres',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
