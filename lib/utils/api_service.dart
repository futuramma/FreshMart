import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_user.dart';
import '../utils/constants.dart';

/// Week 5 — API Service
/// Handles all HTTP networking for FreshMart.
/// Makes async GET requests to the JSONPlaceholder public REST API.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  /// Fetch the list of users from JSONPlaceholder API.
  /// HTTP Method: GET
  /// Endpoint: https://jsonplaceholder.typicode.com/users
  ///
  /// Returns a list of [ApiUser] objects on success.
  /// Throws a descriptive [Exception] on failure.
  Future<List<ApiUser>> fetchUsers() async {
    try {
      final uri = Uri.parse(AppConstants.apiUsersUrl);

      // Make the GET request with a 10-second timeout
      final response = await _client
          .get(uri, headers: {'Content-Type': 'application/json'}).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception(
            'Request timed out. Please check your internet connection.'),
      );

      // Handle HTTP status codes
      if (response.statusCode == 200) {
        // 200 OK — parse the JSON body
        final List<dynamic> jsonList = jsonDecode(response.body) as List;
        return jsonList
            .map((json) => ApiUser.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        throw Exception('Error 404: Resource not found.');
      } else if (response.statusCode == 401) {
        throw Exception('Error 401: Unauthorized access.');
      } else if (response.statusCode == 500) {
        throw Exception('Error 500: Internal server error. Try again later.');
      } else {
        throw Exception(
            'Unexpected error: HTTP ${response.statusCode}');
      }
    } on FormatException {
      throw Exception('Failed to parse server response.');
    } catch (e) {
      // Re-throw with context if not already an Exception
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  void dispose() => _client.close();
}
