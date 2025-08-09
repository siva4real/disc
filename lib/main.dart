import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/timer_service.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const DisciplineApp());
}

class DisciplineApp extends StatelessWidget {
  const DisciplineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimerService(),
      child: MaterialApp(
        title: 'Discipline Timer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFFC0C0C0)),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
