import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/themes/app_colors.dart';
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
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final user = viewModel.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.surfaceLight,
                      backgroundImage: _getProfileImage(user?.photoURL),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 4),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            _buildReadOnlyField("Email", user?.email ?? "Non renseigné", Icons.email_outlined),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Nom d'affichage",
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                  final success = await context.read<AuthViewModel>().updateProfile(
                    newName: _nameController.text,
                    newImageFile: _selectedImage,
                  );

                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profil mis à jour !"), backgroundColor: AppColors.success),
                    );
                    setState(() => _selectedImage = null);
                  }
                },
                icon: const Icon(Icons.save_rounded),
                label: Text(viewModel.isLoading ? "Enregistrement..." : "Sauvegarder"),
              ),
            ),

            const SizedBox(height: 40),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.warning),
                    title: const Text("Se déconnecter", style: TextStyle(color: AppColors.warning)),
                    onTap: () => _confirmLogout(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    title: const Text("Supprimer mon compte", style: TextStyle(color: AppColors.error)),
                    onTap: () => _showConfirmDelete(context, viewModel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextField(
      enabled: false,
      controller: TextEditingController(text: value),
      style: TextStyle(color: AppColors.textSecondary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        fillColor: AppColors.surfaceLight.withOpacity(0.1),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // Match theme
          borderSide: BorderSide(color: AppColors.surfaceLight.withOpacity(0.3)),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    // ... Logique de logout identique ...
    final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Déconnexion"),
          content: const Text("Voulez-vous vraiment quitter ?"),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text("Annuler")),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                onPressed: ()=>Navigator.pop(context,true),
                child: const Text("Déconnexion")
            )
          ],
        )
    );
    if(confirm == true && context.mounted) {
      await context.read<HomeViewModel>().stopTracking();
      if(context.mounted) await context.read<AuthViewModel>().logout();
      if(context.mounted) context.go(AppRoutes.login);
    }
  }

  void _showConfirmDelete(BuildContext context, AuthViewModel viewModel) {
    // ... Dialog de suppression ...
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Suppression définitive"),
          content: const Text("Cette action est irréversible. Toutes vos données seront effacées."),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Annuler")),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () async {
                  await viewModel.deleteAccount();
                  if(context.mounted) {
                    Navigator.pop(context);
                    context.go(AppRoutes.login);
                  }
                },
                child: const Text("Supprimer")
            )
          ],
        )
    );
  }

  ImageProvider _getProfileImage(String? firebasePhotoUrl) {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (firebasePhotoUrl != null && firebasePhotoUrl.isNotEmpty) return NetworkImage(firebasePhotoUrl);
    return const NetworkImage("https://ui-avatars.com/api/?name=User&background=random");
  }
}