import 'package:firebase_storage/firebase_storage.dart';

import '../../core/di.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../data/models/app_user_model.dart';
import '../../data/models/photo_model.dart';
import 'common_view_model.dart';

class PhotosViewModel extends CommonViewModel {
  PhotosViewModel() : super();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final IAuthService _authService = getIt<IAuthService>();
  final IAppUserService userService = getIt<IAppUserService>();

  Future<List<Photo>>? fetchSharedPhotos() async {
    // isLoading = true;

    if (_authService.currentUser == null) {
      // errorMessage = 'Utilisateur non authentifié.';
      return [];
    }

    try {
      final ListResult listResult = await _storage
          .ref(getSelfieStoragePath(_authService.currentUser!.uid))
          .listAll();
      final List<Photo> photos = [];
      for (final Reference ref in listResult.items) {
        final String downloadUrl = await ref.getDownloadURL();
        final AppUser senderUser = await getSenderAppUser(
          ref.name.split('.')[0],
        );
        photos.add(
          Photo(
            downloadUrl: downloadUrl,
            storagePath: ref.fullPath,
            sender: senderUser,
          ),
        );
      }
      print(photos);
      return photos;
    } catch (e) {
      // errorMessage = 'Erreur lors de la récupération des photos partagées.';
      return [];
    }
  }

  Future<void> deletePhoto(String photoPath) async {
    isLoading = true;
    try {
      final Reference ref = _storage.ref(photoPath);
      await ref.delete();
    } catch (e) {
      errorMessage = 'Erreur lors de la suppression de la photo.';
    } finally {
      isLoading = false;
    }
  }

  Future<AppUser> getSenderAppUser(String senderUid) async {
    final AppUser? senderUser = await userService.getUserById(senderUid);
    if (senderUser == null) {
      throw Exception('Utilisateur non trouvé');
    }
    return senderUser;
  }

  String getSelfieStoragePath(String currentUid) {
    return 'selfies/$currentUid';
  }

  String get currentUserId {
    return _authService.currentUser?.uid ?? '';
  }
}
