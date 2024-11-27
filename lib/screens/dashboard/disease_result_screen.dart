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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffB81736), Color(0xff281537)],
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
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Pneumonia Analysis Result',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildConfidenceIndicator(),
                      const SizedBox(height: 30),
                      _buildSymptomsList(),
                      const SizedBox(height: 30),
                      _buildRecommendations(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
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
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: widget.isPneumonia ? const Color(0xffB81736) : Colors.green,
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
              color:
                  widget.isPneumonia ? const Color(0xffB81736) : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isPneumonia
                ? "Don't worry, you're not alone in this journey. With proper care and treatment, pneumonia is treatable. Stay strong!"
                : "Great news! Your lungs appear healthy. Keep up the good work with your health!",
            style: TextStyle(
              fontSize: 16,
              color:
                  widget.isPneumonia ? const Color(0xffB81736) : Colors.green,
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
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: LinearProgressIndicator(
              value: widget.confidence / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isPneumonia ? const Color(0xffB81736) : Colors.green,
              ),
              minHeight: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Confidence: ${widget.confidence.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff281537),
            ),
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
            'Fatigue',
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
                              ? const Color(0xffB81736)
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          symptom,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xff281537),
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
                              ? const Color(0xffB81736)
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to doctor-finding page
          },
          icon: const Icon(Icons.search, color: Colors.white),
          label: const Text(
            'Find Specialists',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff281537),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          ),
        ),
        if (widget.isPneumonia) ...[
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to treatment info page
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
            label: const Text(
              'Treatment Information',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffB81736),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            ),
          ),
        ],
      ],
    );
  }
}
