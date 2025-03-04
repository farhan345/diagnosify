// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diagnosify/theme/app_color.dart';
import 'package:diagnosify/widgets/custom_field.dart';
import 'package:diagnosify/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:io';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  File? _imageFile;
  String? _phoneNumber;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${_auth.currentUser!.uid}.jpg');

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.message}')),
      );
      return null;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user with email and password
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      String? imageUrl;

      // If an image is uploaded, handle the upload process
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      // Save user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneNumber,
        'profileImageUrl': imageUrl ?? '', // Optional image URL
        'createdAt': Timestamp.now(),
      });

      // Update the user's profile with the display name and photo URL (if provided)
      await userCredential.user!.updateProfile(
        displayName: _nameController.text,
        photoURL: imageUrl,
      );

      // Navigate to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final size = MediaQuery.of(context).size;

        return Stack(
          children: [
            Scaffold(
              body: SingleChildScrollView(
                child: Container(
                  height: size.height,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.gradientColors),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(size.width * 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create\nAccount',
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? 32
                                      : isTablet
                                          ? 36
                                          : 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  height: 1.2,
                                ),
                              ).animate().fadeIn(duration: 500.ms).slideX(),
                              const SizedBox(height: 10),
                              const Text(
                                'Sign up to get started',
                                style: TextStyle(
                                  color: AppColors.white70,
                                  fontSize: 16,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 200.ms)
                                  .slideX(),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: isMobile
                                                ? 40
                                                : isTablet
                                                    ? 45
                                                    : 50,
                                            backgroundColor: AppColors.grey,
                                            backgroundImage: _imageFile != null
                                                ? FileImage(_imageFile!)
                                                : null,
                                            child: _imageFile == null
                                                ? const Icon(
                                                    Icons.add_a_photo,
                                                    size: 30,
                                                    color: AppColors.primaryRed,
                                                  )
                                                : null,
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primaryRed,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        .animate()
                                        .scale(delay: 200.ms)
                                        .then()
                                        .shimmer(duration: 1000.ms),
                                    const SizedBox(height: 20),
                                    CustomTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      icon: Icons.person_outline,
                                    ).animate().fadeIn(delay: 300.ms).slideX(),
                                    const SizedBox(height: 15),
                                    CustomTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ).animate().fadeIn(delay: 400.ms).slideX(),
                                    const SizedBox(height: 15),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: IntlPhoneField(
                                        dropdownTextStyle: const TextStyle(
                                            color: AppColors.primaryRed),
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          labelStyle: const TextStyle(
                                              color: AppColors.primaryRed),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: const BorderSide(
                                                color: AppColors.primaryRed),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: const BorderSide(
                                                color: Colors.red),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            borderSide: const BorderSide(
                                                color: Colors.red),
                                          ),
                                        ),
                                        initialCountryCode: 'US',
                                        cursorColor: AppColors.primaryRed,
                                        onChanged: (phone) {
                                          setState(() {
                                            _phoneNumber = phone.completeNumber;
                                          });
                                        },
                                      ),
                                    ).animate().fadeIn(delay: 500.ms).slideX(),
                                    const SizedBox(height: 15),
                                    CustomTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                    ).animate().fadeIn(delay: 600.ms).slideX(),
                                    const SizedBox(height: 15),
                                    CustomTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                    ).animate().fadeIn(delay: 700.ms).slideX(),
                                    const SizedBox(height: 30),
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _signUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryRed,
                                        minimumSize: Size(
                                          size.width * (isMobile ? 0.8 : 0.6),
                                          55,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: AppColors.white)
                                          : const Text(
                                              'SIGN UP',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.white,
                                              ),
                                            ),
                                    ).animate().fadeIn(delay: 800.ms).scale(),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Already have an account? ',
                                          style:
                                              TextStyle(color: AppColors.grey),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              color: AppColors.primaryRed,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ).animate().fadeIn(delay: 900.ms),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().slideY(
                              begin: 1,
                              duration: 500.ms,
                              curve: Curves.easeOut,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading) const Center(child: LoaderWidget()),
          ],
        );
      },
    );
  }
}
