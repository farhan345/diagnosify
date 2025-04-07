// upload_image_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:diagnosify/screens/dashboard/loading_screen.dart';
import 'package:diagnosify/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
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
  late Interpreter _interpreter;

  // Define allowed disease type
  final List<String> _allowedDiseases = ['pneumonia'];

  @override
  void initState() {
    super.initState();
    // Check if the passed disease is valid
    if (!_allowedDiseases.contains(widget.disease.toLowerCase())) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This page only supports pneumonia detection'),
          ),
        );
        Navigator.pop(context);
      });
    }
    loadModel();
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  Future<void> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset('assets/model.tflite',
          options: interpreterOptions);
      debugPrint('Model loaded successfully');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  Future<List<List<List<List<double>>>>> preprocessImage(File imageFile) async {
    final imageData = await imageFile.readAsBytes();
    final image = img.decodeImage(imageData);
    if (image == null) throw Exception('Failed to decode image');

    final resizedImage = img.copyResize(image, width: 224, height: 224);

    var inputArray = List.generate(
      1,
      (_) => List.generate(
        224,
        (_) => List.generate(
          224,
          (_) => List.generate(3, (_) => 0.0),
        ),
      ),
    );

    for (var y = 0; y < resizedImage.height; y++) {
      for (var x = 0; x < resizedImage.width; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputArray[0][y][x][0] = pixel.r / 255.0;
        inputArray[0][y][x][1] = pixel.g / 255.0;
        inputArray[0][y][x][2] = pixel.b / 255.0;
      }
    }

    return inputArray;
  }

  Future<Map<String, dynamic>> runInference(File imageFile) async {
    try {
      final input = await preprocessImage(imageFile);
      var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

      _interpreter.run(input, output);

      final result = output[0] as List<double>;
      final confidence = result.reduce((a, b) => a > b ? a : b) * 100;
      final isPositive = result[1] > result[0];

      return {
        'isPneumonia': isPositive,
        'confidence': confidence,
        'rawOutput': result,
      };
    } catch (e) {
      debugPrint('Error running inference: $e');
      rethrow;
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        String extension = pickedFile.path.toLowerCase();
        if (!extension.endsWith('.jpg') &&
            !extension.endsWith('.jpeg') &&
            !extension.endsWith('.png')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload only JPG or PNG images'),
            ),
          );
          return;
        }

        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
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
                leading:
                    const Icon(Icons.camera_alt, color: AppColors.primaryRed),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.primaryRed),
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
                colors: AppColors.gradientColors,
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
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
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
                                  color: Colors.black
                                      .withAlpha((0.1 * 255).toInt()),
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
                                    color: AppColors.primaryRed,
                                  ),
                          ),
                        ).animate().scale(delay: 300.ms),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.cloud_upload,
                              color: Colors.white),
                          label: const Text(
                            'Upload Image',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
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
                                  try {
                                    final result = await runInference(_image!);
                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoadingScreen(
                                            result: result,
                                            imagePath: _image!.path,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
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
                            disabledBackgroundColor: const Color(0xff281537)
                                .withAlpha((0.5 * 255).toInt()),
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
