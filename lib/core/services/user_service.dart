import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../data/enums/firestore_collection_enum.dart';
import '../../data/models/app_user_model.dart';

abstract class IAppUserService {
  Future<AppUser?> getUserById(String uid);

  Future<Map<String, String>> fetchUsersEmailAndUuid(String currentUid);

  Future<void> createUser(AppUser user);

  Future<void> updateUser(AppUser user);

  Future<AppUser> updateFcmToken(AppUser appUser);

  Future<void> deleteUserData(String uid);

  Future<void> fetchAndSetCurrentUser(String uid);

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
  Future<void> fetchAndSetCurrentUser(String uid) async {
    _currentAppUser = await getUserById(uid);
  }

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
    _currentAppUser ?? await fetchAndSetCurrentUser(user.uid);

    if (_currentAppUser == null) {
      throw Exception('User not found');
    }

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
  Future<void> deleteUserData(String uid) async {
    await usersCollection.doc(uid).delete();
  }

  @override
  AppUser? get currentAppUser => _currentAppUser;

  @override
  Future<Map<String, String>> fetchUsersEmailAndUuid(String currentUid) {
    return usersCollection.get().then((querySnapshot) {
      final Map<String, String> emailToUidMap = {};
      for (var doc in querySnapshot.docs) {
        final user = doc.data();
        if (user.email.isEmpty) continue;
        if (emailToUidMap.containsKey(user.email)) continue;
        if (user.uid == currentUid) continue;
        emailToUidMap[user.email] = user.uid;
      }
      return emailToUidMap;
    });
  }
}
