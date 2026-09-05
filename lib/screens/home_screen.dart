import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService firestoreService =
      FirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        elevation: 0,
        title: const Text(
          "NChat",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 10),
                    Text("Settings"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // =====================================================
      // USERS
      // =====================================================

      body: FutureBuilder<String>(
        future:
            firestoreService.getCurrentUserId(),
        builder:
            (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final currentUserId =
              userSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream:
                firestoreService.getUsers(),
            builder:
                (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "Something went wrong",
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final users =
                  snapshot.data!.docs.where(
                (doc) {
                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  return data["userId"] !=
                      currentUserId;
                },
              ).toList();

              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    "No users found",
                  ),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder:
                    (context, index) {
                  final data =
                      users[index].data()
                          as Map<String, dynamic>;

                  return ChatTile(
                    userId:
                        data["userId"] ?? "",
                    name:
                        data["name"] ?? "",
                    message:
                        data["about"] ?? "",
                    photoUrl:
                        data["photoUrl"] ?? "",
                  );
                },
              );
            },
          );
        },
      ),

      // =====================================================
      // FLOATING ACTION BUTTON
      // =====================================================

      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            AppColors.primary,
        onPressed: () {},
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
    );
  }
}

// =========================================================
// CHAT TILE
// =========================================================

class ChatTile extends StatelessWidget {
  final String userId;
  final String name;
  final String message;
  final String photoUrl;

  const ChatTile({
    super.key,
    required this.userId,
    required this.name,
    required this.message,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final textTheme =
        theme.textTheme;

    return ListTile(
      // ===================================================
      // PROFILE PHOTO
      // ===================================================

      leading: CircleAvatar(
        radius: 28,
        backgroundImage:
            photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
        child: photoUrl.isEmpty
            ? const Icon(
                Icons.person,
              )
            : null,
      ),

      // ===================================================
      // USER NAME
      // ===================================================

      title: Text(
        name,
        style: textTheme.titleMedium?.copyWith(
          fontWeight:
              FontWeight.bold,
          fontSize: 17,
        ),
      ),

      // ===================================================
      // ABOUT / MESSAGE
      // ===================================================

      subtitle: Text(
        message,
        style:
            textTheme.bodyMedium,
      ),

      // ===================================================
      // OPEN CHAT
      // ===================================================

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              userName: name,
              receiverId: userId,
            ),
          ),
        );
      },
    );
  }
}