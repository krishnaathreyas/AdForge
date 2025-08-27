import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  // Your real, deployed API Gateway endpoint URL
  static const String apiUrl =
      'https://y2fls39ue8.execute-api.ap-south-1.amazonaws.com/Prod/forge/';

  // This is now the main method that calls your backend
  static Future<String?> generateRealVideo({
    required Product product,
    required String context,
  }) async {
    try {
      print("Sending request to backend...");

      final headers = {
        'Content-Type': 'application/json',
        // If your API Gateway requires an API Key, you would add it here
        // 'x-api-key': 'YOUR_API_KEY_GOES_HERE'
      };

      // The backend expects a JSON body with 'sku' and 'context'
      final body = json.encode({
        'sku': product.id, // We use the product's ID field as the SKU
        'context': context,
      });

      // Making the real POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      print("Backend responded with status code: ${response.statusCode}");
      print("Backend response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // The backend returns a JSON with the key "finalVideoUrl"
        return responseData['finalVideoUrl'];
      } else {
        // If the backend returns an error (4xx or 5xx), we'll know
        print('API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // This catches network errors, etc.
      print('A network or parsing error occurred: $e');
      return null;
    }
  }
}
