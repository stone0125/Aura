import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/theme/app_colors.dart';
import '../services/auth_service.dart';

/// Screen prompting the user to verify their email address
/// 提示用户验证其电子邮件地址的屏幕
class EmailVerificationScreen extends StatefulWidget {
  /// Creates the email verification screen
  /// 创建电子邮件验证屏幕
  const EmailVerificationScreen({super.key});

  /// Creates the mutable state for the email verification screen
  /// 创建电子邮件验证屏幕的可变状态
  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isCheckingVerification = false;

  /// Initializes the state, registers lifecycle observer, and starts polling
  /// 初始化状态，注册生命周期观察者，并开始轮询
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  /// Disposes timers and removes lifecycle observer
  /// 释放计时器并移除生命周期观察者
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Checks verification when app resumes from background
  /// 当应用从后台恢复时检查验证状态
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerification();
    }
  }

  /// Starts periodic polling to check email verification status every 5 seconds
  /// 启动每5秒检查一次电子邮件验证状态的定期轮询
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerification();
    });
  }

  /// Checks if the user's email has been verified and refreshes the token
  /// 检查用户的电子邮件是否已验证并刷新令牌
  Future<void> _checkVerification() async {
    if (_isCheckingVerification) return;
    _isCheckingVerification = true;
    try {
      final user = await _authService.reloadCurrentUser();
      if (user != null && user.emailVerified) {
        // Force token refresh so idTokenChanges stream fires
        await user.getIdToken(true);
      }
    } catch (_) {
      // Silently ignore — polling will retry
    } finally {
      _isCheckingVerification = false;
    }
  }

  /// Manually checks verification status and shows feedback to the user
  /// 手动检查验证状态并向用户显示反馈
  Future<void> _manualCheck() async {
    setState(() => _isCheckingVerification = true);
    try {
      final user = await _authService.reloadCurrentUser();
      if (user != null && user.emailVerified) {
        await user.getIdToken(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check verification status.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingVerification = false);
    }
  }

  /// Resends the verification email and starts a cooldown timer
  /// 重新发送验证邮件并启动冷却计时器
  Future<void> _resendEmail() async {
    try {
      await _authService.sendEmailVerification();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send email. Try again later.')),
        );
      }
    }
  }

  /// Starts a 60-second cooldown timer for the resend email button
  /// 启动重新发送邮件按钮的60秒冷却计时器
  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
      }
    });
  }

  /// Builds the email verification screen UI with check and resend buttons
  /// 构建带有检查和重新发送按钮的电子邮件验证屏幕界面
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final coralColor = isDark ? AppColors.darkCoral : AppColors.lightCoral;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mail icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: coralColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 40,
                    color: coralColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Check your email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'We sent a verification link to',
                  style: TextStyle(fontSize: 16, color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // "I've verified my email" button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isCheckingVerification ? null : _manualCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: coralColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCheckingVerification
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "I've verified my email",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Resend email button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _cooldownSeconds > 0 ? null : _resendEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: coralColor,
                      side: BorderSide(color: borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _cooldownSeconds > 0
                          ? 'Resend email (${_cooldownSeconds}s)'
                          : 'Resend email',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign out button
                TextButton(
                  onPressed: () => _authService.signOut(),
                  child: Text(
                    'Sign out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
