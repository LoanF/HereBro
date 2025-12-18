import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di.dart';
import '../../core/services/auth_service.dart';
import '../../data/enums/firestore_collection_enum.dart';
import '../../data/models/friend_location_model.dart';
import 'common_view_model.dart';

class HomeViewModel extends CommonViewModel {
  final IAuthService _auth = getIt<IAuthService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LatLng? _currentPosition;

  LatLng? get currentPosition => _currentPosition;

  final Map<String, FriendLocation> _friendsData = {};

  List<FriendLocation> get friends => _friendsData.values.toList();

  DateTime? _lastUploadTime;
  final int _uploadIntervalSeconds = 10;

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<QuerySnapshot>? _friendsListSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  final List<StreamSubscription> _individualSubscriptions = [];

  void init() {
    if (_gpsSubscription != null) return;

    _initLocation();
    _startTrackingFriends();

    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) {
      if (status == ServiceStatus.enabled) {
        errorMessage = null;
        _initLocation();
      } else {
        errorMessage = "Le GPS a été désactivé.";
        stopTracking();
      }
    });
  }

  void retryLocation() {
    errorMessage = null;
    isLoading = true;
    _initLocation();
  }

  Stream<QuerySnapshot> getTrackingFriendsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection(FirestoreCollection.users.value)
        .doc(user.uid)
        .collection(FirestoreCollection.tracking.value)
        .snapshots();
  }

  Future<void> _initLocation() async {
    try {
      isLoading = true;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Future.delayed(const Duration(milliseconds: 500));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          errorMessage = "Le service de localisation est désactivé.";
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage = "Permission refusée. Impossible de vous localiser.";
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage =
            "Permission refusée définitivement. Allez dans les réglages.";
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition();

      _currentPosition = LatLng(position.latitude, position.longitude);

      final user = _auth.currentUser;
      if (user != null) {
        _firestore
            .collection(FirestoreCollection.users.value)
            .doc(user.uid)
            .update({
              'position': {'lat': position.latitude, 'lng': position.longitude},
              'lastUpdated': FieldValue.serverTimestamp(),
            });
      }

      errorMessage = null;
      isLoading = false;

      _gpsSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 2,
            ),
          ).listen(
            (Position newPos) {
              _currentPosition = LatLng(newPos.latitude, newPos.longitude);
              errorMessage = null;

              final now = DateTime.now();
              if (_lastUploadTime == null ||
                  now.difference(_lastUploadTime!).inSeconds >=
                      _uploadIntervalSeconds) {
                final u = _auth.currentUser;
                if (u != null) {
                  _firestore
                      .collection(FirestoreCollection.users.value)
                      .doc(u.uid)
                      .update({
                        'position': {
                          'lat': newPos.latitude,
                          'lng': newPos.longitude,
                        },
                        'lastUpdated': FieldValue.serverTimestamp(),
                      });
                  _lastUploadTime = now;
                }
              }
            },
            onError: (Object error) {
              errorMessage = "Signal GPS perdu ou interrompu.";
              isLoading = false;

              Future.delayed(const Duration(seconds: 5), () => retryLocation());
            },
            cancelOnError: false,
          );
    } catch (e) {
      errorMessage = "Erreur GPS: $e";
      isLoading = false;
    }
  }

  void _startTrackingFriends() {
    final user = _auth.currentUser;
    if (user == null) return;

    _friendsListSubscription = _firestore
        .collection(FirestoreCollection.users.value)
        .doc(user.uid)
        .collection(FirestoreCollection.tracking.value)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final friendData = doc.data();
            final friendUid = friendData['uid'];

            if (_friendsData.containsKey(friendUid)) continue;

            final sub = _firestore
                .collection(FirestoreCollection.users.value)
                .doc(friendUid)
                .snapshots()
                .listen((userDoc) {
                  if (!userDoc.exists) return;
                  final userData = userDoc.data()!;

                  if (userData.containsKey('position')) {
                    final pos = userData['position'];

                    _friendsData[friendUid] = FriendLocation(
                      uid: friendUid,
                      position: LatLng(pos['lat'], pos['lng']),
                      displayName: userData['displayName'] ?? 'Ami',
                      photoURL: userData['photoURL'],
                    );

                    notifyListeners();
                  }
                });

            _individualSubscriptions.add(sub);
          }
        });
  }

  Future<void> stopTracking() async {
    await _serviceStatusSubscription?.cancel();
    await _gpsSubscription?.cancel();
    await _friendsListSubscription?.cancel();
    for (var sub in _individualSubscriptions) {
      await sub.cancel();
    }
    _individualSubscriptions.clear();
    _friendsData.clear();
    _gpsSubscription = null;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
