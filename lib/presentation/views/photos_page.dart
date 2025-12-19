import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/themes/app_colors.dart';
import '../../data/models/photo_model.dart';
import '../view_models/photos_view_model.dart';

class PhotosPage extends StatefulWidget {
  const PhotosPage({super.key});

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PhotosViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Photos partagées'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withOpacity(0.9),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: FutureBuilder<List<Photo>?>(
            future: viewModel.fetchSharedPhotos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return _buildEmptyState(
                  viewModel.errorMessage ?? "Une erreur est survenue",
                  Icons.error_outline_rounded,
                );
              }

              final photos = snapshot.data ?? [];

              if (photos.isEmpty) {
                return _buildEmptyState(
                  'Aucune photo partagée pour le moment.',
                  Icons.photo_library_outlined,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: photos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  final String senderName = photo.sender.displayName.isNotEmpty
                      ? photo.sender.displayName
                      : photo.sender.email;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Image.network(
                              photo.downloadUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 250,
                                  color: AppColors.surfaceLight.withValues(alpha: 0.2),
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stack) => Container(
                                height: 200,
                                color: AppColors.surfaceLight.withValues(alpha: 0.2),
                                child: const Icon(Icons.broken_image_rounded,
                                    size: 48, color: AppColors.textTertiary),
                              ),
                            ),
                          ),
                        ),

                        // Infos et Actions
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Envoyé à",
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      senderName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              IconButton.filledTonal(
                                onPressed: viewModel.isLoading
                                    ? null
                                    : () async {
                                  await viewModel.deletePhoto(photo.storagePath);
                                  setState(() {});
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                  foregroundColor: AppColors.error,
                                ),
                                icon: viewModel.isLoading
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.error,
                                  ),
                                )
                                    : const Icon(Icons.delete_outline_rounded),
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
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.surfaceLight),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}