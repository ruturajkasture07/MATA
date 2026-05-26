import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/narrator_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  
  const SplashScreen({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  Future<void> _initSplash() async {
    // Narrate welcome message
    NarratorService().speak("Welcome to MATA. Loading your learning companion.");
    
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => widget.isLoggedIn 
              ? const MainNavigator() 
              : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.5),
                radius: 1.5,
                colors: [
                  Color(0x997C3AED), // Violet glow
                  AppColors.bg0,
                ],
              ),
            ),
          ),
          
          // Secondary Glow
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.8, 0.8),
                radius: 1.5,
                colors: [
                  Color(0x6606B6D4), // Cyan glow
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text("👁️", style: TextStyle(fontSize: 40)),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(end: 1.05, duration: 1000.ms, curve: Curves.easeInOut),
                 
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  "MATA",
                  style: AppTextStyles.displayLg,
                ),
                
                const SizedBox(height: 8),
                
                // Tagline
                const Text(
                  "Your AI Textbook\nReading Companion",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Progress Bar
                Container(
                  width: 120,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                       .moveX(begin: -60, end: 120, duration: 1500.ms, curve: Curves.easeInOut),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
