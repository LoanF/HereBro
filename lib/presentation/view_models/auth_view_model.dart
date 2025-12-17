import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/di.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../data/enums/auth_exception_code_enum.dart';
import '../../data/enums/storage_child_enum.dart';
import '../../data/models/app_user_model.dart';
import 'common_view_model.dart';

class AuthViewModel extends CommonViewModel {
  final IAuthService _auth = getIt<IAuthService>();
  final IAppUserService _appUserService = getIt<IAppUserService>();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  Future<bool> login(String email, String password) async {
    isLoading = true;

    try {
      await _auth.signInWithEmail(email, password);
      isLoading = false;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = AuthExceptionCode.getMessageFromCode(e.code);
      return false;
    } catch (e) {
      errorMessage = "Une erreur inconnue est survenue.";
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    isLoading = true;

    try {
      await _auth.createUserWithEmailAndPassword(email, password);
      isLoading = false;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = AuthExceptionCode.getMessageFromCode(e.code);
      return false;
    } catch (e) {
      errorMessage = "Une erreur inconnue est survenue.";
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> updateProfile({
    required String newName,
    File? newImageFile,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      String? photoUrl;

      if (newImageFile != null) {
        final ref = _storage
            .ref()
            .child(StorageChild.profileImages.value)
            .child('${user.uid}.jpg');
        await ref.putFile(newImageFile);
        photoUrl = await ref.getDownloadURL();
        await user.updatePhotoURL(photoUrl);
      }

      if (newName != user.displayName) {
        await user.updateDisplayName(newName);
      }

      AppUser? updatedAppUser;

      if (newName.isNotEmpty) {
        updatedAppUser = _appUserService.currentAppUser!.copyWith(
          displayName: newName,
        );
      }
      if (photoUrl != null) {
        updatedAppUser = _appUserService.currentAppUser!.copyWith(
          photoURL: photoUrl,
        );
      }

      if (updatedAppUser != null) {
        _appUserService.updateUser(updatedAppUser);
      }

      await user.reload();

      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = "Erreur mise à jour : $e";
      return false;
    }
  }
}
