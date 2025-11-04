import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/habit_detail_provider.dart';
import 'providers/ai_coach_provider.dart';
import 'screens/home_screen.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Habit Provider
        ChangeNotifierProvider(create: (_) => HabitProvider()),

        // Habit Detail Provider
        ChangeNotifierProvider(create: (_) => HabitDetailProvider()),

        // AI Coach Provider
        ChangeNotifierProvider(create: (_) => AICoachProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Habit Tracker',
            debugShowCheckedModeBanner: false,

            // Theme configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Home screen
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
