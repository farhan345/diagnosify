import 'package:diagnosify/screens/dashboard/disease_result_screen.dart';
import 'package:diagnosify/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final String imagePath;

  const LoadingScreen({
    required this.result,
    required this.imagePath,
    super.key,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0;
  final List<String> _loadingTexts = [
    'Analyzing image...',
    'Processing data...',
    'Running diagnosis...',
    'Preparing results...',
  ];
  int _currentTextIndex = 0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    const totalDuration = Duration(milliseconds: 3000);
    const progressInterval = Duration(milliseconds: 30);
    final steps =
        totalDuration.inMilliseconds ~/ progressInterval.inMilliseconds;
    final progressIncrement = 100 / steps;

    Timer.periodic(progressInterval, (timer) {
      if (_progress >= 100) {
        timer.cancel();
        _navigateToResult();
      } else {
        setState(() {
          _progress += progressIncrement;
          if (_progress > 25 && _currentTextIndex == 0) {
            _currentTextIndex = 1;
          } else if (_progress > 50 && _currentTextIndex == 1) {
            _currentTextIndex = 2;
          } else if (_progress > 75 && _currentTextIndex == 2) {
            _currentTextIndex = 3;
          }
        });
      }
    });
  }

  void _navigateToResult() {
    Future.delayed(const Duration(milliseconds: 500), () {
      String predictedClass = widget.result['predictedClass'] as String;
      bool isBrainTumor = predictedClass != 'notumor';
      double confidence = widget.result['confidence'] as double;
      Map<String, String> probabilities =
          widget.result['allProbabilities'] as Map<String, String>;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiseaseDetectionPage(
            isBrainTumor: isBrainTumor,
            confidence: confidence,
            imagePath: widget.imagePath,
            predictedClass: predictedClass,
            probabilities: probabilities,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie Animation
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/dloader.json', // Replace with your Lottie JSON path
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _loadingTexts[_currentTextIndex],
                    key: ValueKey<int>(_currentTextIndex),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
