import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

abstract class ISelfieService {
  Future<String?> captureSelfie(String currentUid, String senderUid);
  Future<String?> getSelfieUrl(String currentUid, String senderUid);
  Future<void> deleteCapture(String currentUid, String senderUid);
}

class SelfieService implements ISelfieService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> captureSelfie(String currentUid, String senderUid) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );

    if (photo == null) return null;

    final File file = File(photo.path);
    final String fileName = 'selfies/$currentUid/$senderUid.jpg';

    final UploadTask uploadTask = FirebaseStorage.instance
        .ref()
        .child(fileName)
        .putFile(file);

    final TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  @override
  Future<String?> getSelfieUrl(String currentUid, String senderUid) async {
    final String fileName = 'selfies/$currentUid/$senderUid.jpg';
    final Reference ref = FirebaseStorage.instance.ref().child(fileName);

    try {
      final String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteCapture(String currentUid, String senderUid) async {
    final String fileName = 'selfies/$currentUid/$senderUid.jpg';
    final Reference ref = FirebaseStorage.instance.ref().child(fileName);
    if ((await ref.listAll()).items.isEmpty) return;
    await ref.delete();
  }
}
