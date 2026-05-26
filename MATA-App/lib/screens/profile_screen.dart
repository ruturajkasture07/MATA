import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../services/narrator_service.dart';
import '../services/api_service.dart';
import '../widgets/accessible_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = "Student";
  String _name = "Learner";
  int _age = 15;
  String _isBlind = 'no';
  String? _profilePicUrl;
  
  // Dummy Stats
  final int _streak = 14;
  final int _totalSessions = 42;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileData = await ApiService.getProfile();
      setState(() {
        _username = profileData['username'] ?? "Guest";
        _name = profileData['name'] ?? "Learner";
        _age = profileData['age'] ?? 15;
        _isBlind = profileData['is_blind'] == true ? 'yes' : 'no';
        _profilePicUrl = profileData['profile_picture'];
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _username);
      await prefs.setString('name', _name);
      await prefs.setInt('age', _age);
      await prefs.setString('is_blind', _isBlind);
      if (_profilePicUrl != null) await prefs.setString('profile_picture', _profilePicUrl!);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString('username') ?? "Guest";
        _name = prefs.getString('name') ?? "Learner";
        _age = prefs.getInt('age') ?? 15;
        _isBlind = prefs.getString('is_blind') ?? 'no';
        _profilePicUrl = prefs.getString('profile_picture');
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarratorService().speak("Profile screen. Logged in as $_name.");
    });
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final newUrl = await ApiService.uploadProfilePicture(pickedFile.path);
        if (newUrl != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_picture', newUrl);
          setState(() {
            _profilePicUrl = newUrl;
          });
          NarratorService().playEarcon(Earcon.success);
          NarratorService().speak("Profile picture updated.");
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload picture: $e')));
      }
    }
  }

  Future<void> _logout() async {
    NarratorService().playEarcon(Earcon.success);
    NarratorService().speak("Logging out.");
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return AccessibleWidget(
      label: "$title. Double tap to open.",
      onActivate: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.bg0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -60),
              child: Column(
                children: [
                  // Avatar
                  AccessibleWidget(
                    label: "Profile picture. Double tap to change.",
                    onActivate: _uploadProfilePicture,
                    child: GestureDetector(
                      onTap: _uploadProfilePicture,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.gradientCard,
                              border: Border.all(color: AppColors.primary, width: 4),
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 24, spreadRadius: 4)],
                            ),
                            child: ClipOval(
                              child: _profilePicUrl != null && _profilePicUrl!.startsWith('http')
                                  ? Image.network(_profilePicUrl!, fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, trace) => const Center(child: Text("U", style: TextStyle(fontSize: 48, color: Colors.white))))
                                  : Center(child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : "U", style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold))),
                            ),
                          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                          
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle, border: Border.all(color: AppColors.bg0, width: 3)),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ).animate().scale(delay: 300.ms),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Name and Username
                  Text(_name, style: AppTextStyles.h1).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 4),
                  Text("@$_username", style: AppTextStyles.bodyMd).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 32),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Stats Row
                        Row(
                          children: [
                            _buildStatCard("Day Streak", "$_streak 🔥", Icons.local_fire_department, AppColors.warning),
                            const SizedBox(width: 16),
                            _buildStatCard("Total Sessions", "$_totalSessions 📖", Icons.history_edu, AppColors.accent),
                          ],
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 32),
                        
                        // Menu
                        _buildMenuItem("Edit Profile", Icons.person, AppColors.primaryLight, () {}).animate().fadeIn(delay: 500.ms),
                        _buildMenuItem("Accessibility", Icons.accessibility_new, AppColors.accent, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                        }).animate().fadeIn(delay: 600.ms),
                        _buildMenuItem("Data & Privacy", Icons.security, AppColors.warning, () {}).animate().fadeIn(delay: 700.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Logout
                        AccessibleWidget(
                          label: "Logout. Double tap to sign out.",
                          onActivate: _logout,
                          child: GlassCard(
                            onTap: _logout,
                            borderGlow: true,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Center(
                              child: Text("LOGOUT", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                            ),
                          ),
                        ).animate().fadeIn(delay: 800.ms),
                        
                        const SizedBox(height: 48),
                      ],
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
