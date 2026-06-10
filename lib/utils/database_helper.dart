import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
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
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Create database tables on first launch
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

  /// Search customers by name or email (Week 4 — search functionality)
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
  /// Uses COLLATE NOCASE to handle case differences (e.g. Kevin@ vs kevin@)
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

  /// Close the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
