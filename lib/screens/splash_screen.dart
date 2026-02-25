import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../config/theme/app_colors.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import '../services/badge_service.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget Function() destinationBuilder;

  const AnimatedSplashScreen({super.key, required this.destinationBuilder});

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

  void _startMinTimer() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      _minTimeElapsed = true;
      _tryTransition();
    });
  }

  void _tryTransition() {
    if (!_initComplete || !_minTimeElapsed || _transitioned) return;
    if (!mounted) return;
    _transitioned = true;

    _fadeController.stop();
    _pulseController.stop();
    setState(() {});
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

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
