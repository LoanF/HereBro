import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/app_user_model.dart';
import 'user_service.dart';

abstract class IAuthService {
  Stream<User?> get authStateChanges;

  Future<void> signInWithEmail(String email, String password);

  Future<void> signOut();

  /// Creates a new user with the provided email and password.
  /// Throws a [FirebaseAuthException] if the operation fails.
  /// @param email The email address of the new user. Trimmed and converted to lowercase.
  /// @param password The password for the new user.
  Future<void> createUserWithEmailAndPassword(String email, String password);

  User? get currentUser;
}

class AuthService implements IAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final IAppUserService _appUserService;

  AuthService(this._appUserService);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithEmail(String email, String password) async {
    email = email.trim().toLowerCase();
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password.trim(),
    );
    _appUserService.updateUser(_appUserService.currentAppUser!);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    email = email.trim().toLowerCase();
    final UserCredential cred = await _firebaseAuth
        .createUserWithEmailAndPassword(
          email: email,
          password: password.trim(),
        );

    if (cred.user == null) return;
    final user = AppUser(
      uid: cred.user!.uid,
      displayName: cred.user!.displayName ?? '',
      email: email,
      photoURL: cred.user!.photoURL ?? '',
      position: null,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
    _appUserService.createUser(user);
  }

  @override
  User? get currentUser => _firebaseAuth.currentUser;
}
