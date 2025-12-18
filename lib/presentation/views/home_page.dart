import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/friend_location_model.dart';
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
        title: Text(
          homeViewModel.warningMessage ?? '',
          style: const TextStyle(
            color: AppColors.warning,
            fontWeight: FontWeight.normal,
          ),
        ),
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
                    return _buildFriendMarker(friend);
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
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: "recenter",
        child: const Icon(Icons.my_location),
        onPressed: () {
          if (homeViewModel.currentPosition != null) {
            _mapController.move(homeViewModel.currentPosition!, 16);
            _mapController.rotate(0.0);
          }
        },
      ),
    );
  }

  Marker _buildFriendMarker(FriendLocation friend) {
    String? imageUrl = friend.selfieUrl ?? friend.photoUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = null;
    }

    String name = friend.displayName;
    if (name.isEmpty) {
      name = friend.email;
    }

    return Marker(
      point: friend.position,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () =>
            _showFriendInfo(context, name, friend.photoUrl, friend.selfieUrl),
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
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                backgroundColor: Colors.green,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(name[0])
                    : null,
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

  void _showFriendInfo(
    BuildContext context,
    String name,
    String? photoUrl,
    String? selfieUrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allow full-height sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final mq = MediaQuery.of(context);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  mq.viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Text(
                                  name[0],
                                  style: const TextStyle(fontSize: 24),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selfieUrl != null && selfieUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      // Constrain image height but allow zoom/scroll
                      SizedBox(
                        height: mq.size.height * 0.6,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InteractiveViewer(
                            panEnabled: true,
                            scaleEnabled: true,
                            child: Image.network(
                              selfieUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  height: mq.size.height * 0.4,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stack) => SizedBox(
                                height: mq.size.height * 0.3,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
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
