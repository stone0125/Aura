import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _googleSignInInitialized = false;

  // Stream of auth changes (idTokenChanges fires on verification status updates)
  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Initialize Google Sign In (v7 requires async initialization)
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    await GoogleSignIn.instance.initialize(
      serverClientId:
          '314464093764-squts7kosrc0s0kn9nsp1nshk1strk3i.apps.googleusercontent.com',
    );
    _googleSignInInitialized = true;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web Google Sign In
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        // Mobile Google Sign In (v7 API)
        await _ensureGoogleSignInInitialized();

        if (!GoogleSignIn.instance.supportsAuthenticate()) {
          throw UnsupportedError(
              'Google Sign-In not supported on this platform');
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

  // Sign in with Apple
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

  // Send email verification to current user
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Reload current user and return fresh instance
  Future<User?> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  // Sign up with Email & Password
  Future<UserCredential> signUpWithEmailPassword(
      String email, String password) async {
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

  // Sign in with Email & Password
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
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

  // Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (_) {
      // Always succeed silently to avoid leaking whether an email is registered
    }
  }

  // Sign Out
  Future<void> signOut() async {
    if (_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
