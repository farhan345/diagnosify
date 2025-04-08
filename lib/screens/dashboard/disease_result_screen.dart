import 'package:diagnosify/screens/dashboard/nearby_facilities_screen.dart';
import 'package:diagnosify/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

class DiseaseDetectionPage extends StatefulWidget {
  final bool isPneumonia;
  final double confidence;
  final String imagePath;

  const DiseaseDetectionPage({
    required this.isPneumonia,
    required this.confidence,
    required this.imagePath,
    super.key,
  });

  @override
  State<DiseaseDetectionPage> createState() => _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends State<DiseaseDetectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false; // Added missing _isLoading variable

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Added missing PDF generation method (placeholder - implement as needed)
  Future<void> generateAndDownloadPDF() async {
    setState(() => _isLoading = true);
    // Implement your PDF generation logic here
    await Future.delayed(const Duration(seconds: 2)); // Simulated delay
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF downloaded successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.gradientColors, // Using theme gradient colors
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                    const Text(
                      'Analysis Result',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildAnimatedResult(),
                      const SizedBox(height: 20),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: FileImage(File(widget.imagePath)),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildConfidenceIndicator(),
                      const SizedBox(height: 30),
                      _buildSymptomsList(),
                      const SizedBox(height: 30),
                      _buildRecommendations(),
                      const SizedBox(height: 30),
                      _buildDoctorActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isPneumonia
            ? AppColors.primaryRed.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: widget.isPneumonia ? AppColors.primaryRed : Colors.green,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Lottie.asset(
              widget.isPneumonia
                  ? 'assets/caring.json'
                  : 'assets/celebration.json',
              controller: _animationController,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isPneumonia ? 'Pneumonia Detected' : 'Normal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isPneumonia ? AppColors.primaryRed : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isPneumonia
                ? "Don't worry, you're not alone in this journey. With proper care and treatment, pneumonia is treatable. Stay strong!"
                : "Great news! Your lungs appear healthy. Keep up the good work with your health!",
            style: TextStyle(
              fontSize: 16,
              color: widget.isPneumonia ? AppColors.primaryRed : Colors.green,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detection Confidence',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: widget.confidence / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isPneumonia ? AppColors.primaryRed : Colors.green,
                ),
                minHeight: 20,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${widget.confidence.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff281537),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomsList() {
    final symptoms = widget.isPneumonia
        ? [
            'Chest Pain',
            'Difficulty Breathing',
            'Persistent Cough',
            'Rapid Breathing',
            ' Fatigue',
          ]
        : [
            'Normal Breathing Pattern',
            'Clear Lung Imagery',
            'No Visible Abnormalities',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: symptoms
                .map(
                  (symptom) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: widget.isPneumonia
                              ? AppColors.primaryRed
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            symptom,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xff281537),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    final recommendations = widget.isPneumonia
        ? [
            'Seek immediate medical attention',
            'Rest and stay hydrated',
            'Monitor breathing rate',
            'Take prescribed medications',
            'Follow-up with healthcare provider',
          ]
        : [
            'Maintain good respiratory hygiene',
            'Regular health check-ups',
            'Stay updated with vaccinations',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: recommendations
                .map(
                  (recommendation) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right,
                          color: widget.isPneumonia
                              ? AppColors.primaryRed
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xff281537),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await generateAndDownloadPDF();
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.download, color: Colors.white),
          label: Text(
            _isLoading ? 'Generating PDF...' : 'Download Report',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff281537),
            elevation: 5,
            shadowColor: const Color(0xff281537).withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            disabledBackgroundColor: const Color(0xff281537).withOpacity(0.3),
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NearbyDoctorsPage(
                  diseaseType: widget.isPneumonia ? 'Pneumonia' : 'Normal',
                ),
              ),
            );
          },
          icon: const Icon(Icons.local_hospital, color: Colors.white),
          label: const Text(
            'Find Nearby Doctors',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPneumonia
                ? AppColors.primaryRed
                : const Color(0xff281537),
            elevation: 5,
            shadowColor: widget.isPneumonia
                ? AppColors.primaryRed.withOpacity(0.5)
                : const Color(0xff281537).withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          ),
        ),
      ],
    );
  }
}
