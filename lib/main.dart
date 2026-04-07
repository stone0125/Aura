// =============================================================================
// main.dart — App Entry Point
// 应用入口文件
//
// This is the first file that runs when the app launches. It initializes
// Firebase, sets up state management providers, and handles authentication
// routing (login → email verification → home screen).
//
// 这是应用启动时运行的第一个文件。它初始化 Firebase，设置状态管理 Provider，
// 并处理身份验证路由（登录 → 邮箱验证 → 主页）。
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme/app_colors.dart';
import 'config/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/badge_service.dart';
import 'services/subscription_service.dart';
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
import 'screens/email_verification_screen.dart';

/// App bootstrap: initialize Flutter bindings and launch the app
/// 应用启动：初始化 Flutter 绑定并启动应用
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load theme before runApp to prevent flash of wrong theme
  // 在 runApp 之前预加载主题，防止主题闪烁
  ThemeMode initialThemeMode = ThemeMode.light;
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');
    initialThemeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  } catch (e) {
    debugPrint('Error loading theme preference: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(MyApp(initialThemeMode: initialThemeMode));
}

/// Root widget — sets up MultiProvider for state management and MaterialApp
/// 根组件 — 设置 MultiProvider 进行状态管理并构建 MaterialApp
class MyApp extends StatelessWidget {
  final ThemeMode initialThemeMode;
  const MyApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app with 7 providers for global state management
    // MultiProvider 用 7 个 Provider 包装应用，实现全局状态管理
    return MultiProvider(
      providers: [
        // Theme Provider — manages light/dark mode (pre-loaded to avoid flash)
        // 主题 Provider — 管理亮色/暗色模式（预加载以避免闪烁）
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialMode: initialThemeMode),
        ),

        // Habit Provider — manages habit list, Firestore sync, streaks
        // 习惯 Provider — 管理习惯列表、Firestore 同步、连续记录
        ChangeNotifierProvider(create: (_) => HabitProvider()),

        // Habit Detail Provider — detailed analytics for a single habit
        // 习惯详情 Provider — 单个习惯的详细分析
        ChangeNotifierProvider(create: (_) => HabitDetailProvider()),

        // AI Coach Provider — AI suggestions, insights, patterns, tips
        // AI 教练 Provider — AI 建议、洞察、模式、技巧
        ChangeNotifierProvider(create: (_) => AICoachProvider()),

        // Progress Provider — depends on HabitProvider, calculates analytics
        // 进度 Provider — 依赖 HabitProvider，计算分析数据
        ChangeNotifierProxyProvider<HabitProvider, ProgressProvider>(
          create: (_) => ProgressProvider(),
          update: (_, habitProvider, progressProvider) =>
              progressProvider!..updateHabits(habitProvider.habits),
        ),

        // Settings Provider — user profile, preferences, account management
        // 设置 Provider — 用户资料、偏好设置、账户管理
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // AI Scoring Provider — habit scoring across 4 dimensions (0-100)
        // AI 评分 Provider — 4 个维度的习惯评分（0-100）
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

/// AuthWrapper — listens to Firebase Auth state and routes users accordingly:
/// - Not logged in → LoginScreen
/// - Email not verified → EmailVerificationScreen
/// - Logged in & verified → HomeScreen
///
/// AuthWrapper — 监听 Firebase Auth 状态并相应路由用户：
/// - 未登录 → 登录页面
/// - 邮箱未验证 → 邮箱验证页面
/// - 已登录且已验证 → 主页
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
    _authSubscription = FirebaseAuth.instance.idTokenChanges().listen((user) {
      if (user == null) {
        // User logged out — clear all provider data to prevent cross-user leaks
        _clearAllProviderData();
      } else {
        // User logged in — re-subscribe to Firestore for the new user
        if (mounted) {
          context.read<HabitProvider>().reinitialize();
        }
      }
    });
  }

  /// Clear all provider data on logout to prevent cross-user data leaks
  /// 登出时清除所有 Provider 数据，防止跨用户数据泄露
  void _clearAllProviderData() {
    if (!mounted) return;

    // Clear each provider independently so one failure doesn't skip the rest
    // 独立清除每个 Provider，防止一个失败导致其余被跳过
    final clearActions = <String, VoidCallback>{
      'HabitProvider': () => context.read<HabitProvider>().clearUserData(),
      'AICoachProvider': () => context.read<AICoachProvider>().clearUserData(),
      'ProgressProvider': () =>
          context.read<ProgressProvider>().clearUserData(),
      'AIScoringProvider': () =>
          context.read<AIScoringProvider>().clearUserData(),
      'HabitDetailProvider': () =>
          context.read<HabitDetailProvider>().clearUserData(),
      'ThemeProvider': () => context.read<ThemeProvider>().clearUserData(),
      'BadgeService': () => BadgeService().resetOnLogout(),
      'SubscriptionService': () => SubscriptionService().logoutUser(),
    };

    for (final entry in clearActions.entries) {
      try {
        entry.value();
      } catch (e) {
        debugPrint('Error clearing ${entry.key}: $e');
      }
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
      stream: FirebaseAuth.instance.idTokenChanges(),
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

        final user = snapshot.data;
        if (user != null) {
          // Gate email/password users behind email verification
          final needsVerification =
              !user.emailVerified &&
              user.providerData.any((p) => p.providerId == 'password');
          if (needsVerification) {
            return const EmailVerificationScreen();
          }
          return HomeScreen(key: HomeScreen.homeKey);
        }

        return const LoginScreen();
      },
    );
  }
}
