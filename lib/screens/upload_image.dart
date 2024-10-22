import 'package:flutter/material.dart';
import 'package:diagnosify/screens/disease_result_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadImagePage extends StatefulWidget {
  final String disease;

  const UploadImagePage({required this.disease, super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle any errors here
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xffB81736)),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xffB81736)),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xffB81736), Color(0xff281537)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Upload Image - ${widget.disease}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideX(),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 250,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: _image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_a_photo,
                                    size: 80,
                                    color: Color(0xffB81736),
                                  ),
                          ),
                        ).animate().scale(delay: 300.ms),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.cloud_upload, color: Colors.white),
                          label: const Text(
                            'Upload Image',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffB81736),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideY(),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _image == null
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  // Simulate processing delay
                                  await Future.delayed(
                                      const Duration(seconds: 2));
                                  setState(() => _isLoading = false);
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DiseaseDetectionPage(),
                                      ),
                                    );
                                  }
                                },
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                          label: Text(
                            _isLoading ? 'Processing...' : 'Detect Disease',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff281537),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
                            disabledBackgroundColor:
                                const Color(0xff281537).withOpacity(0.5),
                          ),
                        ).animate().fadeIn(delay: 700.ms).slideY(),
                      ],
                    ),
                  ).animate().scale(delay: 200.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}