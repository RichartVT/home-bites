import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final GoogleSignIn _googleSignIn;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    // Configurar GoogleSignIn (no necesitamos clientId aquí para iOS)
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

    // Escuchar cambios de usuario
    _auth.userChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  Future<void> signInWithGoogle() async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Error de autenticación.';
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado.';
      if (kDebugMode) {
        print('Error genérico en signInWithGoogle: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error al cerrar sesión: $e');
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
