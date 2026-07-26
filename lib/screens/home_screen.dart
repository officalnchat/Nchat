import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final FirestoreService firestoreService = FirestoreService();

  String? currentUserId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    initializePresence();
  }

  Future<void> initializePresence() async {
    currentUserId =
        await firestoreService.getCurrentUserId();

    await firestoreService.setUserOnline(
      currentUserId!,
    );
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {
    if (currentUserId == null) return;

    if (state == AppLifecycleState.resumed) {
      firestoreService.setUserOnline(
        currentUserId!,
      );
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      firestoreService.setUserOffline(
        currentUserId!,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (currentUserId != null) {
      firestoreService.setUserOffline(
        currentUserId!,
      );
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: FutureBuilder<String>(
        future: firestoreService.getCurrentUserId(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final currentUserId =
              userSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getUsers(),
            builder: (context, snapshot) {
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
                  snapshot.data!.docs.where((doc) {
                final data =
                    doc.data() as Map<String, dynamic>;

                return data["userId"] !=
                    currentUserId;
              }).toList();

              if (users.isEmpty) {
                return const Center(
                  child: Text("No users found"),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final data =
                      users[index].data()
                          as Map<String, dynamic>;

                  return ChatTile(
                    userId:
                        data["userId"] ?? "",
                    name: data["name"] ?? "",
                    message:
                        data["about"] ?? "",
                  );
                },
              );
            },
          );
        },
      ),

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

class ChatTile extends StatelessWidget {
  final String userId;
  final String name;
  final String message;

  const ChatTile({
    super.key,
    required this.userId,
    required this.name,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        radius: 28,
        child: Icon(Icons.person),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      subtitle: Text(message),
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