/// Model representing a customer visit/activity entry linking a customer to a date and activity status.
class CustomerVisit {
  final int? id;
  final int customerId;
  final String date; // format 'yyyy-MM-dd'
  final String status; // 'Active' (Buyer), 'Pending' (Visitor), 'Inactive' (None)
  final String? customerName; // Populated from JOIN queries (not stored)

  CustomerVisit({
    this.id,
    required this.customerId,
    required this.date,
    required this.status,
    this.customerName,
  });

  /// Convert CustomerVisit to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'date': date,
      'status': status,
    };
  }

  /// Create a CustomerVisit from a database Map
  factory CustomerVisit.fromMap(Map<String, dynamic> map) {
    return CustomerVisit(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      date: map['date'] as String,
      status: map['status'] as String,
      customerName: map['customer_name'] as String?,
    );
  }

  /// Create a copy of CustomerVisit with some fields replaced
  CustomerVisit copyWith({String? status}) {
    return CustomerVisit(
      id: id,
      customerId: customerId,
      date: date,
      status: status ?? this.status,
      customerName: customerName,
    );
  }
}
