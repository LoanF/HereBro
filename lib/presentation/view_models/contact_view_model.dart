import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/di.dart';
import '../../core/services/auth_service.dart';
import '../../data/enums/firestore_collection_enum.dart';
import 'common_view_model.dart';

class ContactViewModel extends CommonViewModel {
  final IAuthService _auth = getIt<IAuthService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a stream of the current user's contacts from Firestore.
  Stream<QuerySnapshot> getContactsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection(FirestoreCollection.users.value)
        .doc(user.uid)
        .collection(FirestoreCollection.contacts.value)
        .snapshots();
  }

  /// Get a stream of the current user's friend requests from Firestore.
  Stream<QuerySnapshot> getFriendRequestsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection(FirestoreCollection.users.value)
        .doc(user.uid)
        .collection(FirestoreCollection.friendRequests.value)
        .snapshots();
  }

  Stream<QuerySnapshot> getLocationRequestsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection(FirestoreCollection.users.value)
        .doc(user.uid)
        .collection(FirestoreCollection.locationRequests.value)
        .snapshots();
  }

  Future<bool> sendFriendRequest(String email) async {
    isLoading = true;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("Non connecté");

      if (email.trim() == currentUser.email) {
        throw Exception("Impossible de s'ajouter soi-même");
      }

      final querySnapshot = await _firestore
          .collection(FirestoreCollection.users.value)
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("Aucun utilisateur trouvé.");
      }

      final targetUser = querySnapshot.docs.first;
      final targetUid = targetUser['uid'];

      final alreadyFriend = await _firestore
          .collection(FirestoreCollection.users.value)
          .doc(currentUser.uid)
          .collection(FirestoreCollection.contacts.value)
          .doc(targetUid)
          .get();

      if (alreadyFriend.exists) throw Exception("Vous êtes déjà amis.");

      final pendingRequest = await _firestore
          .collection(FirestoreCollection.users.value)
          .doc(targetUid)
          .collection(FirestoreCollection.friendRequests.value)
          .doc(currentUser.uid)
          .get();

      if (pendingRequest.exists) throw Exception("Demande déjà envoyée.");

      await _firestore
          .collection(FirestoreCollection.users.value)
          .doc(targetUid)
          .collection(FirestoreCollection.friendRequests.value)
          .doc(currentUser.uid)
          .set({
            'uid': currentUser.uid,
            'displayName': currentUser.displayName ?? 'Inconnu',
            'photoURL': currentUser.photoURL,
            'email': currentUser.email,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      isLoading = false;
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    }
  }

  Future<void> acceptFriendRequest(
    String senderUid,
    Map<String, dynamic> senderData,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();

    final senderRef = _firestore
        .collection(FirestoreCollection.users.value)
        .doc(senderUid)
        .collection(FirestoreCollection.contacts.value)
        .doc(currentUser.uid);

    batch.set(senderRef, {
      'uid': currentUser.uid,
      'displayName': currentUser.displayName,
      'photoURL': currentUser.photoURL,
      'addedAt': FieldValue.serverTimestamp(),
    });

    final myContactRef = _firestore
        .collection(FirestoreCollection.users.value)
        .doc(currentUser.uid)
        .collection(FirestoreCollection.contacts.value)
        .doc(senderUid);

    batch.set(myContactRef, {
      'uid': senderUid,
      'displayName': senderData['displayName'],
      'photoURL': senderData['photoURL'],
      'addedAt': FieldValue.serverTimestamp(),
    });

    final requestRef = _firestore
        .collection(FirestoreCollection.users.value)
        .doc(currentUser.uid)
        .collection(FirestoreCollection.friendRequests.value)
        .doc(senderUid);

    batch.delete(requestRef);

    await batch.commit();
  }

  Future<void> refuseFriendRequest(String senderUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection(FirestoreCollection.users.value)
        .doc(currentUser.uid)
        .collection(FirestoreCollection.friendRequests.value)
        .doc(senderUid)
        .delete();
  }

  Future<bool> sendLocationRequest(String friendUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("Non connecté");

      await _firestore
          .collection(FirestoreCollection.users.value)
          .doc(friendUid)
          .collection(FirestoreCollection.locationRequests.value)
          .doc(currentUser.uid)
          .set({
            'uid': currentUser.uid,
            'displayName': currentUser.displayName ?? 'Inconnu',
            'photoURL': currentUser.photoURL,
            'timestamp': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> acceptLocationRequest(
    String senderUid,
    Map<String, dynamic> requestData,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();

    final requestRef = _firestore
        .collection(FirestoreCollection.users.value)
        .doc(currentUser.uid)
        .collection(FirestoreCollection.locationRequests.value)
        .doc(senderUid);
    batch.delete(requestRef);

    final trackingRef = _firestore
        .collection(FirestoreCollection.users.value)
        .doc(senderUid)
        .collection(FirestoreCollection.tracking.value)
        .doc(currentUser.uid);
    batch.set(trackingRef, {
      'uid': currentUser.uid,
      'displayName': currentUser.displayName,
      'photoURL': currentUser.photoURL,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final sharedWithRef = _firestore
        .collection(FirestoreCollection.users.value)
        .doc(currentUser.uid)
        .collection(FirestoreCollection.sharedWith.value)
        .doc(senderUid);
    batch.set(sharedWithRef, {
      'uid': senderUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<bool> stopSharingLocation(String friendUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final batch = _firestore.batch();

      final trackingRef = _firestore
          .collection(FirestoreCollection.users.value)
          .doc(friendUid)
          .collection(FirestoreCollection.tracking.value)
          .doc(currentUser.uid);
      batch.delete(trackingRef);

      final sharedWithRef = _firestore
          .collection(FirestoreCollection.users.value)
          .doc(currentUser.uid)
          .collection(FirestoreCollection.sharedWith.value)
          .doc(friendUid);
      batch.delete(sharedWithRef);

      await batch.commit();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<void> refuseLocationRequest(String senderUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection(FirestoreCollection.users.value)
        .doc(currentUser.uid)
        .collection(
          FirestoreCollection.locationRequests.value,
        ) // On supprime de la bonne table
        .doc(senderUid)
        .delete();
  }

  Future<void> syncContactInfo(
    String contactUid,
    Map<String, dynamic> freshData,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(FirestoreCollection.users.value)
          .doc(currentUser.uid)
          .collection(FirestoreCollection.contacts.value)
          .doc(contactUid)
          .update({
            'displayName': freshData['displayName'],
            'photoURL': freshData['photoURL'],
          });
    } catch (e) {
      return;
    }
  }

  Stream<List<String>> getSharedWithIdsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(FirestoreCollection.users.value)
        .doc(user.uid)
        .collection(FirestoreCollection.sharedWith.value)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
