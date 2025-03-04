import 'package:diagnosify/screens/authentication/login_screen.dart';
import 'package:diagnosify/screens/authentication/signup_screen.dart';
import 'package:diagnosify/theme/app_color.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: screenHeight,
          width: screenWidth,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: screenHeight * 0.2), // Responsive padding
                child: const CircleAvatar(
                  radius: 75, // CircleAvatar size
                  backgroundImage: AssetImage('assets/logo1.png'),

                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(
                  height: screenHeight * 0.1), // Adjust based on screen height
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenHeight * 0.05), // Responsive spacing
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 53,
                  width: screenWidth * 0.8, // Responsive width
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Center(
                    child: Text(
                      'SIGN IN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03), // Responsive spacing
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 53,
                  width: screenWidth * 0.8, // Responsive width
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Center(
                    child: Text(
                      'SIGN UP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // const Text(
              //   'Login with Social Media',
              //   style: TextStyle(
              //     fontSize: 17,
              //     color: Colors.white,
              //   ),
              // ),
              // SizedBox(height: screenHeight * 0.02), // Adjust based on screen height
              // const Image(
              //   image: AssetImage('assets/social.png'),
              //   height: 50, // Adjust height for social icons
              // ),
              // SizedBox(height: screenHeight * 0.05), // Add some padding to the bottom
            ],
          ),
        ),
      ),
    );
  }
}
