import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../services/narrator_service.dart';
import '../widgets/accessible_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  String _name = '';
  int _age = 15;
  bool _isBlind = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarratorService().speak("Registration screen. Please create a new account.");
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      NarratorService().playEarcon(Earcon.error);
      NarratorService().speak("Please check the form for errors.");
      return;
    }
    
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    NarratorService().playEarcon(Earcon.loading);
    NarratorService().speak("Registering your account, please wait.", interrupt: true);

    try {
      await ApiService.register(
        username: _username,
        password: _password,
        name: _name,
        age: _age,
        isBlind: _isBlind,
        email: "student@example.com",
        mobileNo: "0000000000"
      );
      if (!mounted) return;
      NarratorService().playEarcon(Earcon.success);
      NarratorService().speak("Registration successful. You can now log in.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful. Please log in.')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NarratorService().playEarcon(Earcon.error);
      NarratorService().speak("Registration failed.");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
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
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent.withOpacity(0.3), Colors.transparent],
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
                        const Text("Create Account", style: AppTextStyles.h1).animate().slideY(begin: -0.2).fadeIn(),
                        const SizedBox(height: 32),
                        
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
                            validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        
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
                            validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        
                        const SizedBox(height: 16),
                        
                        // Name
                        AccessibleWidget(
                          label: "Full Name input field",
                          child: TextFormField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: const TextStyle(color: Colors.white60),
                              prefixIcon: const Icon(Icons.badge, color: AppColors.primaryLight),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            onSaved: (value) => _name = value ?? '',
                            validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        
                        const SizedBox(height: 16),
                        
                        // Age
                        AccessibleWidget(
                          label: "Age input field",
                          child: TextFormField(
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age',
                              labelStyle: const TextStyle(color: Colors.white60),
                              prefixIcon: const Icon(Icons.cake, color: AppColors.primaryLight),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            onSaved: (value) => _age = int.tryParse(value ?? '15') ?? 15,
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        
                        const SizedBox(height: 16),
                        
                        // Visually Impaired Checkbox
                        AccessibleWidget(
                          label: "Visually impaired toggle. Current state: ${_isBlind ? 'Yes' : 'No'}",
                          onActivate: () => setState(() => _isBlind = !_isBlind),
                          child: GestureDetector(
                            onTap: () => setState(() => _isBlind = !_isBlind),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(_isBlind ? Icons.visibility_off : Icons.visibility, color: AppColors.primaryLight),
                                  const SizedBox(width: 16),
                                  const Expanded(child: Text("Visually Impaired", style: TextStyle(color: Colors.white))),
                                  Switch(
                                    value: _isBlind,
                                    onChanged: (val) => setState(() => _isBlind = val),
                                    activeColor: AppColors.primaryLight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                        
                        const SizedBox(height: 32),
                        
                        // Register Button
                        AccessibleWidget(
                          label: "Register button. Double tap to submit.",
                          onActivate: _isLoading ? () {} : _register,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _register,
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
                                  : const Text("REGISTER", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 24),
                        
                        // Login Link
                        AccessibleWidget(
                          label: "Back to login. Double tap to return.",
                          onActivate: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                            },
                            child: const Text("Already have an account? Login", style: TextStyle(color: AppColors.accent, decoration: TextDecoration.underline)),
                          ),
                        ).animate().fadeIn(delay: 700.ms),
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
