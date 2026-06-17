import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/api_post.dart';
import '../models/customer_visit.dart';
import '../utils/constants.dart';

/// DatabaseHelper manages the local SQLite database for FreshMart.
/// Implements the Singleton pattern so only one database instance exists.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  /// Get or initialize the database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: 4, // Bumped to 4 for customer visits table and dropping students/attendance tables
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables on first launch (fresh install)
  Future<void> _onCreate(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCustomers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        address TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Posts cache table for offline networking support
    await db.execute('''
      CREATE TABLE ${AppConstants.tablePostsCache} (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Customer visits table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCustomerVisits} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES ${AppConstants.tableCustomers}(id)
          ON DELETE CASCADE
      )
    ''');
  }

  /// Handle database version upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.tablePostsCache} (
          id INTEGER PRIMARY KEY,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // In version 3, students and attendance tables were added
      await db.execute('DROP TABLE IF EXISTS students');
      await db.execute('DROP TABLE IF EXISTS attendance');
    }
    if (oldVersion < 4) {
      // Migration to version 4: Create customer_visits table and clean up students/attendance
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.tableCustomerVisits} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES ${AppConstants.tableCustomers}(id)
            ON DELETE CASCADE
        )
      ''');
      await db.execute('DROP TABLE IF EXISTS students');
      await db.execute('DROP TABLE IF EXISTS attendance');
    }
  }

  // ─── CUSTOMER CRUD OPERATIONS ──────────────────────────────────────────────

  /// Insert a new customer into the database
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableCustomers,
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Get all registered customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(AppConstants.tableCustomers, orderBy: 'created_at DESC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Search customers by name or email
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableCustomers,
      where: 'full_name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Find a customer by email (for login validation)
  Future<Customer?> getCustomerByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableCustomers,
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Check if an email is already registered
  Future<bool> emailExists(String email) async {
    final customer = await getCustomerByEmail(email.trim().toLowerCase());
    return customer != null;
  }

  /// Update customer details
  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      AppConstants.tableCustomers,
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Delete a customer by ID
  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableCustomers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total number of registered customers
  Future<int> getCustomerCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.tableCustomers}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── POSTS CACHE (Offline Networking Integration) ─────────────────────────

  /// Cache a list of posts fetched from the API into SQLite.
  Future<void> cachePosts(List<ApiPost> posts) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    batch.delete(AppConstants.tablePostsCache);

    for (final post in posts) {
      final map = post.toMap();
      map['cached_at'] = now;
      batch.insert(
        AppConstants.tablePostsCache,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Retrieve all cached posts from SQLite.
  Future<List<ApiPost>> getCachedPosts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tablePostsCache,
      orderBy: 'id ASC',
    );
    return maps.map((map) => ApiPost.fromMap(map)).toList();
  }

  /// Insert a single post into the local cache.
  Future<int> insertCachedPost(ApiPost post) async {
    final db = await database;
    final map = post.toMap();
    map['cached_at'] = DateTime.now().toIso8601String();
    return await db.insert(
      AppConstants.tablePostsCache,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update a cached post in SQLite.
  Future<int> updateCachedPost(ApiPost post) async {
    final db = await database;
    final map = post.toMap();
    map['cached_at'] = DateTime.now().toIso8601String();
    return await db.update(
      AppConstants.tablePostsCache,
      map,
      where: 'id = ?',
      whereArgs: [post.id],
    );
  }

  /// Delete a cached post from SQLite.
  Future<int> deleteCachedPost(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tablePostsCache,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear the entire posts cache.
  Future<int> clearPostsCache() async {
    final db = await database;
    return await db.delete(AppConstants.tablePostsCache);
  }

  /// Get the number of cached posts.
  Future<int> getCachedPostCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.tablePostsCache}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get the timestamp of the last cache update.
  Future<String?> getLastCacheTime() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT MAX(cached_at) as last_cached FROM ${AppConstants.tablePostsCache}');
    if (result.isEmpty || result.first['last_cached'] == null) return null;
    return result.first['last_cached'] as String;
  }

  /// Close the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ─── CUSTOMER VISITS CRUD OPERATIONS ───────────────────────────────────────

  /// Save customer visits for a list of customers on a given date.
  Future<void> saveCustomerVisitsBatch(List<CustomerVisit> records) async {
    final db = await database;
    final batch = db.batch();

    for (final record in records) {
      // Delete any existing record for this customer on this date
      batch.delete(
        AppConstants.tableCustomerVisits,
        where: 'customer_id = ? AND date = ?',
        whereArgs: [record.customerId, record.date],
      );
      // Insert the new record
      batch.insert(
        AppConstants.tableCustomerVisits,
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get customer visit records for a specific date (with customer names via JOIN).
  Future<List<CustomerVisit>> getCustomerVisitsByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT v.*, c.full_name as customer_name
      FROM ${AppConstants.tableCustomerVisits} v
      INNER JOIN ${AppConstants.tableCustomers} c ON v.customer_id = c.id
      WHERE v.date = ?
      ORDER BY c.full_name ASC
    ''', [date]);
    return maps.map((map) => CustomerVisit.fromMap(map)).toList();
  }

  /// Get all visits recorded for a specific customer.
  Future<List<CustomerVisit>> getCustomerVisitsByCustomer(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableCustomerVisits,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => CustomerVisit.fromMap(map)).toList();
  }

  /// Get customer visits summary report for all registered customers.
  Future<List<Map<String, dynamic>>> getCustomerVisitsReport() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.id as customer_id,
        c.full_name as customer_name,
        c.email as customer_email,
        COUNT(v.id) as total,
        SUM(CASE WHEN v.status = 'Active' THEN 1 ELSE 0 END) as active_count,
        SUM(CASE WHEN v.status = 'Pending' THEN 1 ELSE 0 END) as pending_count,
        SUM(CASE WHEN v.status = 'Inactive' THEN 1 ELSE 0 END) as inactive_count
      FROM ${AppConstants.tableCustomers} c
      LEFT JOIN ${AppConstants.tableCustomerVisits} v ON c.id = v.customer_id
      GROUP BY c.id
      ORDER BY c.full_name ASC
    ''');
  }

  /// Get overall customer visit statistics.
  Future<Map<String, int>> getCustomerVisitsStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_records,
        SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) as active_count,
        SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) as pending_count,
        SUM(CASE WHEN status = 'Inactive' THEN 1 ELSE 0 END) as inactive_count
      FROM ${AppConstants.tableCustomerVisits}
    ''');
    if (result.isEmpty) {
      return {'total_records': 0, 'active_count': 0, 'pending_count': 0, 'inactive_count': 0};
    }
    final row = result.first;
    return {
      'total_records': (row['total_records'] as int?) ?? 0,
      'active_count': (row['active_count'] as int?) ?? 0,
      'pending_count': (row['pending_count'] as int?) ?? 0,
      'inactive_count': (row['inactive_count'] as int?) ?? 0,
    };
  }

  /// Check if visits have been recorded for a specific date.
  Future<bool> hasCustomerVisitsForDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableCustomerVisits} WHERE date = ?',
      [date],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  /// Get all unique dates for which customer visits have been recorded.
  Future<List<String>> getCustomerVisitsDates() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT date FROM ${AppConstants.tableCustomerVisits} ORDER BY date DESC',
    );
    return result.map((row) => row['date'] as String).toList();
  }
}
