import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5050';
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final session = SupabaseService().client.auth.currentSession;
    String? token = session?.accessToken;
    
    // Fallback to stored token if session is null
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
    }

    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getAgents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/agents'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        // Try to refresh token
        await SupabaseService().client.auth.refreshSession();
        // Retry with new token
        final newHeaders = await _getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/api/v1/agents'),
          headers: newHeaders,
        );
        
        if (retryResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(retryResponse.body);
          return data.cast<Map<String, dynamic>>();
        }
        throw Exception('Failed to fetch agents: ${retryResponse.statusCode}');
      } else {
        throw Exception('Failed to fetch agents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching agents: $e');
    }
  }
}
