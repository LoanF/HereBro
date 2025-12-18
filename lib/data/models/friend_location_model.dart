import 'package:latlong2/latlong.dart';

class FriendLocation {
  final String uid;
  final LatLng position;
  final String displayName;
  final String? photoUrl;
  final String? selfieUrl;

  FriendLocation({
    required this.uid,
    required this.position,
    required this.displayName,
    this.photoUrl,
    this.selfieUrl,
  });
}
