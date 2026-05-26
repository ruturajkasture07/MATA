import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/narrator_service.dart';
import '../services/voice_service.dart';
import '../widgets/accessible_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';
import 'configuration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final bool _isLoading = false;
  String _currentVoiceInput = "";
  bool _isMarkListening = false;
  String _userName = "Learner";

  @override
  void initState() {
    super.initState();
    _loadUserName();
    VoiceService().initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarratorService().speak(
          "Home screen. Scan page is in the center. Tap anywhere else for options.");
    });
  }

  Future<void> _loadUserName() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (mounted) {
        setState(() {
          _userName = decodedToken['sub'] ?? "Learner";
        });
      }
    }
  }

  void _openCamera() {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  Future<void> _uploadImage() async {
    Navigator.pop(context); // Close bottom sheet
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      NarratorService().playEarcon(Earcon.success);
      NarratorService().speak("Image selected.");
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ConfigurationScreen(imagePath: pickedFile.path)),
        );
      }
    }
  }

  Future<void> _uploadPDF() async {
    Navigator.pop(context); // Close bottom sheet
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      NarratorService().playEarcon(Earcon.success);
      NarratorService().speak("PDF selected.");
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ConfigurationScreen(imagePath: result.files.single.path!, isPdf: true)),
        );
      }
    }
  }

  void _showOptionsSheet() {
    NarratorService().speak("Options: Open Camera, Upload Image, or Upload PDF.");
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Open Camera', style: TextStyle(color: Colors.white, fontSize: 18)),
              onTap: _openCamera,
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.accent),
              title: const Text('Upload Image from Gallery', style: TextStyle(color: Colors.white, fontSize: 18)),
              onTap: _uploadImage,
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.danger),
              title: const Text('Upload PDF Document', style: TextStyle(color: Colors.white, fontSize: 18)),
              onTap: _uploadPDF,
            ),
          ],
        ),
      ),
    );
  }

  void _triggerMark() {
    setState(() {
      _isMarkListening = true;
    });
    NarratorService().playEarcon(Earcon.success);
    NarratorService().speak(
        "Hi, what do you want to learn today? You can say 'Scan a page' or ask me a question.", interrupt: true);
        
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        VoiceService().startListening((text) {
          _currentVoiceInput = text;
        });

        // Auto stop and evaluate after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _isMarkListening = false;
            });
            if (VoiceService().isListening) {
              VoiceService().stopListening();
              if (_currentVoiceInput.toLowerCase().contains("scan") ||
                  _currentVoiceInput.toLowerCase().contains("camera")) {
                _openCamera();
              } else if (_currentVoiceInput.isNotEmpty) {
                NarratorService().speak(
                    "I heard: $_currentVoiceInput. General questions are best asked in the Learning Space.");
              }
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // App Bar / Greeting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Good morning,", style: AppTextStyles.caption.copyWith(letterSpacing: 0)),
                          Text("$_userName 👋", style: AppTextStyles.h2),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.gradientPrimary,
                        ),
                        child: Center(
                          child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : "U", 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Main Scan Card
                  Expanded(
                    child: AccessibleWidget(
                      label: "Scan Page. Double tap to open camera options.",
                      onActivate: _showOptionsSheet,
                      child: GlassCard(
                        gradient: AppColors.gradientPrimary,
                        borderGlow: true,
                        onTap: _showOptionsSheet,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.document_scanner_rounded, size: 80, color: Colors.white)
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .scaleXY(begin: 1.0, end: 1.05, duration: 2.seconds),
                              const SizedBox(height: 16),
                              const Text("Scan Page", style: AppTextStyles.h1),
                              const SizedBox(height: 8),
                              const Text("Double-tap or say \"Scan\"", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bottom Row Tiles
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          onTap: _uploadImage,
                          child: Row(
                            children: [
                              const Icon(Icons.folder, color: AppColors.primaryLight, size: 24),
                              const SizedBox(width: 8),
                              Expanded(child: const Text("Upload\nFile", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.history, color: AppColors.accent, size: 24),
                              const SizedBox(width: 8),
                              Expanded(child: const Text("History\nSessions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.warning, size: 24),
                              const SizedBox(width: 8),
                              Expanded(child: const Text("Saved\nItems", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // MARK FAB
          Positioned(
            bottom: 32,
            right: 24,
            child: AccessibleWidget(
              label: "Ask MARK. Double tap to activate.",
              onActivate: _triggerMark,
              child: GestureDetector(
                onTap: _triggerMark,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientWarm,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withOpacity(0.4),
                        blurRadius: _isMarkListening ? 30 : 20,
                        spreadRadius: _isMarkListening ? 10 : 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text("🎙️", style: TextStyle(fontSize: 28)),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .slideY(begin: -0.05, end: 0.05, duration: 2.seconds)
                 .scaleXY(end: _isMarkListening ? 1.2 : 1.0, duration: 300.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
