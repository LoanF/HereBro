import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/themes/app_colors.dart';
import '../../data/enums/firestore_collection_enum.dart';
import '../view_models/contact_view_model.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  int _selectedIndex = 0;
  final emailController = TextEditingController();

  void _showAddDialog(BuildContext context, ContactViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Ajouter un contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Entrez l'email de votre ami pour lui envoyer une demande.",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "exemple@email.com",
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: viewModel.isLoading
                ? null
                : () async {
              final success = await viewModel.sendFriendRequest(emailController.text);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  emailController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Demande envoyée !"), backgroundColor: AppColors.success),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(viewModel.errorMessage ?? "Erreur"), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: viewModel.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Envoyer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactViewModel = context.watch<ContactViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Mes Relations"),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, contactViewModel),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text("Ajouter"),
      )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildContactList(context, contactViewModel),
            _buildRequestsList(context, contactViewModel),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
            label: 'Contacts',
          ),
          StreamBuilder<QuerySnapshot>(
            stream: contactViewModel.getFriendRequestsStream(),
            builder: (context, snapshotFriends) {
              return StreamBuilder<QuerySnapshot>(
                stream: contactViewModel.getLocationRequestsStream(),
                builder: (context, snapshotLoc) {
                  int count = (snapshotFriends.data?.docs.length ?? 0) + (snapshotLoc.data?.docs.length ?? 0);
                  return NavigationDestination(
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      backgroundColor: AppColors.error,
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      backgroundColor: AppColors.error,
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                    ),
                    label: 'Demandes',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(BuildContext context, ContactViewModel viewModel) {
    return StreamBuilder<List<String>>(
      stream: viewModel.getSharedWithIdsStream(),
      builder: (context, sharedSnapshot) {
        final sharedWithIds = sharedSnapshot.data ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: viewModel.getContactsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) return _emptyState("Aucun contact", Icons.group_off_rounded);

            final contacts = snapshot.data!.docs;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contactDoc = contacts[index].data() as Map<String, dynamic>;
                final friendUid = contactDoc['uid'];
                final isSharing = sharedWithIds.contains(friendUid);

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection(FirestoreCollection.users.value).doc(friendUid).snapshots(),
                  builder: (context, userSnapshot) {
                    String displayName = contactDoc['displayName'] ?? "";
                    String? photoURL = contactDoc['photoURL'];

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final data = userSnapshot.data!.data() as Map<String, dynamic>;
                      displayName = data['displayName'] ?? displayName;
                      photoURL = data['photoURL'] ?? photoURL;
                      if (displayName.isEmpty) displayName = data['email'] ?? "Inconnu";
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSharing ? AppColors.success : Colors.transparent,
                                width: 2
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage: photoURL != null && photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                            backgroundColor: AppColors.surfaceLight,
                            child: photoURL == null ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "?") : null,
                          ),
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        subtitle: isSharing
                            ? const Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: AppColors.success),
                            SizedBox(width: 6),
                            Text("Localisation active", style: TextStyle(color: AppColors.success, fontSize: 12)),
                          ],
                        )
                            : Text("Localisation masquée", style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                          color: AppColors.surfaceLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () => _showLocationMenu(context, viewModel, friendUid, displayName, isSharing),
                              child: Row(
                                children: [
                                  Icon(isSharing ? Icons.location_off_rounded : Icons.location_on_rounded,
                                      color: isSharing ? AppColors.warning : AppColors.success, size: 20),
                                  const SizedBox(width: 12),
                                  Text(isSharing ? "Arrêter le partage" : "Partager ma position"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () => viewModel.removeContact(friendUid),
                              child: const Row(
                                children: [
                                  Icon(Icons.person_remove_rounded, color: AppColors.error, size: 20),
                                  SizedBox(width: 12),
                                  Text("Supprimer", style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList(BuildContext context, ContactViewModel viewModel) {
    return StreamBuilder<QuerySnapshot>(
        stream: viewModel.getFriendRequestsStream(),
        builder: (context, snapshotFriends) {
          return StreamBuilder<QuerySnapshot>(
              stream: viewModel.getLocationRequestsStream(),
              builder: (context, snapshotLoc) {
                final List<Map<String, dynamic>> mixedRequests = [];

                if (snapshotFriends.hasData) {
                  for (var doc in snapshotFriends.data!.docs) {
                    var d = doc.data() as Map<String, dynamic>;
                    d['localType'] = 'friend'; mixedRequests.add(d);
                  }
                }
                if (snapshotLoc.hasData) {
                  for (var doc in snapshotLoc.data!.docs) {
                    var d = doc.data() as Map<String, dynamic>;
                    d['localType'] = 'location'; mixedRequests.add(d);
                  }
                }

                if (mixedRequests.isEmpty) return _emptyState("Aucune demande", Icons.notifications_none);

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: mixedRequests.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = mixedRequests[index];
                    final bool isLoc = req['localType'] == 'location';

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isLoc ? AppColors.primary.withOpacity(0.5) : AppColors.warning.withOpacity(0.5)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: req['photoURL'] != null ? NetworkImage(req['photoURL']) : null,
                                child: req['photoURL'] == null ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(req['displayName'] ?? req['email'] ?? "Inconnu",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(isLoc ? "Souhaite voir votre position" : "Demande d'ami",
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isLoc ? AppColors.primary : AppColors.warning).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLoc ? Icons.location_on : Icons.person_add,
                                  color: isLoc ? AppColors.primary : AppColors.warning,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => isLoc ? viewModel.refuseLocationRequest(req['uid']) : viewModel.refuseFriendRequest(req['uid']),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.surfaceLight)),
                                  child: const Text("Refuser", style: TextStyle(color: AppColors.textSecondary)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => isLoc ? _showAcceptLocationMenu(context, viewModel, req, req['uid']) : viewModel.acceptFriendRequest(req['uid'], req),
                                  style: FilledButton.styleFrom(backgroundColor: isLoc ? AppColors.primary : AppColors.success),
                                  child: const Text("Accepter"),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              }
          );
        }
    );
  }

  // --- MODALS CORRIGÉES ---

  void _showLocationMenu(BuildContext context, ContactViewModel vm, String uid, String name, bool isSharing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea( // IMPORTANT : SafeArea ici
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16), // Espace après la poignée

            ListTile(
              leading: const Icon(Icons.share_location_rounded, color: AppColors.primary),
              title: const Text("Demander sa position"),
              onTap: () { Navigator.pop(ctx); vm.sendLocationRequest(uid); },
            ),
            if (isSharing)
              ListTile(
                leading: const Icon(Icons.visibility_off_rounded, color: AppColors.warning),
                title: const Text("Arrêter le partage"),
                onTap: () { Navigator.pop(ctx); vm.stopSharingLocation(uid); },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showAcceptLocationMenu(BuildContext context, ContactViewModel vm, Map<String, dynamic> req, String uid) async {
    await showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea( // IMPORTANT : Ajout du SafeArea manquant
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),

              ListTile(
                  leading: const Icon(Icons.check_circle, color: AppColors.success),
                  title: const Text("Partager uniquement la position"),
                  onTap: () { Navigator.pop(ctx); vm.acceptLocationRequest(uid, req, false); }
              ),
              ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text("Partager position + Photo"),
                  onTap: () { Navigator.pop(ctx); vm.acceptLocationRequest(uid, req, true); }
              ),
              const SizedBox(height: 16),
            ],
          ),
        )
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: AppColors.surfaceLight),
      const SizedBox(height: 16),
      Text(text, style: TextStyle(color: AppColors.textSecondary))
    ]));
  }
}