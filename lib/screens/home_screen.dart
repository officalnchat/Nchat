import 'package:flutter/material.dart';

import '../services/contact_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final FirestoreService firestoreService =
      FirestoreService();

  final ContactService contactService =
      ContactService();

  List<Map<String, dynamic>> users = [];

  bool isLoading = true;
  bool hasContactPermission = false;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadContactUsers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // =========================================================
  // APP RESUME
  // =========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _loadContactUsers();
    }
  }

  // =========================================================
  // LOAD CONTACT USERS
  // =========================================================

  Future<void> _loadContactUsers({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final permission =
          await contactService.hasPermission();

      if (!permission) {
        if (mounted) {
          setState(() {
            hasContactPermission = false;
            users = [];
            isLoading = false;
          });
        }

        return;
      }

      final currentUserId =
          await firestoreService.getCurrentUserId();

      final contactNumbers =
          await contactService.getContactNumbers();

      final contactUsers =
          await firestoreService.getUsersFromContacts(
        phoneNumbers: contactNumbers,
        currentUserId: currentUserId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        hasContactPermission = true;
        users = contactUsers;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================================================
  // REQUEST CONTACT PERMISSION
  // =========================================================

  Future<void> _requestContactPermission() async {
    final granted =
        await contactService.requestPermission();

    if (!mounted) {
      return;
    }

    if (granted) {
      await _loadContactUsers();
    } else {
      setState(() {
        hasContactPermission = false;
        isLoading = false;
      });
    }
  }

  // =========================================================
  // PULL TO REFRESH
  // =========================================================

  Future<void> _refreshUsers() async {
    if (isRefreshing) {
      return;
    }

    setState(() {
      isRefreshing = true;
    });

    await _loadContactUsers(
      showLoading: false,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isRefreshing = false;
    });
  }

  // =========================================================
  // PERMISSION SCREEN
  // =========================================================

  Widget _buildPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 72,
              color: AppColors.primary,
            ),

            const SizedBox(height: 20),

            Text(
              "Contacts Permission Required",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            Text(
              "NChat uses your phone contacts to show "
              "people you know who are already using NChat.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed:
                  _requestContactPermission,
              icon: const Icon(
                Icons.contacts,
              ),
              label: const Text(
                "Allow Contacts",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY CONTACT USERS
  // =========================================================

  Widget _buildEmptyUsers() {
    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.32,
          ),

          Icon(
            Icons.person_search_outlined,
            size: 64,
            color: Theme.of(context)
                .iconTheme
                .color
                ?.withValues(alpha: 0.6),
          ),

          const SizedBox(height: 16),

          Text(
            "No NChat users found",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            "People from your contacts who use NChat "
            "will appear here.",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // USERS LIST
  // =========================================================

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final data = users[index];

          return ChatTile(
            userId:
                data["userId"]?.toString() ?? "",
            name:
                data["name"]?.toString() ?? "",
            message:
                data["about"]?.toString() ?? "",
            photoUrl:
                data["photoUrl"]?.toString() ?? "",
          );
        },
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

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
      // BODY
      // =====================================================

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : !hasContactPermission
              ? _buildPermissionScreen()
              : users.isEmpty
                  ? _buildEmptyUsers()
                  : _buildUsersList(),

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