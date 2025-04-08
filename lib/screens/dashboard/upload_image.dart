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

class _UploadImagePageState extends State<UploadImagePage>
    with SingleTickerProviderStateMixin {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  late Interpreter _interpreter;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Updated labels list to include the new "notbrain" class
  final List<String> _labels = [
    'glioma',
    'meningioma',
    'notumor',
    'pituitary',
    'notbrain'
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _interpreter.close();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();
      // Make sure your model file is in the assets folder and properly referenced in pubspec.yaml
      _interpreter = await Interpreter.fromAsset(
          'assets/NewTrainedModel.tflite',
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

    // Resize to 224x224 as per Teachable Machine's requirements
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

    // Convert and normalize the image data
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
      // Updated output shape to match 5 classes instead of 4
      var output = List.filled(1 * 5, 0.0).reshape([1, 5]);

      _interpreter.run(input, output);

      final result = output[0] as List<double>;

      // Find the class with highest confidence
      int maxIndex = 0;
      double maxConfidence = result[0];
      for (int i = 1; i < result.length; i++) {
        if (result[i] > maxConfidence) {
          maxIndex = i;
          maxConfidence = result[i];
        }
      }

      // Check if the result is the "notbrain" class
      if (_labels[maxIndex] == 'notbrain') {
        // Return a map indicating this isn't a brain scan
        return {
          'isBrainScan': false,
          'rawOutput': result,
        };
      }

      // Create a map of all probabilities for brain tumor classes
      Map<String, String> probabilities = {};
      for (int i = 0; i < _labels.length - 1; i++) {
        // Exclude notbrain
        probabilities[_labels[i]] = '${(result[i] * 100).toStringAsFixed(2)}%';
      }

      return {
        'isBrainScan': true,
        'predictedClass': _labels[maxIndex],
        'confidence': maxConfidence * 100,
        'allProbabilities': probabilities,
        'rawOutput': result,
      };
    } catch (e) {
      debugPrint('Error running inference: $e');
      rethrow;
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Image Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Please select a brain MRI or CT scan image only',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _getImage(ImageSource.camera);
                      },
                    ),
                    _buildSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _getImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.primaryRed,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showNonBrainImageWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF9F9F9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 15,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppColors.primaryRed,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Not a Brain Scan',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'This does not appear to be a brain MRI or CT scan image.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please upload a valid brain scan image for accurate diagnosis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showImageSourceDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Upload Different Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await runInference(_image!);

      // Check if the image is a brain scan based on model classification
      if (result.containsKey('isBrainScan') && result['isBrainScan'] == false) {
        // If not a brain scan, show warning and don't proceed
        if (mounted) {
          _showNonBrainImageWarning();
        }
        return;
      }

      // If it is a brain scan, proceed to results
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
        SnackBar(
          content: Text('Error processing image: $e'),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(10),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with your original gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.gradientColors,
              ),
            ),
          ),

          // Dynamic gradient overlay animation using your theme colors
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(_animation.value * 2 - 1, -0.3),
                      radius: 1.5,
                      colors: const [Colors.white, Colors.transparent],
                      stops: const [0.0, 0.3],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar with original theme colors
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analyze Brain Scan',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.disease,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideX(),
                ),

                // Main content card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Column(
                        children: [
                          // Colored header with wave design using primaryRed
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryRed,
                                  Color(0xFF281537),
                                ],
                              ),
                            ),
                            child: CustomPaint(
                              painter: WavePainter(),
                              child: const Center(
                                child: Text(
                                  'Upload Brain Scan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Info text with icon
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primaryRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: AppColors.primaryRed
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppColors.primaryRed,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Please upload a clear brain MRI or CT scan image for accurate analysis',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.primaryRed,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 25),

                                  // Image selection area
                                  GestureDetector(
                                    onTap: _showImageSourceDialog,
                                    child: Container(
                                      height: 250,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _image != null
                                              ? Colors.transparent
                                              : Colors.grey.withOpacity(0.3),
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                        boxShadow: _image != null
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.15),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: _image != null
                                          ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Image.file(
                                                    _image!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 10,
                                                  top: 10,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.7),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: InkWell(
                                                      onTap:
                                                          _showImageSourceDialog,
                                                      child: const Icon(
                                                        Icons.edit,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : DashedBorder(
                                              color: AppColors.primaryRed,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            20),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .primaryRed
                                                          .withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.add_photo_alternate,
                                                      size: 60,
                                                      color:
                                                          AppColors.primaryRed,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15),
                                                  const Text(
                                                    'Tap to upload a brain scan',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.primaryRed,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'MRI or CT images only',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ).animate().scale(delay: 300.ms),
                                  const SizedBox(height: 35),

                                  // Action buttons
                                  Row(
                                    children: [
                                      // Upload button
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _showImageSourceDialog,
                                          icon: const Icon(
                                            Icons.cloud_upload,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Upload',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryRed,
                                            foregroundColor: Colors.white,
                                            elevation: 5,
                                            shadowColor: AppColors.primaryRed
                                                .withOpacity(0.5),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                        )
                                            .animate()
                                            .fadeIn(delay: 500.ms)
                                            .slideY(),
                                      ),
                                      const SizedBox(width: 15),

                                      // Analyze button
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _image == null
                                              ? null
                                              : () => _processImage(),
                                          icon: _isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.search,
                                                  color: Colors.white,
                                                ),
                                          label: Text(
                                            _isLoading
                                                ? 'Processing...'
                                                : 'Analyze',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xff281537),
                                            foregroundColor: Colors.white,
                                            elevation: 5,
                                            shadowColor: const Color(0xff281537)
                                                .withOpacity(0.5),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            disabledBackgroundColor:
                                                const Color(0xff281537)
                                                    .withOpacity(0.3),
                                          ),
                                        )
                                            .animate()
                                            .fadeIn(delay: 700.ms)
                                            .slideY(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Wave painter for the header
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add a second wave
    final path2 = Path();
    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    path2.moveTo(0, size.height * 0.9);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.8,
      size.width * 0.5,
      size.height * 0.9,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height * 0.9,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom dashed border widget
class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;

  const DashedBorder({
    super.key,
    required this.child,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedRectPainter(color: color),
      child: child,
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;

  DashedRectPainter({this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    var dashWidth = 8;
    var dashSpace = 5;
    var startX = 0.0;
    var startY = 0.0;
    var radius = 20.0;

    // Top line
    while (startX < size.width - radius) {
      canvas.drawLine(
        Offset(startX + radius, startY),
        Offset(startX + dashWidth + radius, startY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Right line
    startX = size.width;
    startY = 0;
    while (startY < size.height - radius) {
      canvas.drawLine(
        Offset(startX, startY + radius),
        Offset(startX, startY + dashWidth + radius),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Bottom line
    startX = size.width;
    startY = size.height;
    while (startX > radius) {
      canvas.drawLine(
        Offset(startX - radius, startY),
        Offset(startX - dashWidth - radius, startY),
        paint,
      );
      startX -= dashWidth + dashSpace;
    }

    // Left line
    startX = 0;
    startY = size.height;
    while (startY > radius) {
      canvas.drawLine(
        Offset(startX, startY - radius),
        Offset(startX, startY - dashWidth - radius),
        paint,
      );
      startY -= dashWidth + dashSpace;
    }

    // Continuing with the DashedRectPainter class
    // Draw the rounded corners
    var rect = Rect.fromLTRB(0, 0, size.width, size.height);
    var rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    var path = Path()..addRRect(rrect);

    // Use dashed path for drawing the rounded corners
    var dashPaint = Paint()
      ..color = Colors.transparent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
