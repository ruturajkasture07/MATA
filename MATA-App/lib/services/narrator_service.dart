import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

enum Earcon { success, error, navigate, capture, loading }

class NarratorService {
  static final NarratorService _instance = NarratorService._internal();
  factory NarratorService() => _instance;

  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Queue<String> _queue = Queue<String>();
  
  bool _isPlaying = false;
  String _currentText = "";

  NarratorService._internal() {
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _currentText = "";
      _playNextInQueue();
    });
  }

  Future<void> setSpeed(double rate) async {
    await flutterTts.setSpeechRate(rate);
  }

  Future<void> playEarcon(Earcon type) async {
    // In a real app, these would map to actual sound files in assets/audio/
    // For now, we simulate earcons with a very short TTS pip or just log if no assets exist.
    // If you have actual assets, you can use: await _audioPlayer.play(AssetSource('audio/${type.name}.mp3'));
    print("Playing earcon: ${type.name}");
  }

  Future<void> speak(String text, {bool interrupt = true}) async {
    if (text.isEmpty) return;

    if (interrupt) {
      _queue.clear();
      await stop();
      _queue.add(text);
      _playNextInQueue();
    } else {
      _queue.add(text);
      if (!_isPlaying) {
        _playNextInQueue();
      }
    }
  }

  void _playNextInQueue() async {
    if (_queue.isNotEmpty && !_isPlaying) {
      _isPlaying = true;
      _currentText = _queue.removeFirst();
      await flutterTts.speak(_currentText);
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _currentText = "";
    _queue.clear();
    await flutterTts.stop();
  }
}
