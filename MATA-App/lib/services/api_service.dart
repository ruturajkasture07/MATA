import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:io';

class ApiService {
  static String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const Duration timeoutDuration = Duration(seconds: 90); // Increased to 90s for slow AI processing

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final customIp = prefs.getString('server_ip');
    if (customIp != null && customIp.isNotEmpty) {
      baseUrl = 'http://$customIp:8000/api/v1';
    }
  }

  static Future<void> updateServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    baseUrl = 'http://$ip:8000/api/v1';
  }

  static Future<void> logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required int age,
    required bool isBlind,
    required String email,
    required String mobileNo,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': name,
            'username': username,
            'age': age,
            'is_blind': isBlind,
            'email': email,
            'mobile_no': mobileNo,
            'password': password,
          }),
        )
        .timeout(timeoutDuration);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          json.decode(response.body)['error'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password}),
        )
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      const storage = FlutterSecureStorage();
      if (data['access_token'] != null) {
        await storage.write(key: 'access_token', value: data['access_token']);
      }
      return data;
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> processImage(
      String imagePath, String ageLevel) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/process'));
      request.fields['age_level'] = ageLevel;
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send().timeout(timeoutDuration);
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('UNAUTHORIZED');
      } else {
        throw Exception('Failed to process image: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. The server took too long to respond.');
    } on SocketException {
      throw Exception('Network error. Could not connect to the server.');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<Map<String, dynamic>> processPdf(
      String filePath, String ageLevel) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/process_pdf'));
      request.fields['age_level'] = ageLevel;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send().timeout(timeoutDuration);
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('UNAUTHORIZED');
      } else {
        throw Exception('Failed to process PDF: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. The server took too long to respond.');
    } on SocketException {
      throw Exception('Network error. Could not connect to the server.');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<Map<String, dynamic>> askQuestion(
      String sessionId, String question, List<dynamic> history) async {
    final headers = await _getHeaders();
    var response = await http
        .post(
          Uri.parse('$baseUrl/qa'),
          headers: headers,
          body: json.encode({
            'session_id': sessionId,
            'question': question,
            'history': history,
          }),
        )
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    } else {
      throw Exception('Failed to ask question');
    }
  }

  static Future<List<dynamic>> getHistory() async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/sessions'), headers: headers)
        .timeout(timeoutDuration);
    if (response.statusCode == 200) {
      return json.decode(response.body)['sessions'] ?? [];
    } else if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    }
    throw Exception('Failed to load history');
  }

  static Future<void> deleteHistory(String sessionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sessions/$sessionId'),
      headers: await _getHeaders(),
    ).timeout(timeoutDuration);
    
    if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to delete history');
    }
  }

  static Future<void> clearHistory() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sessions'),
      headers: await _getHeaders(),
    ).timeout(timeoutDuration);
    
    if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    } else if (response.statusCode != 200) {
      throw Exception('Failed to clear history');
    }
  }

  static Future<void> updateProfile(String name, int age, bool isBlind) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/profile'));
    request.fields['name'] = name;
    request.fields['age'] = age.toString();
    request.fields['is_blind'] = isBlind.toString();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    var response = await request.send().timeout(timeoutDuration);
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  static Future<String?> uploadProfilePicture(String filePath) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/profile/picture'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    var response = await request.send().timeout(timeoutDuration);
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      return data['profile_picture'];
    }
    return null;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/profile'), headers: headers)
        .timeout(timeoutDuration);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      await logout();
      throw Exception('UNAUTHORIZED');
    }
    throw Exception('Failed to load profile');
  }

  static Future<void> submitFeedback(String sessionId, String rating) async {
    final headers = await _getHeaders();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/feedback'));
    request.fields['session_id'] = sessionId;
    request.fields['rating'] = rating;
    if (headers['Authorization'] != null) {
      request.headers['Authorization'] = headers['Authorization']!;
    }
    var response = await request.send().timeout(timeoutDuration);
    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback');
    }
  }
}
