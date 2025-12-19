import 'app_user_model.dart';

class Photo {
  final String downloadUrl;
  final String storagePath;
  final AppUser sender;

  Photo({
    required this.downloadUrl,
    required this.storagePath,
    required this.sender,
  });
}
