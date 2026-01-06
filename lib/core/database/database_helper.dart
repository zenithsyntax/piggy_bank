import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'piggy_bank.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add remaining_amount to debts
      await db.execute('ALTER TABLE debts ADD COLUMN remaining_amount REAL DEFAULT 0');
      // Initialize remaining_amount = amount for existing records
      await db.execute('UPDATE debts SET remaining_amount = amount');
      
      // Create debt_repayments table
      await db.execute('''
        CREATE TABLE debt_repayments (
          id TEXT PRIMARY KEY,
          debt_id TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          FOREIGN KEY (debt_id) REFERENCES debts (id) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Add reset_day to family_members with default 1
      await db.execute('ALTER TABLE family_members ADD COLUMN reset_day INTEGER DEFAULT 1');
      
      // Add completed_at to debts
      await db.execute('ALTER TABLE debts ADD COLUMN completed_at TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Family Members
    await db.execute('''
      CREATE TABLE family_members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        reset_day INTEGER DEFAULT 1
      )
    ''');

    // 2. Categories
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // 3. Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (member_id) REFERENCES family_members (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 4. Debts
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        member_id TEXT NOT NULL,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        completed_at TEXT,
        FOREIGN KEY (member_id) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');

    // 5. Allowances
    await db.execute('''
      CREATE TABLE allowances (
        id TEXT PRIMARY KEY,
        from_member_id TEXT NOT NULL,
        to_member_id TEXT NOT NULL,
        total_amount REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        status TEXT NOT NULL,
        FOREIGN KEY (from_member_id) REFERENCES family_members (id) ON DELETE CASCADE,
        FOREIGN KEY (to_member_id) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');

    // 6. Allowance Expenses
    await db.execute('''
      CREATE TABLE allowance_expenses (
        id TEXT PRIMARY KEY,
        allowance_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (allowance_id) REFERENCES allowances (id) ON DELETE CASCADE,
         FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 7. Debt Repayments
    await db.execute('''
      CREATE TABLE debt_repayments (
        id TEXT PRIMARY KEY,
        debt_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (debt_id) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final uuid = Uuid();
    
    // Seed Family Member
    final memberId = uuid.v4();
    await db.insert('family_members', {
      'id': memberId,
      'name': 'Me',
      'created_at': DateTime.now().toIso8601String(),
      'reset_day': 1,
    });

    // Seed Categories
    final expenses = ['Food', 'Transport', 'Utilities', 'Entertainment', 'Shopping'];
    for (var name in expenses) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': name,
        'type': 'expense',
      });
    }

    final income = ['Salary', 'Freelance', 'Gift'];
    for (var name in income) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': name,
        'type': 'income',
      });
    }
  }
}
