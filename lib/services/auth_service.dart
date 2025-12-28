import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _googleSignInInitialized = false;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

        // Force account selection by disconnecting first
        await GoogleSignIn.instance.disconnect();

        // Authenticate - returns GoogleSignInAccount
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

  // Sign Out
  Future<void> signOut() async {
    if (_googleSignInInitialized) {
      await GoogleSignIn.instance.disconnect();
    }
    await _auth.signOut();
  }
}
