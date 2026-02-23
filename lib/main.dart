import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_colors.dart';
import 'config/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/habit_detail_provider.dart';
import 'providers/ai_coach_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ai_scoring_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
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

        // Progress Provider (depends on HabitProvider)
        ChangeNotifierProxyProvider<HabitProvider, ProgressProvider>(
          create: (_) => ProgressProvider(),
          update: (_, habitProvider, progressProvider) =>
              progressProvider!..updateHabits(habitProvider.habits),
        ),

        // Settings Provider
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // AI Scoring Provider
        ChangeNotifierProvider(create: (_) => AIScoringProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Aura',
            debugShowCheckedModeBanner: false,

            // Theme configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Home screen wrapper for Auth
            home: AnimatedSplashScreen(
              destinationBuilder: () => const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        // User logged out — clear all provider data to prevent cross-user leaks
        _clearAllProviderData();
      }
    });
  }

  void _clearAllProviderData() {
    if (!mounted) return;
    try {
      context.read<HabitProvider>().clearUserData();
      context.read<AICoachProvider>().clearUserData();
      context.read<ProgressProvider>().clearUserData();
      context.read<AIScoringProvider>().clearUserData();
      context.read<HabitDetailProvider>().clearUserData();
      context.read<ThemeProvider>().clearUserData();
    } catch (e) {
      debugPrint('Error clearing provider data on logout: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final isDark =
              MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.splashDarkGradientStart
                : AppColors.splashGradientStart,
            body: const SizedBox.shrink(),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen(key: HomeScreen.homeKey);
        }

        return const LoginScreen();
      },
    );
  }
}
