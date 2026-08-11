import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

/// Lokal SQLite bazasi — ilovaning yagona doimiy xotirasi.
///
/// Server, VPS yoki PostgreSQL kerak emas: barcha jadvallar telefon ichida
/// yaratiladi va birinchi ishga tushirishda katalog seed qilinadi.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const int schemaVersion = 1;
  static const String fileName = 'texno_bozor.db';

  static AppDatabase? _instance;

  /// Telefonda ishlaydigan standart baza (sqflite).
  static Future<AppDatabase> open() async {
    final existing = _instance;
    if (existing != null) return existing;

    final dir = await getDatabasesPath();
    final path = p.join(dir, fileName);
    final db = await openDatabase(
      path,
      version: schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    final instance = AppDatabase._(db);
    _instance = instance;
    return instance;
  }

  /// Testlar va boshqa muhitlar uchun: tayyor factory bilan ochish.
  static Future<AppDatabase> openWith(
    DatabaseFactory factory, {
    String path = inMemoryDatabasePath,
  }) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return AppDatabase._(db);
  }

  Future<void> close() async {
    await db.close();
    if (identical(_instance, this)) _instance = null;
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    // Sxema hozircha 1-versiyada; kelajakdagi migratsiyalar shu yerga qo'shiladi.
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE categories (
        id    TEXT PRIMARY KEY,
        name  TEXT NOT NULL,
        image TEXT NOT NULL DEFAULT '',
        grp   TEXT NOT NULL DEFAULT '',
        sort  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE products (
        id           TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        brand        TEXT NOT NULL DEFAULT '',
        category_id  TEXT NOT NULL DEFAULT '',
        price        INTEGER NOT NULL DEFAULT 0,
        old_price    INTEGER NOT NULL DEFAULT 0,
        rating       REAL NOT NULL DEFAULT 0,
        rating_count INTEGER NOT NULL DEFAULT 0,
        stock        INTEGER NOT NULL DEFAULT 0,
        description  TEXT NOT NULL DEFAULT '',
        specs        TEXT NOT NULL DEFAULT '{}',
        image        TEXT NOT NULL DEFAULT '',
        popularity   INTEGER NOT NULL DEFAULT 0,
        created_at   INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute(
        'CREATE INDEX idx_products_category ON products(category_id)');
    batch.execute('CREATE INDEX idx_products_brand ON products(brand)');

    batch.execute('''
      CREATE TABLE cart_items (
        product_id TEXT PRIMARY KEY,
        quantity   INTEGER NOT NULL DEFAULT 1,
        added_at   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE favorites (
        product_id TEXT PRIMARY KEY,
        added_at   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE orders (
        id             TEXT PRIMARY KEY,
        created_at     INTEGER NOT NULL DEFAULT 0,
        status         TEXT NOT NULL DEFAULT 'pending',
        subtotal       INTEGER NOT NULL DEFAULT 0,
        delivery_fee   INTEGER NOT NULL DEFAULT 0,
        delivery_type  TEXT NOT NULL DEFAULT 'courier',
        payment_method TEXT NOT NULL DEFAULT 'cash',
        customer_name  TEXT NOT NULL DEFAULT '',
        phone          TEXT NOT NULL DEFAULT '',
        address        TEXT NOT NULL DEFAULT '',
        comment        TEXT NOT NULL DEFAULT ''
      )
    ''');

    batch.execute('''
      CREATE TABLE order_items (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id   TEXT NOT NULL,
        product_id TEXT NOT NULL,
        name       TEXT NOT NULL,
        price      INTEGER NOT NULL DEFAULT 0,
        quantity   INTEGER NOT NULL DEFAULT 1,
        image      TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_order_items ON order_items(order_id)');

    batch.execute('''
      CREATE TABLE users (
        id      TEXT PRIMARY KEY,
        name    TEXT NOT NULL DEFAULT '',
        phone   TEXT NOT NULL DEFAULT '',
        email   TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        city    TEXT NOT NULL DEFAULT 'Toshkent'
      )
    ''');

    batch.execute('''
      CREATE TABLE reviews (
        id         TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        author     TEXT NOT NULL DEFAULT '',
        rating     INTEGER NOT NULL DEFAULT 5,
        text       TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('CREATE INDEX idx_reviews_product ON reviews(product_id)');

    batch.execute('''
      CREATE TABLE search_history (
        query      TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE viewed_products (
        product_id TEXT PRIMARY KEY,
        viewed_at  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE pc_builds (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL DEFAULT 0,
        items      TEXT NOT NULL DEFAULT '{}'
      )
    ''');

    batch.execute('''
      CREATE TABLE chat_messages (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        role        TEXT NOT NULL,
        text        TEXT NOT NULL,
        created_at  INTEGER NOT NULL DEFAULT 0,
        product_ids TEXT NOT NULL DEFAULT ''
      )
    ''');

    batch.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL DEFAULT ''
      )
    ''');

    await batch.commit(noResult: true);

    // Katalogni birinchi ochilishda to'ldiramiz.
    await SeedData.populate(db);
  }
}
