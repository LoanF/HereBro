import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../view_models/home_view_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  bool _hasCenteredOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
  }

  @override
  void dispose() {
    context.read<HomeViewModel>().stopTracking();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();

    if (homeViewModel.currentPosition != null && !_hasCenteredOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(homeViewModel.currentPosition!, 16.0);
        _hasCenteredOnce = true;
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.contact),
            icon: const Icon(Icons.people),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(48.8566, 2.3522),
              initialZoom: 16.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.herebro',
              ),

              MarkerLayer(
                markers: [
                  if (homeViewModel.currentPosition != null)
                    Marker(
                      point: homeViewModel.currentPosition!,
                      width: 60,
                      height: 60,
                      child: _buildMyMarker(),
                    ),

                  ...homeViewModel.friends.map((friend) {
                    return _buildFriendMarker(
                      friend.uid,
                      friend.position,
                      friend.displayName,
                      friend.photoURL,
                    );
                  }),
                ],
              ),
            ],
          ),

          if (homeViewModel.isLoading)
            const Align(
              alignment: Alignment.center,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Recherche GPS..."),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (homeViewModel.errorMessage != null)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          homeViewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton(
                              style: const ButtonStyle(
                                foregroundColor: WidgetStatePropertyAll(
                                  Colors.lightBlue,
                                ),
                                backgroundColor: WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                              ),
                              onPressed: () async {
                                await Geolocator.openLocationSettings();
                              },
                              child: const Text("Paramètres"),
                            ),
                            const SizedBox(width: 16),
                            FilledButton.icon(
                              onPressed: () {
                                context.read<HomeViewModel>().retryLocation();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("Réessayer"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 20,
            right: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 30, right: 20),
              child: FloatingActionButton(
                heroTag: "recenter",
                child: const Icon(Icons.my_location),
                onPressed: () {
                  if (homeViewModel.currentPosition != null) {
                    _mapController.move(homeViewModel.currentPosition!, 16);
                    _mapController.rotate(0.0);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildFriendMarker(
    String uid,
    LatLng position,
    String name,
    String? photoUrl,
  ) {
    return Marker(
      point: position,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _showFriendInfo(context, name, photoUrl),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  const BoxShadow(blurRadius: 4, color: Colors.black26),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                backgroundColor: Colors.green,
                child: photoUrl == null ? Text(name[0]) : null,
              ),
            ),
            ClipPath(
              clipper: _TriangleClipper(),
              child: Container(color: Colors.white, width: 8, height: 6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(blurRadius: 3)],
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFF4285F4),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  void _showFriendInfo(BuildContext context, String name, String? photoUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Text(name[0], style: const TextStyle(fontSize: 24))
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
