import 'package:diagnosify/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xffB81736), Color(0xff281537)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms),
                const CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Color(0xffB81736),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .scale(delay: 200.ms)
                    .then()
                    .shimmer(duration: 1000.ms),
                const SizedBox(height: 20),
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 300.ms).slide(),
                const SizedBox(height: 40),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          _buildInfoTile(Icons.email, 'Email', 'example@gmail.com')
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideX(),
                          const SizedBox(height: 20),
                          _buildInfoTile(Icons.phone, 'Phone', '+1234567890')
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .slideX(),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                            },
                            style: ElevatedButton.styleFrom(
                            
                              backgroundColor: const Color(0xffB81736),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                            ),
                            child: const Text(
                              'Log Out',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ).animate().fadeIn(delay: 600.ms).scale(),
                        ],
                      ),
                    ),
                  ).animate().slideY(
                        begin: 1,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xffB81736)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff281537),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}