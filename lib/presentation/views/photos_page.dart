import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(title: const Text('Photos partagées')),
      body: FutureBuilder<List<Photo>?>(
        future: viewModel.fetchSharedPhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(viewModel.errorMessage!));
          }

          final photos = snapshot.data ?? [];

          if (photos.isEmpty) {
            return const Center(child: Text('Aucune photo partagée.'));
          }

          // Display cards with image and sender info
          // (displayname or email if displayname is null or empty)
          // photo
          // delete button
          return ListView.builder(
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRect(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Image.network(
                            photo.downloadUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 200,
                                child: Center(child: Icon(Icons.broken_image)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Envoyé à: ${photo.sender.displayName.isNotEmpty == true ? photo.sender.displayName : photo.sender.email}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                                await viewModel.deletePhoto(photo.storagePath);
                                setState(() {});
                              },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text(
                          viewModel.isLoading ? 'Suppression' : 'Supprimer',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
