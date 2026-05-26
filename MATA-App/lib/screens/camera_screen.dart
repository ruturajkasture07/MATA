import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../services/narrator_service.dart';
import '../widgets/accessible_widget.dart';
import '../theme/app_theme.dart';
import 'configuration_screen.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  bool _edgesDetected = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NarratorService().speak(
          "Camera open. Move your phone slightly higher. The bottom third of the screen is the capture zone. Double tap it to capture.", interrupt: true);
          
      // Simulate edge detection after 2 seconds for UI demo
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _edgesDetected = true;
          });
          NarratorService().playEarcon(Earcon.success);
        }
      });
    });
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    }
  }

  Future<void> _launchMLKitScanner() async {
    try {
      DocumentScannerOptions documentOptions = DocumentScannerOptions(
        mode: ScannerMode.filter,
        pageLimit: 1,
        isGalleryImport: false,
      );
      final documentScanner = DocumentScanner(options: documentOptions);
      final DocumentScanningResult result = await documentScanner.scanDocument();
      
      if (result.images != null && result.images!.isNotEmpty) {
        final imagePath = result.images!.first;
        HapticFeedback.heavyImpact();
        NarratorService().playEarcon(Earcon.capture);
        NarratorService().speak("Page scanned.");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ConfigurationScreen(imagePath: imagePath)),
        );
      }
    } catch (e) {
      NarratorService().speak("Auto scanner cancelled.");
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;

    try {
      final image = await _controller!.takePicture();
      HapticFeedback.heavyImpact();
      NarratorService().playEarcon(Earcon.capture);
      NarratorService().speak("Page captured manually.");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ConfigurationScreen(imagePath: image.path)),
      );
    } catch (e) {
      NarratorService().speak("Error capturing image.");
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildCorner(Alignment alignment, bool isTop, bool isLeft) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: AppColors.primaryLight, width: 4) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: AppColors.primaryLight, width: 4) : BorderSide.none,
            left: isLeft ? BorderSide(color: AppColors.primaryLight, width: 4) : BorderSide.none,
            right: !isLeft ? BorderSide(color: AppColors.primaryLight, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview Viewfinder
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.3,
            child: _isReady && _controller != null
                ? ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.previewSize?.height ?? 1,
                          height: _controller!.value.previewSize?.width ?? 1,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A2030), Color(0xFF0D1520)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
          ),
          
          // Viewfinder Guidelines
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.3,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _edgesDetected ? AppColors.success : AppColors.primary.withOpacity(0.8), 
                        width: 2
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        _buildCorner(Alignment.topLeft, true, true),
                        _buildCorner(Alignment.topRight, true, false),
                        _buildCorner(Alignment.bottomLeft, false, true),
                        _buildCorner(Alignment.bottomRight, false, false),
                        const Center(
                          child: Text("📖", style: TextStyle(fontSize: 32, color: Colors.white24)),
                        )
                      ],
                    ),
                  ).animate(target: _edgesDetected ? 1 : 0).tint(color: AppColors.success.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  if (_edgesDetected)
                    const Text("Edges detected ✓", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold))
                        .animate().fadeIn().slideY(begin: 0.2),
                ],
              ),
            ),
          ),
          
          // Top Bar (Back Button)
          Positioned(
            top: 48,
            left: 16,
            child: AccessibleWidget(
              label: "Back. Double tap to return to home.",
              onActivate: () => Navigator.pop(context),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: const Center(
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Auto Scan button (ML Kit)
          Positioned(
            top: 48,
            right: 16,
            child: AccessibleWidget(
              label: "Auto Scan. Double tap to use auto edge detection scanner.",
              onActivate: _launchMLKitScanner,
              child: GestureDetector(
                onTap: _launchMLKitScanner,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Row(
                        children: const [
                          Icon(Icons.document_scanner, color: AppColors.accent, size: 16),
                          SizedBox(width: 8),
                          Text("Auto Scan", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Capture Zone
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: AccessibleWidget(
              label: "Capture Image. Double tap anywhere in this bottom area.",
              onActivate: _captureImage,
              child: GestureDetector(
                onTap: _captureImage,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.95),
                        AppColors.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              spreadRadius: 6,
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scaleXY(end: 1.05, duration: 1000.ms),
                      const SizedBox(height: 16),
                      const Text(
                        "Double-tap anywhere here to capture",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
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
