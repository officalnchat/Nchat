import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final FirestoreService _firestoreService =
      FirestoreService();

  final ImagePicker _imagePicker =
      ImagePicker();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _aboutController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String _userId = '';
  String _phoneNumber = '';
  String _photoUrl = '';

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> _loadProfile() async {
    try {
      final userId =
          await _firestoreService.getCurrentUserId();

      final snapshot =
          await _firestoreService.usersCollection
              .doc(userId)
              .get();

      if (!mounted) return;

      if (snapshot.exists) {
        final data =
            snapshot.data()
                as Map<String, dynamic>? ??
            {};

        setState(() {
          _userId = userId;

          _nameController.text =
              data['name']?.toString() ?? '';

          _aboutController.text =
              data['about']?.toString() ?? '';

          _photoUrl =
              data['photoUrl']?.toString() ?? '';

          _phoneNumber =
              data['phoneNumber']?.toString() ?? '';

          _isLoading = false;
        });
      } else {
        setState(() {
          _userId = userId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load profile: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // PICK PROFILE IMAGE
  // =========================================================

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      setState(() {
        _selectedImage =
            File(pickedFile.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to select image: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> _saveProfile() async {
    final name =
        _nameController.text.trim();

    final about =
        _aboutController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Name cannot be empty.',
          ),
        ),
      );

      return;
    }

    if (_userId.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? newPhotoUrl;

      // ================================================
      // UPLOAD NEW PROFILE IMAGE
      // ================================================

      if (_selectedImage != null) {
        newPhotoUrl =
            await _firestoreService
                .uploadProfileImage(
          userId: _userId,
          imageFile: _selectedImage!,
        );

        if (newPhotoUrl.isEmpty) {
          throw Exception(
            'Profile image upload failed.',
          );
        }
      }

      // ================================================
      // UPDATE PROFILE
      // ================================================

      await _firestoreService.updateProfile(
        userId: _userId,
        name: name,
        about: about,
        photoUrl:
            newPhotoUrl ?? _photoUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =========================================================
  // PROFILE IMAGE
  // =========================================================

  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      return CircleAvatar(
        radius: 58,
        backgroundImage:
            FileImage(_selectedImage!),
      );
    }

    if (_photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 58,
        backgroundImage:
            NetworkImage(_photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 58,
      child: Icon(
        Icons.person,
        size: 60,
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ==========================================
                  // PROFILE PHOTO
                  // ==========================================

                  Stack(
                    children: [
                      _buildProfileImage(),

                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color:
                              AppColors.primary,
                          shape:
                              const CircleBorder(),
                          child: InkWell(
                            customBorder:
                                const CircleBorder(),
                            onTap:
                                _isSaving
                                    ? null
                                    : _pickProfileImage,
                            child:
                                const Padding(
                              padding:
                                  EdgeInsets.all(10),
                              child: Icon(
                                Icons.camera_alt,
                                color:
                                    Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Change profile photo',
                    style: TextStyle(
                      color:
                          AppColors.primary,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==========================================
                  // NAME
                  // ==========================================

                  TextField(
                    controller:
                        _nameController,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        InputDecoration(
                      labelText: 'Name',
                      prefixIcon:
                          const Icon(
                        Icons.person_outline,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // ABOUT
                  // ==========================================

                  TextField(
                    controller:
                        _aboutController,
                    maxLines: 3,
                    maxLength: 100,
                    decoration:
                        InputDecoration(
                      labelText: 'About',
                      hintText:
                          'Tell something about yourself',
                      prefixIcon:
                          const Padding(
                        padding:
                            EdgeInsets.only(
                          bottom: 45,
                        ),
                        child: Icon(
                          Icons.info_outline,
                        ),
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // ==========================================
                  // PHONE NUMBER
                  // ==========================================

                  TextField(
                    controller:
                        TextEditingController(
                      text: _phoneNumber.isEmpty
                          ? 'Not available'
                          : _phoneNumber,
                    ),
                    readOnly: true,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Phone Number',
                      prefixIcon:
                          const Icon(
                        Icons.phone_outlined,
                      ),
                      suffixIcon:
                          const Icon(
                        Icons.lock_outline,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==========================================
                  // SAVE BUTTON
                  // ==========================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : _saveProfile,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style:
                                  TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}