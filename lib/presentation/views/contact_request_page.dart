import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/contact_view_model.dart';

class ContactRequestPage extends StatelessWidget {
  const ContactRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Demandes de contact")),
      body: _buildRequestsList(context),
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

            if (mixedRequests.isEmpty) {
              return _emptyState(
                "Aucune demande en attente",
                Icons.notifications_off_outlined,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
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
    String name = request['displayName'] ?? "";
    final photo = request['photoURL'];
    final type = request['localType'];

    if (name.isEmpty) {
      name = request['email'] ?? "Inconnu";
    }

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
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?")
                    : null,
              ),
              Positioned(
                bottom: -4,
                right: -4,
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
                  backgroundColor: Colors.red.withOpacity(0.1),
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
          Icon(icon, size: 60, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
