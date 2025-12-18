import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/home_view_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController.text = user?.displayName ?? "";
    _emailController.text = user?.email ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final user = viewModel.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Mon Profil"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: _getProfileImage(user?.photoURL),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
                hintText: user?.email ?? "Non renseigné",
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nom d'affichage",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        final success = await context
                            .read<AuthViewModel>()
                            .updateProfile(
                              newName: _nameController.text,
                              newImageFile: _selectedImage,
                            );

                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Profil mis à jour !"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            setState(() {
                              _selectedImage = null;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(viewModel.errorMessage!),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                icon: viewModel.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  viewModel.isLoading
                      ? "Enregistrement..."
                      : "Sauvegarder les modifications",
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            TextButton.icon(
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Déconnexion"),
                    content: const Text(
                      "Voulez-vous vraiment vous déconnecter ?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Annuler"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Se déconnecter",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await context.read<HomeViewModel>().stopTracking();

                  if (context.mounted) {
                    await context.read<AuthViewModel>().logout();
                  }

                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Se déconnecter",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getProfileImage(String? firebasePhotoUrl) {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    if (firebasePhotoUrl != null && firebasePhotoUrl.isNotEmpty) {
      return NetworkImage(firebasePhotoUrl);
    }
    return const NetworkImage(
      "https://ui-avatars.com/api/?name=User&background=random",
    );
  }
}
