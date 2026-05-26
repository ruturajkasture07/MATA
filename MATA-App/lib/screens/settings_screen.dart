import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../services/narrator_service.dart';
import '../widgets/accessible_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarratorService().speak("Accessibility Settings.");
    });
  }

  Widget _buildGlassTile({
    required String title,
    String? trailingText,
    Widget? trailingWidget,
    IconData? leadingIcon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return AccessibleWidget(
      label: "$title setting. Double tap to change.",
      onActivate: onTap ?? () {},
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: onTap,
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: iconColor ?? AppColors.primaryLight, size: 24),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            if (trailingText != null)
              Text(trailingText, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            if (trailingWidget != null) trailingWidget,
            if (trailingWidget == null && trailingText == null)
              const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    String textSizeLabel = "Medium";
    if (settings.textSize < 1.0) textSizeLabel = "Small";
    if (settings.textSize > 1.0) textSizeLabel = "Large";

    return Scaffold(
      backgroundColor: AppColors.bg0,
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
        title: const Text('Settings', style: AppTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                const SizedBox(height: 10),
                const Text("Accessibility", style: AppTextStyles.bodyMd).animate().fadeIn(),
                const SizedBox(height: 16),
                
                _buildGlassTile(
                  title: 'High-Contrast Mode',
                  leadingIcon: Icons.contrast_rounded,
                  iconColor: AppColors.warning,
                  trailingWidget: Switch(
                    value: settings.highContrastMode,
                    onChanged: (val) {
                      settings.setHighContrastMode(val);
                      NarratorService().playEarcon(Earcon.success);
                      NarratorService().speak("High contrast mode ${val ? 'enabled' : 'disabled'}.");
                    },
                    activeColor: AppColors.success,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
                
                _buildGlassTile(
                  title: 'Text Size',
                  leadingIcon: Icons.format_size_rounded,
                  iconColor: AppColors.success,
                  trailingText: textSizeLabel,
                  onTap: () {
                    double newSize = 1.0;
                    if (settings.textSize == 1.0) newSize = 1.2;
                    else if (settings.textSize == 1.2) newSize = 0.8;
                    settings.setTextSize(newSize);
                    NarratorService().playEarcon(Earcon.navigate);
                    NarratorService().speak("Text size set to $newSize");
                  },
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                
                const SizedBox(height: 32),
                const Text("Learning Preferences", style: AppTextStyles.bodyMd).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),
                
                _buildGlassTile(
                  title: 'Explanation Mode',
                  leadingIcon: Icons.school_rounded,
                  iconColor: AppColors.primaryLight,
                  trailingText: settings.explanationMode[0].toUpperCase() + settings.explanationMode.substring(1),
                  onTap: () {
                    String newMode = 'teen';
                    if (settings.explanationMode == 'child') newMode = 'teen';
                    else if (settings.explanationMode == 'teen') newMode = 'adult';
                    else if (settings.explanationMode == 'adult') newMode = 'child';
                    settings.setExplanationMode(newMode);
                    NarratorService().playEarcon(Earcon.navigate);
                    NarratorService().speak("Explanation mode set to $newMode");
                  },
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                
                const SizedBox(height: 32),
                const Text("Data Management", style: AppTextStyles.bodyMd).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),
                
                _buildGlassTile(
                  title: 'Clear History',
                  leadingIcon: Icons.delete_sweep_rounded,
                  iconColor: AppColors.danger,
                  onTap: () async {
                    NarratorService().speak("Are you sure you want to delete all past learning sessions? This cannot be undone.", interrupt: true);
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.bg1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.border)),
                        title: const Text('Clear History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: const Text('Are you sure you want to delete all past learning sessions? This cannot be undone.', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (confirm) {
                      NarratorService().playEarcon(Earcon.loading);
                      try {
                        await ApiService.clearHistory();
                        if (mounted) {
                          NarratorService().playEarcon(Earcon.success);
                          NarratorService().speak("History cleared successfully.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('History cleared successfully', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          NarratorService().playEarcon(Earcon.error);
                          NarratorService().speak("Failed to clear history.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to clear history', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    }
                  },
                ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
