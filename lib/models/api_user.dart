/// Week 5 — API User Model
/// Represents a user record returned from the JSONPlaceholder REST API.
/// Maps the JSON response fields to a Dart object.
class ApiUser {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final String companyName;
  final String city;

  ApiUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.companyName,
    required this.city,
  });

  /// Parse an ApiUser from the JSON map returned by the API
  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      companyName: (json['company'] as Map<String, dynamic>)['name'] as String,
      city: (json['address'] as Map<String, dynamic>)['city'] as String,
    );
  }

  @override
  String toString() => 'ApiUser{id: $id, name: $name, email: $email}';
}
