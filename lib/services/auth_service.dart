// =============================================================================
// auth_service.dart — Authentication Service
// 身份验证服务
//
// Handles all authentication flows using Firebase Auth:
// - Google Sign-In (OAuth2, supports web and mobile)
// - Apple Sign-In (iOS/macOS only)
// - Email/Password (sign up, sign in, password reset)
// - Email verification
// - Sign out
//
// 使用 Firebase Auth 处理所有身份验证流程：
// - Google 登录（OAuth2，支持 Web 和移动端）
// - Apple 登录（仅 iOS/macOS）
// - 邮箱/密码（注册、登录、密码重置）
// - 邮箱验证
// - 登出
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _googleSignInInitialized = false;

  /// Stream of auth state changes (fires on verification status updates)
  /// 认证状态变化的流（在验证状态更新时触发）
  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  /// Get the currently authenticated user
  /// 获取当前已认证的用户
  User? get currentUser => _auth.currentUser;

  /// Initialize Google Sign In (v7 requires async initialization)
  /// 初始化 Google 登录（v7 版本需要异步初始化）
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    await GoogleSignIn.instance.initialize(
      serverClientId:
          '314464093764-squts7kosrc0s0kn9nsp1nshk1strk3i.apps.googleusercontent.com',
    );
    _googleSignInInitialized = true;
  }

  /// Sign in with Google (OAuth2, supports web and mobile)
  /// 使用 Google 登录（OAuth2，支持 Web 和移动端）
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web Google Sign In
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        // Mobile Google Sign In (v7 API)
        await _ensureGoogleSignInInitialized();

        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          throw UnsupportedError(
            'Google Sign-In not supported on this platform',
          );
        }

        // Credential Manager handles account selection — no disconnect() needed
        final account = await GoogleSignIn.instance.authenticate();

        // Get authentication tokens from the account
        // Note: v7 only provides idToken in GoogleSignInAuthentication
        final auth = account.authentication;

        // Get access token separately if needed via authenticatedClient
        // For Firebase Auth, we can use just idToken
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: auth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in with Apple (iOS/macOS only)
  /// 使用 Apple 登录（仅限 iOS/macOS）
  Future<UserCredential?> signInWithApple() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final OAuthProvider provider = OAuthProvider('apple.com');
        final AuthCredential credential = provider.credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        return await _auth.signInWithCredential(credential);
      } else {
        throw UnimplementedError(
          'Apple Sign In is only available on iOS/macOS',
        );
      }
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    }
  }

  /// Send email verification to the current user
  /// 向当前用户发送邮箱验证邮件
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Reload current user data and return the refreshed instance
  /// 重新加载当前用户数据并返回刷新后的实例
  Future<User?> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  /// Sign up with email and password, then send verification email
  /// 使用邮箱和密码注册，然后发送验证邮件
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Auto-send verification email after account creation
      await credential.user?.sendEmailVerification();
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'An account already exists with this email. Try signing in with Google instead.',
        );
      }
      rethrow;
    }
  }

  /// Sign in with email and password
  /// 使用邮箱和密码登录
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Invalid email or password. Please try again.');
        default:
          rethrow;
      }
    }
  }

  /// Send password reset email (silently succeeds to avoid leaking info)
  /// 发送密码重置邮件（静默成功以避免泄露信息）
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (_) {
      // Always succeed silently to avoid leaking whether an email is registered
    }
  }

  /// Sign out the current user and disconnect Google Sign-In
  /// 登出当前用户并断开 Google 登录连接
  Future<void> signOut() async {
    if (_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
