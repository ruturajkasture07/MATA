import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _highContrastMode = false;
  double _textSize = 1.0;
  String _explanationMode = 'teen';

  bool get highContrastMode => _highContrastMode;
  double get textSize => _textSize;
  String get explanationMode => _explanationMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _highContrastMode = prefs.getBool('high_contrast_mode') ?? false;
    _textSize = prefs.getDouble('text_size') ?? 1.0;
    _explanationMode = prefs.getString('explanation_mode') ?? 'teen';
    notifyListeners();
  }

  Future<void> setHighContrastMode(bool value) async {
    _highContrastMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast_mode', value);
    notifyListeners();
  }

  Future<void> setTextSize(double value) async {
    _textSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_size', value);
    notifyListeners();
  }

  Future<void> setExplanationMode(String value) async {
    _explanationMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('explanation_mode', value);
    notifyListeners();
  }
}
