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

  late HomeViewModel _homeViewModel;
  bool _hasCenteredOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().init();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeViewModel = context.read<HomeViewModel>();
  }

  @override
  void dispose() {
    _homeViewModel.stopTracking();

    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On continue d'utiliser watch() ici pour écouter les changements
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
        backgroundColor: Colors.transparent,
        leading: _buildActionButton(Icons.photo_library, () => context.push(AppRoutes.photos)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
        elevation: 0,
        title: homeViewModel.warningMessage != null
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.warning.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                homeViewModel.warningMessage!,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
            : null,
        actions: [
          _buildActionButton(Icons.people_alt_rounded, () => context.push(AppRoutes.contact)),
          const SizedBox(width: 8),
          _buildActionButton(Icons.settings_rounded, () => context.push(AppRoutes.settings)),
          const SizedBox(width: 16),
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
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text("Recherche GPS...", style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),

          if (homeViewModel.errorMessage != null)
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_disabled_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      homeViewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () async => await Geolocator.openLocationSettings(),
                          child: const Text("Paramètres"),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () => context.read<HomeViewModel>().retryLocation(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("Réessayer"),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: "recenter",
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.my_location_rounded),
        onPressed: () {
          if (homeViewModel.currentPosition != null) {
            _mapController.move(homeViewModel.currentPosition!, 16);
            _mapController.rotate(0.0);
          }
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsetsGeometry.directional(start: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.textPrimary),
        tooltip: "Menu",
      ),
    );
  }

  Marker _buildFriendMarker(FriendLocation friend) {
    String? imageUrl = friend.selfieUrl ?? friend.photoUrl;
    String name = friend.displayName.isNotEmpty ? friend.displayName : friend.email;

    return Marker(
      point: friend.position,
      width: 60,
      height: 70,
      child: GestureDetector(
        onTap: () => _showFriendInfo(context, name, friend.photoUrl, friend.selfieUrl),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 8),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
            ClipPath(
              clipper: _TriangleClipper(),
              child: Container(color: AppColors.accent, width: 10, height: 8),
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
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
            ],
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.navigation_rounded, size: 12, color: Colors.white),
        ),
      ],
    );
  }

  void _showFriendInfo(BuildContext context, String name, String? photoUrl, String? selfieUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black45)],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: AppColors.background,
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                child: photoUrl == null
                                    ? Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(fontSize: 24))
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "À proximité",
                                    style: TextStyle(color: AppColors.success, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        if (selfieUrl != null && selfieUrl.isNotEmpty) ...[
                          const Text("Dernier Selfie", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Image.network(
                                selfieUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loading) {
                                  if (loading == null) return child;
                                  return Container(
                                    color: AppColors.surfaceLight,
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                              ),
                            ),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.camera_alt_outlined, color: AppColors.textTertiary, size: 32),
                                  SizedBox(height: 8),
                                  Text("Pas de selfie récent", style: TextStyle(color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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