import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_user.dart';
import '../models/api_post.dart';
import '../utils/constants.dart';

/// Week 5 & 6 — API Service (Singleton)
/// Handles all HTTP networking for FreshMart.
///
/// Week 5: GET requests to /users
/// Week 6: Full CRUD — GET, POST, PUT, DELETE on /posts
///
/// Uses the JSONPlaceholder public REST API (https://jsonplaceholder.typicode.com).
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  /// Standard headers sent with every request.
  /// 'Content-Type: application/json' tells the server we are sending JSON.
  /// 'Accept: application/json' tells the server we expect JSON back.
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Standard timeout duration for all requests.
  static const Duration _timeout = Duration(seconds: 10);

  // ═══════════════════════════════════════════════════════════════════════════
  // WEEK 5 — Users (GET only)
  // ═══════════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════════
  // WEEK 6 — Posts (Full CRUD: GET, POST, PUT, DELETE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// ── GET /posts ─────────────────────────────────────────────────────────────
  /// Fetches all posts from the REST API.
  ///
  /// HTTP Method : GET
  /// Endpoint    : https://jsonplaceholder.typicode.com/posts
  /// Status Code : 200 OK on success
  ///
  /// Returns a [List<ApiPost>] parsed from the JSON array response.
  Future<List<ApiPost>> fetchPosts() async {
    try {
      final uri = Uri.parse(AppConstants.apiPostsUrl);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout, onTimeout: () => throw Exception(
              'Request timed out. Please check your internet connection.'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List;
        return jsonList
            .map((json) => ApiPost.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(_errorMessage(response.statusCode));
      }
    } on FormatException {
      throw Exception('Failed to parse server response.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// ── POST /posts ────────────────────────────────────────────────────────────
  /// Creates a new post on the server.
  ///
  /// HTTP Method : POST
  /// Endpoint    : https://jsonplaceholder.typicode.com/posts
  /// Request Body: JSON { userId, title, body }
  /// Status Code : 201 Created on success
  ///
  /// Returns the created [ApiPost] with the server-assigned id.
  Future<ApiPost> createPost(ApiPost post) async {
    try {
      final uri = Uri.parse(AppConstants.apiPostsUrl);

      // Encode the post object to a JSON string for the request body
      final jsonBody = jsonEncode(post.toJson());

      final response = await _client
          .post(uri, headers: _headers, body: jsonBody)
          .timeout(_timeout, onTimeout: () => throw Exception(
              'Request timed out. Please check your internet connection.'));

      if (response.statusCode == 201) {
        // 201 Created — parse the returned post (includes server-assigned id)
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiPost.fromJson(json);
      } else {
        throw Exception(_errorMessage(response.statusCode));
      }
    } on FormatException {
      throw Exception('Failed to parse server response.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// ── PUT /posts/{id} ───────────────────────────────────────────────────────
  /// Updates an existing post on the server (full replacement).
  ///
  /// HTTP Method : PUT
  /// Endpoint    : https://jsonplaceholder.typicode.com/posts/{id}
  /// Request Body: JSON { id, userId, title, body }
  /// Status Code : 200 OK on success
  ///
  /// Returns the updated [ApiPost].
  Future<ApiPost> updatePost(ApiPost post) async {
    try {
      final uri = Uri.parse('${AppConstants.apiPostsUrl}/${post.id}');

      final jsonBody = jsonEncode(post.toJson());

      final response = await _client
          .put(uri, headers: _headers, body: jsonBody)
          .timeout(_timeout, onTimeout: () => throw Exception(
              'Request timed out. Please check your internet connection.'));

      if (response.statusCode == 200) {
        // 200 OK — parse the updated post
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiPost.fromJson(json);
      } else {
        throw Exception(_errorMessage(response.statusCode));
      }
    } on FormatException {
      throw Exception('Failed to parse server response.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// ── DELETE /posts/{id} ────────────────────────────────────────────────────
  /// Deletes a post from the server.
  ///
  /// HTTP Method : DELETE
  /// Endpoint    : https://jsonplaceholder.typicode.com/posts/{id}
  /// Request Body: None (empty)
  /// Status Code : 200 OK on success
  ///
  /// Returns true if deletion was successful.
  Future<bool> deletePost(int id) async {
    try {
      final uri = Uri.parse('${AppConstants.apiPostsUrl}/$id');

      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(_timeout, onTimeout: () => throw Exception(
              'Request timed out. Please check your internet connection.'));

      // JSONPlaceholder returns 200 for successful DELETE
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(_errorMessage(response.statusCode));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ─── Helper: Map HTTP status codes to user-friendly error messages ────────

  String _errorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Error 400: Bad request. Please check your data.';
      case 401:
        return 'Error 401: Unauthorized access.';
      case 403:
        return 'Error 403: Access forbidden.';
      case 404:
        return 'Error 404: Resource not found.';
      case 500:
        return 'Error 500: Internal server error. Try again later.';
      case 503:
        return 'Error 503: Service unavailable. Try again later.';
      default:
        return 'Unexpected error: HTTP $statusCode';
    }
  }

  void dispose() => _client.close();
}
