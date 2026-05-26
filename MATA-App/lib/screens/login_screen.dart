import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/narrator_service.dart';
import '../widgets/accessible_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarratorService().speak("Login screen. Please enter your username and password.");
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      NarratorService().playEarcon(Earcon.error);
      NarratorService().speak("Please check the form for errors.");
      return;
    }
    
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    NarratorService().playEarcon(Earcon.loading);
    NarratorService().speak("Logging in, please wait.", interrupt: true);

    try {
      await ApiService.login(_username, _password);

      if (!mounted) return;
      NarratorService().playEarcon(Earcon.success);
      NarratorService().speak("Login successful. Welcome back.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigator()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NarratorService().playEarcon(Earcon.error);
      NarratorService().speak("Login failed. Please check your credentials.");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          // Background Effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 2.seconds),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("MATA", style: AppTextStyles.displayLg).animate().slideY(begin: -0.2).fadeIn(),
                        const SizedBox(height: 8),
                        const Text("Welcome back", style: AppTextStyles.bodyMd).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 48),
                        
                        // Username
                        AccessibleWidget(
                          label: "Username input field",
                          child: TextFormField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: const TextStyle(color: Colors.white60),
                              prefixIcon: const Icon(Icons.person, color: AppColors.primaryLight),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            onSaved: (value) => _username = value ?? '',
                            validator: (value) => (value == null || value.isEmpty) ? 'Please enter username' : null,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                        
                        const SizedBox(height: 16),
                        
                        // Password
                        AccessibleWidget(
                          label: "Password input field",
                          child: TextFormField(
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.white60),
                              prefixIcon: const Icon(Icons.lock, color: AppColors.primaryLight),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            onSaved: (value) => _password = value ?? '',
                            validator: (value) => (value == null || value.isEmpty) ? 'Please enter password' : null,
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                        
                        const SizedBox(height: 32),
                        
                        // Login Button
                        AccessibleWidget(
                          label: "Login button. Double tap to submit.",
                          onActivate: _isLoading ? () {} : _login,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _login,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
                              ),
                              child: _isLoading
                                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)))
                                  : const Text("LOGIN", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 24),
                        
                        // Register Link
                        AccessibleWidget(
                          label: "Create new account link. Double tap to register.",
                          onActivate: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                            },
                            child: const Text("Don't have an account? Register here", style: TextStyle(color: AppColors.accent, decoration: TextDecoration.underline)),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
