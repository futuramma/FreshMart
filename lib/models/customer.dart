/// Customer model representing a registered FreshMart user
class Customer {
  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String address;
  final String createdAt;

  Customer({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.address,
    required this.createdAt,
  });

  /// Convert Customer to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'address': address,
      'created_at': createdAt,
    };
  }

  /// Create a Customer from a database Map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      password: map['password'] as String,
      address: map['address'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  /// Copy with modified fields
  Customer copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? address,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, fullName: $fullName, email: $email}';
  }
}
