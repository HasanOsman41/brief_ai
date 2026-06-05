import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthCubit({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        super(AuthInitial()) {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else if (state is! AuthLoading && state is! AuthError) {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> checkCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        emit(Authenticated(cred.user!));
      } else {
        emit(const AuthError('login_failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapAuthErrorKey(e.code)));
    } catch (_) {
      emit(const AuthError('login_failed'));
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    emit(AuthLoading());
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        if (displayName != null && displayName.trim().isNotEmpty) {
          await cred.user!.updateDisplayName(displayName.trim());
        }
        emit(Authenticated(cred.user!));
      } else {
        emit(const AuthError('register_failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapAuthErrorKey(e.code)));
    } catch (_) {
      emit(const AuthError('register_failed'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(Unauthenticated());
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        emit(Authenticated(cred.user!));
      } else {
        emit(const AuthError('login_failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapAuthErrorKey(e.code)));
    } catch (_) {
      emit(const AuthError('login_failed'));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      emit(PasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapAuthErrorKey(e.code)));
    } catch (_) {
      emit(const AuthError('login_failed'));
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    emit(Unauthenticated());
  }

  String _mapAuthErrorKey(String code) {
    switch (code) {
      case 'invalid-email':
        return 'invalid_email';
      case 'user-disabled':
        return 'user_disabled';
      case 'user-not-found':
        return 'user_not_found';
      case 'wrong-password':
      case 'invalid-credential':
        return 'wrong_password';
      case 'email-already-in-use':
        return 'email_already_in_use';
      case 'weak-password':
        return 'password_too_short';
      case 'operation-not-allowed':
        return 'operation_not_allowed';
      case 'network-request-failed':
        return 'network_error';
      case 'too-many-requests':
        return 'too_many_requests';
      default:
        return 'login_failed';
    }
  }
}
