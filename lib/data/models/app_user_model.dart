import 'package:cloud_firestore/cloud_firestore.dart';

import 'position_model.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final Position? position;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.position,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'],
      displayName: json['displayName'],
      email: json['email'],
      photoURL: json['photoURL'],
      position: json['position'] != null
          ? Position.fromJson(json['position'])
          : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'position': position?.toJson(),
      'createdAt': createdAt,
      'updatedAt': Timestamp.now(),
      'fcmToken': fcmToken,
    };
  }

  AppUser? copyWith({
    String? displayName,
    String? photoURL,
    Position? position,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoURL: photoURL ?? this.photoURL,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: Timestamp.now(),
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
