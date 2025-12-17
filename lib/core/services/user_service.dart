import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../data/enums/firestore_collection_enum.dart';
import '../../data/models/app_user_model.dart';

abstract class IAppUserService {
  Future<AppUser?> getUserById(String uid);

  Future<void> createUser(AppUser user);

  Future<void> updateUser(AppUser user);

  Future<AppUser> updateFcmToken(AppUser appUser);

  AppUser? get currentAppUser;
}

class AppUserService implements IAppUserService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  late final CollectionReference<AppUser> usersCollection = _firebaseFirestore
      .collection(FirestoreCollection.users.value)
      .withConverter<AppUser>(
        fromFirestore: (snapshot, _) => AppUser.fromJson(snapshot.data()!),
        toFirestore: (user, _) => user.toJson(),
      );

  AppUser? _currentAppUser;

  @override
  Future<AppUser?> getUserById(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    return doc.data();
  }

  @override
  Future<void> createUser(AppUser user) async {
    user = await updateFcmToken(user);
    await usersCollection.doc(user.uid).set(user);
    _currentAppUser = user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    _currentAppUser ??= await getUserById(user.uid);

    if (_currentAppUser?.fcmToken == null) {
      user = await updateFcmToken(user);
    }

    if (_currentAppUser != null &&
        _currentAppUser!.toJson().toString() == user.toJson().toString()) {
      return;
    }

    await usersCollection.doc(user.uid).update(user.toJson());
  }

  @override
  Future<AppUser> updateFcmToken(AppUser appUser) async {
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken == null) return appUser;

    return AppUser(
      uid: appUser.uid,
      displayName: appUser.displayName,
      email: appUser.email,
      photoURL: appUser.photoURL,
      position: appUser.position,
      createdAt: appUser.createdAt,
      updatedAt: appUser.updatedAt,
      fcmToken: fcmToken,
    );
  }

  @override
  AppUser? get currentAppUser => _currentAppUser;
}
