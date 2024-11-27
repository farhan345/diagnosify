// ignore_for_file: use_build_context_synchronously

import 'package:diagnosify/screens/dashboard/disease_result_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';

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
    const totalDuration = Duration(milliseconds: 3000); // 3 seconds total
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
          // Update loading text
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiseaseDetectionPage(
            isPneumonia: widget.result['isPneumonia'],
            confidence: widget.result['confidence'],
            imagePath: widget.imagePath,
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
            colors: [Color(0xffB81736), Color(0xff281537)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular progress with percentage
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: _progress / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${_progress.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Loading text with fade transition
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
                // Linear progress indicator
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
