import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ⚠️ Substitua com seu LinkedIn Client ID (sem secret - usamos PKCE)
const String _linkedInClientId = 'YOUR_LINKEDIN_CLIENT_ID';
// URL de redirecionamento registrada no app LinkedIn
const String _linkedInRedirectUri =
    'https://azuos01.github.io/life-balance-tracker/';

class AuthResult {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String provider;

  const AuthResult({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    required this.provider,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── GOOGLE ──────────────────────────────────────────────────────────────
  Future<AuthResult?> signInWithGoogle() async {
    try {
      UserCredential cred;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        cred = await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }
      return _fromFirebaseUser(cred.user, 'google');
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  // ─── GITHUB ──────────────────────────────────────────────────────────────
  Future<AuthResult?> signInWithGitHub() async {
    try {
      final provider = GithubAuthProvider()..addScope('user:email');
      UserCredential cred;
      if (kIsWeb) {
        cred = await _auth.signInWithPopup(provider);
      } else {
        cred = await _auth.signInWithProvider(provider);
      }
      return _fromFirebaseUser(cred.user, 'github');
    } catch (e) {
      debugPrint('GitHub Sign-In error: $e');
      rethrow;
    }
  }

  // ─── FACEBOOK ────────────────────────────────────────────────────────────
  Future<AuthResult?> signInWithFacebook() async {
    try {
      final provider = FacebookAuthProvider()
        ..addScope('email')
        ..addScope('public_profile');
      UserCredential cred;
      if (kIsWeb) {
        cred = await _auth.signInWithPopup(provider);
      } else {
        cred = await _auth.signInWithProvider(provider);
      }
      return _fromFirebaseUser(cred.user, 'facebook');
    } catch (e) {
      debugPrint('Facebook Sign-In error: $e');
      rethrow;
    }
  }

  // ─── LINKEDIN (OAuth2 PKCE) ───────────────────────────────────────────────
  //
  // LinkedIn usa Authorization Code + PKCE.
  // A troca do code por token acontece via POST ao endpoint do LinkedIn.
  // NOTA: o endpoint de token do LinkedIn tem restrição de CORS em browsers.
  // Para produção, use uma Firebase Function como proxy.
  // Este fluxo funciona em apps mobile (não-web) sem CORS issues.
  //
  Future<AuthResult?> signInWithLinkedIn() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateState();

    // Salva state e verifier para usar após o redirect
    _pendingLinkedInState = state;
    _pendingLinkedInVerifier = codeVerifier;

    final authUri = Uri.https('www.linkedin.com', '/oauth/v2/authorization', {
      'response_type': 'code',
      'client_id': _linkedInClientId,
      'redirect_uri': _linkedInRedirectUri,
      'scope': 'openid profile email',
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    if (await canLaunchUrl(authUri)) {
      await launchUrl(authUri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Não foi possível abrir o LinkedIn');
    }
    // O callback é tratado em handleLinkedInCallback()
    return null;
  }

  // Chamado quando o app recebe o redirect do LinkedIn (deep link / URL)
  Future<AuthResult?> handleLinkedInCallback(String code, String state) async {
    if (state != _pendingLinkedInState) {
      throw Exception('LinkedIn OAuth: state inválido (possível CSRF)');
    }

    final verifier = _pendingLinkedInVerifier!;
    _pendingLinkedInState = null;
    _pendingLinkedInVerifier = null;

    // Troca o code pelo access token
    final tokenResponse = await http.post(
      Uri.https('www.linkedin.com', '/oauth/v2/accessToken'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _linkedInRedirectUri,
        'client_id': _linkedInClientId,
        'code_verifier': verifier,
      },
    );

    if (tokenResponse.statusCode != 200) {
      throw Exception('LinkedIn token exchange falhou: ${tokenResponse.body}');
    }

    final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final accessToken = tokenData['access_token'] as String;

    // Busca perfil do usuário via OIDC userinfo endpoint
    final userInfoResponse = await http.get(
      Uri.parse('https://api.linkedin.com/v2/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final userInfo =
        jsonDecode(userInfoResponse.body) as Map<String, dynamic>;

    return AuthResult(
      uid: 'linkedin_${userInfo['sub']}',
      name: userInfo['name'] as String?,
      email: userInfo['email'] as String?,
      photoUrl: userInfo['picture'] as String?,
      provider: 'linkedin',
    );
  }

  // Pending LinkedIn state (in-memory for simplicity)
  String? _pendingLinkedInState;
  String? _pendingLinkedInVerifier;

  // ─── SIGN OUT ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  AuthResult? _fromFirebaseUser(User? user, String provider) {
    if (user == null) return null;
    return AuthResult(
      uid: user.uid,
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      provider: provider,
    );
  }

  String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(128, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _generateState() {
    final rng = Random.secure();
    return List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
  }
}
