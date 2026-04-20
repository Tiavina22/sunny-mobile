import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF2E283F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD7A6FF),
          secondary: Color(0xFFFFBB5C),
          surface: Color(0xFF3D3551),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF3D3551),
          elevation: 0,
        ),
      ),
      home: const AppShell(),
    );
  }
}
