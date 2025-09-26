import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'https://y2fls39ue8.execute-api.ap-south-1.amazonaws.com/Prod';

  // Add this method to your existing ApiService class
  static Future<Map<String, dynamic>> generateAd({
    required String productName,
    String language = 'English',
    String userContext = 'General',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productName': productName,
          'language': language,
          'userContext': userContext,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate ad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating ad: $e');
    }
  }

  /// Calls the /forge endpoint to start the video generation.
  /// Expects the backend to immediately return a unique 'jobId'.
  static Future<String?> startVideoGenerationJob({
    required Product product,
    required String context,
    String? language, // NEW: Added language parameter
  }) async {
    final Uri startJobUrl = Uri.parse('$_baseUrl/forge');
    try {
      final headers = {'Content-Type': 'application/json'};

      // Updated payload to include language
      final Map<String, dynamic> payload = {
        'sku': product.id,
        'user_context': context,
      };

      // Only add language to payload if it's selected
      if (language != null && language.isNotEmpty) {
        payload['language'] = language;
      }

      final body = json.encode(payload);

      print("🚀 POST /forge with payload: $body");

      final response =
          await http.post(startJobUrl, headers: headers, body: body);

      if (response.statusCode == 202) {
        // 202 Accepted is the correct code here
        final responseData = json.decode(response.body);
        print("✅ Job started successfully with ID: ${responseData['jobId']}");
        return responseData['jobId'];
      } else {
        print(
            "❌ Error starting job: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Network error while starting job: $e");
      return null;
    }
  }

  /// Calls the /status/{jobId} endpoint to check the job's progress.
  static Future<Map<String, dynamic>?> checkJobStatus(
      {required String jobId}) async {
    final Uri statusUrl = Uri.parse('$_baseUrl/status/$jobId');
    try {
      print("...Polling GET /status/$jobId");
      final response = await http.get(statusUrl);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("...Status received: ${responseData['status']}");
        return responseData;
      } else {
        print(
            "❌ Error checking status: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Network error while checking status: $e");
      return null;
    }
  }
}
