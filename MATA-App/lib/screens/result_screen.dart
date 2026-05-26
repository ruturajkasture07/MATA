import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../services/narrator_service.dart';
import '../widgets/accessible_widget.dart';
import '../services/voice_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/markdown_math.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatefulWidget {
  final String sessionId;
  final String explanation;
  final String? audioUrl;
  final List<dynamic>? initialChatHistory;

  const ResultScreen({
    super.key,
    required this.sessionId,
    required this.explanation,
    this.audioUrl,
    this.initialChatHistory,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final List<Map<String, String>> _chatHistory = [];
  bool _isBotThinking = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _isPlaying = false;
  bool _isChattingWithMark = false;
  bool _isExplanationFinished = false;
  
  String _currentVoiceInput = "";
  double _playbackRate = 1.0;
  
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialChatHistory != null) {
      for (var msg in widget.initialChatHistory!) {
        _chatHistory.add({'role': 'user', 'text': msg['user'].toString()});
        _chatHistory.add({'role': 'bot', 'text': msg['bot'].toString()});
      }
      if (_chatHistory.isNotEmpty) {
        _isChattingWithMark = true;
      }
    }
    _initAudio();
    VoiceService().initSpeech();
  }

  void _initAudio() async {
    bool audioSuccess = false;
    
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isExplanationFinished = true;
          });
          NarratorService().playEarcon(Earcon.success);
          NarratorService().speak("Explanation finished. Please complete the comprehension check at the bottom.");
        }
      });
      
      try {
        await _audioPlayer.setSourceUrl(widget.audioUrl!);
        _audioPlayer.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); });
        _audioPlayer.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); });
        audioSuccess = true;
      } catch (e) {
        print("AudioPlayer failed to set source: $e");
        audioSuccess = false;
      }
    }
    
    if (!audioSuccess) {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isExplanationFinished = true;
          });
          NarratorService().playEarcon(Earcon.success);
          NarratorService().speak("Explanation finished. Please complete the comprehension check.");
        }
      });
    }
    _toggleAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    NarratorService().stop();
    _chatController.dispose();
    super.dispose();
  }

  void _toggleAudio() async {
    if (_isPlaying) {
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _audioPlayer.pause();
      } else {
        await _flutterTts.stop();
      }
      setState(() => _isPlaying = false);
      NarratorService().speak("Paused.", interrupt: true);
    } else {
      setState(() => _isPlaying = true);
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _audioPlayer.resume();
      } else {
        String cleanText = widget.explanation.replaceAll(RegExp(r'[*#_~`>\$\\]'), '');
        await _flutterTts.speak(cleanText);
      }
    }
  }

  void _seekAudio(int seconds) async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      final position = await _audioPlayer.getCurrentPosition() ?? Duration.zero;
      final duration = await _audioPlayer.getDuration() ?? const Duration(hours: 1);
      
      var newPosition = position + Duration(seconds: seconds);
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > duration) newPosition = duration;
      
      await _audioPlayer.seek(newPosition);
      NarratorService().speak(seconds > 0 ? "Forwarded." : "Rewound.", interrupt: true);
    } else {
      NarratorService().speak("Seeking only available for streaming audio.");
    }
  }

  void _toggleSpeed() async {
    setState(() {
      if (_playbackRate == 1.0) _playbackRate = 1.5;
      else if (_playbackRate == 1.5) _playbackRate = 2.0;
      else _playbackRate = 1.0;
    });
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      await _audioPlayer.setPlaybackRate(_playbackRate);
    } else {
      await _flutterTts.setSpeechRate(0.5 * _playbackRate);
    }
    NarratorService().speak("Speed ${_playbackRate}x.", interrupt: true);
  }

  void _startChatWithMark() async {
    if (_isPlaying) {
      _toggleAudio();
    }
    setState(() {
      _isChattingWithMark = true;
    });
    NarratorService().playEarcon(Earcon.success);
    NarratorService().speak("I paused the reading. What is your question?");
  }

  void _stopChatWithMark() {
    setState(() {
      _isChattingWithMark = false;
    });
    NarratorService().speak("Returned to learning space.");
  }

  void _askQuestion(String question) async {
    if (question.isNotEmpty) {
      setState(() {
        _chatHistory.add({'role': 'user', 'text': question});
        _isBotThinking = true;
        _chatController.clear();
      });
      NarratorService().speak("You asked: $question");

      try {
        final historyToSend = _chatHistory.length > 6 ? _chatHistory.sublist(_chatHistory.length - 6) : _chatHistory;
        final result = await ApiService.askQuestion(widget.sessionId, question, historyToSend);
        final answerText = result['answer']?.toString() ?? "No answer received.";
        
        if (result['audio_url'] != null && result['audio_url'].toString().isNotEmpty) {
          await _audioPlayer.play(UrlSource(result['audio_url'].toString()));
        }

        setState(() {
          _chatHistory.add({'role': 'bot', 'text': answerText});
        });
        String cleanAnswer = answerText.replaceAll(RegExp(r'[*#_~`>\$\\]'), '');
        NarratorService().speak("MARK says: $cleanAnswer");
      } catch (e) {
        setState(() {
          _chatHistory.add({'role': 'bot', 'text': 'Sorry, error: $e'});
        });
        NarratorService().playEarcon(Earcon.error);
        NarratorService().speak("Sorry, I encountered an error.");
      } finally {
        setState(() {
          _isBotThinking = false;
        });
      }
    }
  }

  void _provideFeedback(String rating) async {
    NarratorService().playEarcon(Earcon.success);
    NarratorService().speak("Feedback recorded. Thank you.");
    try {
      await ApiService.submitFeedback(widget.sessionId, rating);
    } catch (e) {
      print("Feedback error: $e");
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Widget _buildAudioControls() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gradient: AppColors.gradientCard,
      radius: BorderRadius.circular(100),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AccessibleWidget(
            label: "Rewind 10 seconds.",
            onActivate: () => _seekAudio(-10),
            child: IconButton(
              icon: const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 28),
              onPressed: () => _seekAudio(-10),
            ),
          ),
          const SizedBox(width: 8),
          AccessibleWidget(
            label: _isPlaying ? "Pause." : "Play.",
            onActivate: _toggleAudio,
            child: GestureDetector(
              onTap: _toggleAudio,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AccessibleWidget(
            label: "Forward 10 seconds.",
            onActivate: () => _seekAudio(10),
            child: IconButton(
              icon: const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 28),
              onPressed: () => _seekAudio(10),
            ),
          ),
          const SizedBox(width: 8),
          AccessibleWidget(
            label: "Change Speed. Current $_playbackRate x.",
            onActivate: _toggleSpeed,
            child: GestureDetector(
              onTap: _toggleSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Text("${_playbackRate}x", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return AccessibleWidget(
      label: "Comprehension Check. Was this explanation Too Hard, Good, or Too Easy?",
      child: GlassCard(
        borderGlow: true,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Comprehension Check", style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text("How was this explanation?", style: AppTextStyles.bodyMd),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => _provideFeedback("too_hard"),
                  child: Column(
                    children: [
                      const Text("😖", style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      const Text("Too Hard", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _provideFeedback("good"),
                  child: Column(
                    children: [
                      const Text("😊", style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      const Text("Good", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _provideFeedback("too_easy"),
                  child: Column(
                    children: [
                      const Text("🥱", style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      const Text("Too Easy", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLearningSpace() {
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
        title: const Text("Learning Space", style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primary),
            onPressed: () {},
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.8),
                  radius: 1.5,
                  colors: [Color(0xFF1E1B4B), AppColors.bg0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  const SizedBox(height: 16),
                  
                  // Main Content Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: MarkdownBody(
                      data: widget.explanation,
                      builders: {'math': MathElementBuilder()},
                      inlineSyntaxes: [MathSyntax()],
                      blockSyntaxes: [BlockMathSyntax()],
                      styleSheet: MarkdownStyleSheet(
                        p: AppTextStyles.bodyXl,
                        h1: AppTextStyles.h1,
                        h2: AppTextStyles.h2,
                        h3: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        listBullet: AppTextStyles.bodyXl,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  if (_isExplanationFinished) _buildFeedbackCard(),
                ],
              ),
            ),
          ),
          
          // Audio Controls (Floating at bottom center)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: _buildAudioControls().animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutBack),
            ),
          ),
          
          // MARK Chat FAB (Bottom Right)
          Positioned(
            bottom: 32,
            right: 16,
            child: AccessibleWidget(
              label: "Ask MARK a question. Double tap to open chat.",
              onActivate: _startChatWithMark,
              child: GestureDetector(
                onTap: _startChatWithMark,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientPrimary,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)
                    ],
                  ),
                  child: const Center(
                    child: Text("🎙️", style: TextStyle(fontSize: 28)),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.05, duration: 2.seconds),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSpace() {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        leading: AccessibleWidget(
          label: "Back to learning space",
          onActivate: _stopChatWithMark,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _stopChatWithMark,
          ),
        ),
        title: const Text("Chat with MARK", style: AppTextStyles.h2),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                final isUser = chat['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: GlassCard(
                      gradient: isUser ? AppColors.gradientPrimary : null,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        chat['text'] ?? '',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isUser ? FontWeight.w500 : FontWeight.normal),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isBotThinking)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: AppColors.bg1,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a question...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: _askQuestion,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (VoiceService().isListening) {
                      VoiceService().stopListening();
                    } else {
                      NarratorService().playEarcon(Earcon.success);
                      VoiceService().startListening((text) {
                        setState(() => _chatController.text = text);
                        if (text.isNotEmpty) {
                          Future.delayed(const Duration(seconds: 2), () {
                            if (!VoiceService().isListening && _chatController.text == text) {
                              _askQuestion(text);
                            }
                          });
                        }
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: VoiceService().isListening ? AppColors.danger : AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.mic, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _askQuestion(_chatController.text),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isChattingWithMark ? _buildChatSpace() : _buildLearningSpace();
  }
}
