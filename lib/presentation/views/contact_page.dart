import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/enums/firestore_collection_enum.dart';
import '../view_models/contact_view_model.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  int _selectedIndex = 0;

  void _showAddDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un contact"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Entrez l'adresse email de la personne que vous souhaitez ajouter.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email du contact",
                  hintText: "exemple@gmail.com",
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final success = await context
                  .read<ContactViewModel>()
                  .sendFriendRequest(emailController.text);

              if (success) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text("Demande envoyée !"),
                    backgroundColor: Colors.blue,
                  ),
                );
              } else if (context.mounted) {
                final error = context.read<ContactViewModel>().errorMessage;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(error ?? "Erreur"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Envoyer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contacts"), centerTitle: false),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text("Ajouter"),
            )
          : null,

      body: IndexedStack(
        index: _selectedIndex,
        children: [_buildFriendsList(context), _buildRequestsList(context)],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Mes contacts',
          ),

          StreamBuilder<QuerySnapshot>(
            stream: context.read<ContactViewModel>().getFriendRequestsStream(),
            builder: (context, snapshotFriends) {
              return StreamBuilder<QuerySnapshot>(
                stream: context
                    .read<ContactViewModel>()
                    .getLocationRequestsStream(),
                builder: (context, snapshotLoc) {
                  int count = 0;
                  if (snapshotFriends.hasData) {
                    count += snapshotFriends.data!.docs.length;
                  }
                  if (snapshotLoc.hasData) {
                    count += snapshotLoc.data!.docs.length;
                  }

                  return NavigationDestination(
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: const Icon(Icons.notifications),
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

  Widget _buildFriendsList(BuildContext context) {
    final viewModel = context.read<ContactViewModel>();

    return StreamBuilder<List<String>>(
      stream: viewModel.getSharedWithIdsStream(),
      builder: (context, sharedSnapshot) {
        final sharedWithIds = sharedSnapshot.data ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: viewModel.getContactsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return _emptyState("Aucun contact", Icons.diversity_3);
            }

            final contacts = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contactDoc =
                    contacts[index].data() as Map<String, dynamic>;
                final friendUid = contactDoc['uid'];

                final isSharing = sharedWithIds.contains(friendUid);

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(FirestoreCollection.users.value)
                      .doc(friendUid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    String displayName = contactDoc['displayName'] ?? "Inconnu";
                    String? photoURL = contactDoc['photoURL'];

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final data =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      displayName = data['displayName'] ?? displayName;
                      photoURL = data['photoURL'] ?? photoURL;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoURL != null
                            ? NetworkImage(photoURL)
                            : null,
                        child: photoURL == null
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : "?",
                              )
                            : null,
                      ),
                      title: Text(displayName),

                      subtitle: isSharing
                          ? const Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Voit votre position",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : null,

                      trailing: IconButton(
                        icon: Icon(
                          isSharing
                              ? Icons.location_on
                              : Icons.location_on_outlined,
                          color: isSharing ? Colors.green : Colors.blue,
                        ),
                        onPressed: () => _showLocationMenu(
                          context,
                          viewModel,
                          friendUid,
                          displayName,
                          isSharing,
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

  Widget _buildRequestsList(BuildContext context) {
    final viewModel = context.read<ContactViewModel>();

    return StreamBuilder<QuerySnapshot>(
      stream: viewModel.getFriendRequestsStream(),
      builder: (context, snapshotFriends) {
        return StreamBuilder<QuerySnapshot>(
          stream: viewModel.getLocationRequestsStream(),
          builder: (context, snapshotLocation) {
            if (!snapshotFriends.hasData || !snapshotLocation.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<Map<String, dynamic>> mixedRequests = [];

            for (var doc in snapshotFriends.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              data['localType'] = 'friend';
              mixedRequests.add(data);
            }

            for (var doc in snapshotLocation.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              data['localType'] = 'location';
              mixedRequests.add(data);
            }

            // Cas vide
            if (mixedRequests.isEmpty) {
              return _emptyState(
                "Aucune demande en attente",
                Icons.notifications_off_outlined,
              );
            }

            return ListView.builder(
              itemCount: mixedRequests.length,
              itemBuilder: (context, index) {
                final request = mixedRequests[index];
                return _buildRequestCard(context, request, viewModel);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    Map<String, dynamic> request,
    ContactViewModel viewModel,
  ) {
    final uid = request['uid'];
    final name = request['displayName'] ?? "Inconnu";
    final photo = request['photoURL'];
    final type = request['localType'];

    String subtitle;
    IconData typeIcon;
    Color iconColor;

    if (type == 'location') {
      subtitle = "Veut connaître votre position";
      typeIcon = Icons.location_on;
      iconColor = Colors.blue;
    } else {
      subtitle = "Veut vous ajouter dans ses contacts";
      typeIcon = Icons.person_add;
      iconColor = Colors.orange;
    }

    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?")
                    : null,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, size: 14, color: iconColor),
                ),
              ),
            ],
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (type == 'location') {
                    viewModel.refuseLocationRequest(uid);
                  } else {
                    viewModel.refuseFriendRequest(uid);
                  }
                },
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check),
                onPressed: () {
                  if (type == 'location') {
                    viewModel.acceptLocationRequest(uid, request);
                  } else {
                    viewModel.acceptFriendRequest(uid, request);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationMenu(
    BuildContext context,
    ContactViewModel viewModel,
    String friendUid,
    String name,
    bool isSharing,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Gestion localisation avec $name",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.search, color: Colors.blue),
                title: const Text("Demander sa position"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await viewModel.sendLocationRequest(
                    friendUid,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? "Demande envoyée" : "Erreur"),
                      ),
                    );
                  }
                },
              ),

              const Divider(),

              if (isSharing)
                ListTile(
                  leading: const Icon(Icons.wrong_location, color: Colors.red),
                  title: const Text("Arrêter de partager ma position"),
                  subtitle: const Text("Il ne vous verra plus sur la carte"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await viewModel.stopSharingLocation(friendUid);
                  },
                )
              else
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text("Vous ne partagez pas votre position"),
                  subtitle: Text("Ce contact ne peut pas vous voir"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
