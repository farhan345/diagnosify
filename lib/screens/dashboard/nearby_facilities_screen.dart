import 'package:diagnosify/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class NearbyDoctorsPage extends StatefulWidget {
  final String diseaseType;

  const NearbyDoctorsPage({
    required this.diseaseType,
    super.key,
  });

  @override
  State<NearbyDoctorsPage> createState() => _NearbyDoctorsPageState();
}

class _NearbyDoctorsPageState extends State<NearbyDoctorsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _nearbyDoctors = [];
  Position? _currentPosition;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat(reverse: true);
    _findNearbyDoctors();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _findNearbyDoctors() async {
    try {
      // Get location permission
      final permissionStatus = await Permission.location.request();

      if (permissionStatus.isGranted) {
        // Get current position
        _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // Use Overpass API to fetch nearby healthcare facilities
        final overpassQuery = '''
          [out:json];
          (
            node["amenity"~"hospital|clinic|doctors"](${_currentPosition!.latitude - 0.05},${_currentPosition!.longitude - 0.05},${_currentPosition!.latitude + 0.05},${_currentPosition!.longitude + 0.05});
          );
          out body;
        ''';

        final response = await http.post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          body: overpassQuery,
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final elements = data['elements'] as List;

          // Process the results
          setState(() {
            _nearbyDoctors = elements.map((element) {
              final double lat = element['lat'];
              final double lon = element['lon'];
              final double distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                lat,
                lon,
              );

              return {
                'name': element['tags']['name'] ?? 'Unnamed Facility',
                'address': element['tags']['address'] ?? 'No address available',
                'distance': (distance / 1000).toStringAsFixed(2), // km
                'coordinates': [lon, lat], // [longitude, latitude]
                'type': _getHealthcareType(element['tags']),
              };
            }).toList();

            // Sort by distance
            _nearbyDoctors.sort((a, b) => double.parse(a['distance'])
                .compareTo(double.parse(b['distance'])));

            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to fetch nearby doctors. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Location permission denied. Please enable location to find nearby doctors.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getHealthcareType(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'hospital') return 'Hospital';
    if (tags['amenity'] == 'clinic') return 'Clinic';
    if (tags['amenity'] == 'doctors') return 'Doctor\'s Office';
    return 'Healthcare Facility';
  }

  // Future<void> _openMap(double lat, double lng) async {
  //   final String googleMapsUrl =
  //       'https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}';

  //   final Uri uri = Uri.parse(googleMapsUrl);

  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   } else {
  //     throw 'Could not launch Maps';
  //   }
  // }

  void _openMap(double lat, double lng, String name) {
    try {
      // Launch map with coordinates and a label
      MapsLauncher.launchCoordinates(lat, lng, name);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening map: $e')),
      );
    }
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor, int index) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + (index * 100)),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 50),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top colored band indicating facility type
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: AppColors.primaryRed.withOpacity(0.8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          doctor['type'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_walk,
                                  size: 14, color: AppColors.primaryPurple),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor['distance']} km',
                                style: const TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                _getFacilityIcon(doctor['type']),
                                color: AppColors.primaryPurple,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right side - text info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    doctor['address'],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              final coordinates = doctor['coordinates'];
                              _openMap(
                                coordinates[1],
                                coordinates[0],
                                doctor['name'],
                              );
                            },
                            icon: const Icon(Icons.directions,
                                color: AppColors.primaryPurple),
                            label: const Text(
                              'Directions',
                              style: TextStyle(color: AppColors.primaryPurple),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getFacilityIcon(String type) {
    switch (type) {
      case 'Hospital':
        return Icons.local_hospital;
      case 'Clinic':
        return Icons.medical_services;
      case 'Doctor\'s Office':
        return Icons.person;
      default:
        return Icons.health_and_safety;
    }
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.local_hospital,
                  size: 60,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Finding nearby doctors...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(
            color: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _findNearbyDoctors();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No healthcare facilities found nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We couldn\'t find any doctors or hospitals in your vicinity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _findNearbyDoctors();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryRed,
              Color(0xFF34B5C2), // Intermediate color
              AppColors.primaryPurple,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nearby Healthcare',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Found ${_isLoading ? '...' : _nearbyDoctors.length} healthcare facilities near you',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Disease type info
              if (widget.diseaseType.isNotEmpty)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Doctors specializing in ${widget.diseaseType} treatment',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // Content area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: _isLoading
                        ? _buildLoadingView()
                        : _errorMessage.isNotEmpty
                            ? _buildErrorView()
                            : _nearbyDoctors.isEmpty
                                ? _buildEmptyView()
                                : Column(
                                    children: [
                                      Expanded(
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 8, 16, 16),
                                          itemCount: _nearbyDoctors.length,
                                          itemBuilder: (context, index) {
                                            return _buildDoctorCard(
                                                _nearbyDoctors[index], index);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          !_isLoading && _errorMessage.isEmpty && _nearbyDoctors.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  backgroundColor: AppColors.primaryRed,
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                )
              : null,
    );
  }
}
