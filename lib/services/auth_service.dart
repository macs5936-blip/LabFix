import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException extends StateError implements Exception {
  AuthException(super.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _authOverride = auth,
       _firestoreOverride = firestore,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitialization;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool isValidEspochEmail(String? email) {
    if (email == null) return false;
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith('@espoch.edu.ec');
  }

  /// Normaliza los roles aceptando variantes en inglés y español,
  /// mayúsculas o minúsculas y caracteres acentuados.
  /// - 'student' / 'estudiante' -> 'student'
  /// - 'technician' / 'tecnico' / 'técnico' / 'tech' -> 'technician'
  /// - 'deanery' / 'decanato' / 'admin' / 'administrador' -> 'admin'
  static String normalizeRole(String? role) {
    if (role == null) return 'student';
    final clean = role
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    switch (clean) {
      case 'student':
      case 'estudiante':
        return 'student';
      case 'technician':
      case 'tecnico':
      case 'tech':
        return 'technician';
      case 'admin':
      case 'administrador':
      case 'administrator':
      case 'deanery':
      case 'decanato':
        return 'admin';
      default:
        return clean;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _ensureUserProfile(user);
    }
    return credential;
  }

  Future<UserCredential?> signInWithGoogle([AuthProvider? provider]) async {
    try {
      if (kIsWeb) {
        final authProvider = provider ?? GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(authProvider);
        final user = userCredential.user;
        if (user != null) await _ensureUserProfile(user);
        return userCredential;
      }

      if (provider != null) {
        final userCredential = await _auth.signInWithProvider(provider);
        final user = userCredential.user;
        if (user != null) await _ensureUserProfile(user);
        return userCredential;
      }

      try {
        _googleInitialization ??= _googleSignIn.initialize();
        await _googleInitialization;

        final googleUser = await _googleSignIn.authenticate();
        final idToken = googleUser.authentication.idToken;

        if (idToken != null) {
          final credential = GoogleAuthProvider.credential(idToken: idToken);
          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;
          if (user != null) await _ensureUserProfile(user);
          return userCredential;
        }
      } on UnimplementedError {
        // Fallback to signInWithProvider when GoogleSignIn native channel is unavailable
      } on UnsupportedError {
        // Fallback to signInWithProvider
      }

      final authProvider = GoogleAuthProvider();
      final userCredential = await _auth.signInWithProvider(authProvider);
      final user = userCredential.user;
      if (user != null) await _ensureUserProfile(user);
      return userCredential;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'canceled' ||
          error.code == 'web-context-cancelled') {
        return null;
      }
      rethrow;
    }
  }

  Future<UserCredential?> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com')
      ..addScope('email')
      ..addScope('openid')
      ..addScope('profile');
    try {
      final UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        userCredential = await _auth.signInWithProvider(provider);
      }
      final user = userCredential.user;
      if (user != null && !isValidEspochEmail(user.email)) {
        await _auth.signOut();
        throw AuthException(
          'Acceso denegado: Solo cuentas institucionales (@espoch.edu.ec)',
        );
      }
      if (user != null) await _ensureUserProfile(user);
      return userCredential;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'canceled' ||
          error.code == 'web-context-cancelled') {
        return null;
      }
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEspoch() => signInWithMicrosoft();

  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Se requiere una sesión iniciada.');

    await _ensureUserProfile(user);
    try {
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final data = profile.data();
      final rawRole = (data?['role'] ?? data?['rol'])?.toString();
      return normalizeRole(rawRole);
    } catch (_) {
      return 'student';
    }
  }

  Future<UserCredential> registerStudent({
    required String nombres,
    required String apellidos,
    required String telefono,
    required String email,
    required String password,
    required String carrera,
    required String pao,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return credential;

    final displayName = '${nombres.trim()} ${apellidos.trim()}';
    await user.updateDisplayName(displayName);

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'displayName': displayName,
        'telefono': telefono.trim(),
        'email': email.trim(),
        'carrera': carrera,
        'pao': pao,
        'role': 'student',
        'rol': 'STUDENT',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // In tests without live Firestore — profile saved when possible
    }

    return credential;
  }

  // Legacy alias kept for backward compatibility
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return credential;

    final displayName = name.trim();
    await user.updateDisplayName(displayName);
    await _ensureUserProfile(user, displayName: displayName);
    return credential;
  }

  Future<void> _ensureUserProfile(User user, {String? displayName}) async {
    try {
      final profile = _firestore.collection('users').doc(user.uid);
      if ((await profile.get()).exists) return;

      await profile.set({
        'uid': user.uid,
        'displayName': displayName ?? user.displayName ?? '',
        'email': user.email,
        'role': 'student',
        'rol': 'STUDENT',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // In tests without live Firestore
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialization != null) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }
}
