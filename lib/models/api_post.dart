/// Week 6 — API Post Model
/// Represents a post from the JSONPlaceholder REST API.
/// Supports both JSON serialization (for HTTP requests/responses)
/// and Map serialization (for SQLite offline caching).
class ApiPost {
  final int? id;
  final int userId;
  final String title;
  final String body;

  ApiPost({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  // ─── JSON Serialization (for HTTP / REST API) ─────────────────────────────

  /// Parse an ApiPost from the JSON map returned by the API.
  /// Used when decoding GET responses.
  factory ApiPost.fromJson(Map<String, dynamic> json) {
    return ApiPost(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  /// Convert to a JSON-compatible map for POST and PUT request bodies.
  /// The 'id' is excluded for POST (server assigns it) but included for PUT.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'userId': userId,
      'title': title,
      'body': body,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // ─── SQLite Serialization (for offline caching) ───────────────────────────

  /// Convert to a Map for inserting/updating in the SQLite posts_cache table.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
    };
  }

  /// Create an ApiPost from a SQLite database row.
  factory ApiPost.fromMap(Map<String, dynamic> map) {
    return ApiPost(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
    );
  }

  /// Create a copy of this post with modified fields.
  /// Useful for updating posts (e.g. editing title or body).
  ApiPost copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
  }) {
    return ApiPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  @override
  String toString() => 'ApiPost{id: $id, userId: $userId, title: $title}';
}
