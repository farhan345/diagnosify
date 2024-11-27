// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:diagnosify/screens/authentication/login_screen.dart';
import 'package:diagnosify/widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diagnosify/widgets/loader.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  File? _newImageFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>;
            _nameController.text = userData?['name'] ?? '';
            _emailController.text = userData?['email'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error loading user data: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
      );

      if (image != null) {
        setState(() {
          _newImageFile = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_newImageFile == null) return null;

    try {
      final String fileName =
          '${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
          _storage.ref().child('user_images').child(fileName);

      await storageRef.putFile(_newImageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      _showSnackBar('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    // Validate name
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Name cannot be empty');
      return;
    }

    setState(() => isSaving = true);

    try {
      String? newImageUrl;
      if (_newImageFile != null) {
        newImageUrl = await _uploadImage();
      }

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
        'updatedAt': Timestamp.now(),
      };

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updateData);

      // Update user profile in Firebase Auth
      await _auth.currentUser!.updateProfile(
        displayName: _nameController.text.trim(),
        photoURL: newImageUrl ?? userData?['profileImageUrl'],
      );

      await _loadUserData();
      setState(() {
        isEditing = false;
        _newImageFile = null;
      });
      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      _showSnackBar('Error updating profile: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      _showSnackBar('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: LoaderWidget())
          : Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xffB81736), Color(0xff281537)],
                    ),
                  ),
                ),

                // Main content
                SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      // App Bar
                      SliverToBoxAdapter(
                        child: _buildAppBar(),
                      ),

                      // Profile Image Section
                      SliverToBoxAdapter(
                        child: _buildProfileImageSection(),
                      ),

                      // Info Cards Section
                      SliverToBoxAdapter(
                        child: _buildInfoSection(),
                      ),
                    ],
                  ),
                ),

                // Loading overlay
                if (isSaving)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: const Center(child: LoaderWidget()),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Show the icon only when editing
          if (isEditing)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _nameController.text = userData?['name'] ?? '';
                  _emailController.text = userData?['email'] ?? '';
                  _newImageFile = null;
                  isEditing = false;
                });
              },
            ),
          Text(
            isEditing ? 'Edit Profile' : 'Profile',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Colors.white,
              size: 22,
            ),
            onPressed: isEditing
                ? _saveProfile
                : () => setState(() => isEditing = true),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProfileImageSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Decorative circle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 30),
                ),
              ).animate().scale(delay: 200.ms),

              // Profile image
              GestureDetector(
                onTap: isEditing ? _pickImage : null,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xffB81736),
                    backgroundImage: _newImageFile != null
                        ? FileImage(_newImageFile!)
                        : (userData?['profileImageUrl'] != null
                            ? NetworkImage(userData!['profileImageUrl'])
                            : null) as ImageProvider?,
                    child: (_newImageFile == null &&
                            userData?['profileImageUrl'] == null)
                        ? const Icon(Icons.person,
                            size: 50, color: Colors.white)
                        : null,
                  ),
                ),
              ).animate().scale(delay: 400.ms),

              // Edit button
              if (isEditing)
                Positioned(
                  bottom: 0,
                  right: 115,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffB81736),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ).animate().scale(delay: 600.ms),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            userData?['name'] ?? 'No Name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 8),
          Text(
            userData?['email'] ?? 'No Email',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff281537),
            ),
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 24),

          // Always show these fields, but switch between editable and non-editable
          if (isEditing) ...[
            CustomTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person,
            ),
            const SizedBox(height: 500),
          ] else ...[
            _buildInfoCard(
              icon: Icons.phone,
              title: 'Phone',
              content: userData?['phone'] ?? ' No Phone',
              delay: 900,
            ),
            _buildInfoCard(
              icon: Icons.calendar_today_outlined,
              title: 'Member Since',
              content: _formatDate(userData?['createdAt']),
              delay: 1100,
            ),
          ],

          const SizedBox(height: 22),
          if (!isEditing)
            Center(
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffB81736),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xffB81736).withOpacity(0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.2),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffB81736).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xffB81736),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff281537),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX();
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No Date';
    final DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
