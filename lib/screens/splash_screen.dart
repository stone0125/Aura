import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../config/theme/app_colors.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import '../services/badge_service.dart';

/// Animated splash screen shown during app initialization
/// 应用初始化时显示的动画启动屏幕
class AnimatedSplashScreen extends StatefulWidget {
  final Widget Function() destinationBuilder;

  /// Creates the animated splash screen with a destination builder callback
  /// 使用目标构建器回调创建动画启动屏幕
  const AnimatedSplashScreen({super.key, required this.destinationBuilder});

  /// Creates the mutable state for the splash screen
  /// 创建启动屏幕的可变状态
  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _pulseGlow;

  bool _initComplete = false;
  bool _minTimeElapsed = false;
  bool _transitioned = false;

  /// Initializes animations and starts app initialization
  /// 初始化动画并开始应用初始化
  @override
  void initState() {
    super.initState();

    // Logo fade-in + scale (500ms)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _logoFade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _textFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    // Pulse glow (1500ms, repeating) — starts immediately
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseGlow = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start all animations together
    _fadeController.forward();
    _pulseController.repeat(reverse: true);

    _initializeApp();
    _startMinTimer();
  }

  /// Initializes Firebase, notifications, subscriptions, and badge services
  /// 初始化Firebase、通知、订阅和徽章服务
  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await Future.wait([
        NotificationService().initialize(),
        SubscriptionService().initialize(),
        BadgeService().initialize(),
      ]);
    } catch (e) {
      debugPrint('Splash init error: $e');
    }

    _initComplete = true;
    _tryTransition();
  }

  /// Starts a minimum display timer to ensure splash is shown long enough
  /// 启动最短显示计时器，确保启动屏幕显示足够长的时间
  void _startMinTimer() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      _minTimeElapsed = true;
      _tryTransition();
    });
  }

  /// Attempts to transition to the destination screen when both init and timer are done
  /// 当初始化和计时器都完成时，尝试过渡到目标屏幕
  void _tryTransition() {
    if (!_initComplete || !_minTimeElapsed || _transitioned) return;
    if (!mounted) return;
    _transitioned = true;

    _fadeController.stop();
    _pulseController.stop();
    setState(() {});
  }

  /// Disposes animation controllers
  /// 释放动画控制器资源
  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Builds the splash screen UI with animated logo and gradient background
  /// 构建带有动画标志和渐变背景的启动屏幕界面
  @override
  Widget build(BuildContext context) {
    if (_transitioned) {
      return widget.destinationBuilder();
    }

    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.splashDarkGradientStart
            : AppColors.splashGradientStart,
        body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        AppColors.splashDarkGradientStart,
                        AppColors.splashDarkGradientMiddle,
                        AppColors.splashDarkGradientEnd,
                      ]
                    : const [
                        AppColors.splashGradientStart,
                        AppColors.splashGradientMiddle,
                        AppColors.splashGradientEnd,
                      ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with scale + fade + animated glow
                AnimatedBuilder(
                  animation: Listenable.merge([_logoFade, _pulseGlow]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                        ? AppColors.splashDarkGlow
                                        : AppColors.splashGlow)
                                    .withValues(alpha: _pulseGlow.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/icon.png',
                              width: 120,
                              height: 120,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // App name with slide-up + fade-in
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: const Text(
                      'Aura',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
