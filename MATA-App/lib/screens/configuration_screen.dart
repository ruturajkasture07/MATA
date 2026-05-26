import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/narrator_service.dart';
import '../widgets/accessible_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 'result_screen.dart';

class ConfigurationScreen extends StatefulWidget {
  final String imagePath;
  final bool isPdf;
  const ConfigurationScreen({super.key, required this.imagePath, this.isPdf = false});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  String? _selectedLevel;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedLevel == null) {
      _selectedLevel = Provider.of<SettingsProvider>(context, listen: false).explanationMode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NarratorService().speak("Reading level configuration. Current level is $_selectedLevel. Double tap a card to change it.", interrupt: true);
      });
    }
  }

  void _selectLevel(String level) {
    setState(() {
      _selectedLevel = level;
    });
    Provider.of<SettingsProvider>(context, listen: false).setExplanationMode(level);
    NarratorService().playEarcon(Earcon.navigate);
    NarratorService().speak("$level level selected.");
  }

  Future<void> _processImage() async {
    setState(() => _isProcessing = true);
    NarratorService().playEarcon(Earcon.loading);
    NarratorService().speak("Analyzing with AI. Please wait.", interrupt: true);
    
    try {
      final result = widget.isPdf 
          ? await ApiService.processPdf(widget.imagePath, _selectedLevel!)
          : await ApiService.processImage(widget.imagePath, _selectedLevel!);
          
      if (!mounted) return;
      NarratorService().playEarcon(Earcon.success);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            sessionId: result['session_id'],
            explanation: result['explanation'],
            audioUrl: result['audio_url'],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      NarratorService().playEarcon(Earcon.error);
      NarratorService().speak("Error processing image.");
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildLevelCard(String level, String label, String desc, String emoji) {
    final isSelected = _selectedLevel == level;
    return AccessibleWidget(
      label: "$label level. $desc. Double tap to select.",
      onActivate: () => _selectLevel(level),
      child: GlassCard(
        borderGlow: isSelected,
        gradient: isSelected ? AppColors.gradientCard : null,
        onTap: () => _selectLevel(level),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 28)
                  .animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: AccessibleWidget(
          label: "Back",
          onActivate: () => Navigator.pop(context),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reading Level", style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  const Text("How should MARK explain this page?", style: AppTextStyles.bodyMd),
                  const SizedBox(height: 32),
                  
                  Expanded(
                    child: ListView(
                      children: [
                        _buildLevelCard("child", "Child (Age 8–12)", "Simple words, fun analogies", "🐣"),
                        _buildLevelCard("teen", "Teen (Age 13–16)", "Standard school vocabulary", "📚"),
                        _buildLevelCard("adult", "Adult / Expert", "Technical college-level", "🎓"),
                      ],
                    ),
                  ),
                  
                  AccessibleWidget(
                    label: "Analyze with AI. Double tap to process the image.",
                    onActivate: _isProcessing ? () {} : _processImage,
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _processImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: _isProcessing
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                ),
                              )
                            : const Text(
                                "▶ ANALYZE WITH AI",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
