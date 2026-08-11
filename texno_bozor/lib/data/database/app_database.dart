import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed_data.dart';

part 'app_database.g.dart';

/// Kategoriyalar jadvali.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('device'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Mahsulotlar jadvali.
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text()();
  TextColumn get categoryId => text()();
  IntColumn get price => integer()();
  IntColumn get oldPrice => integer().nullable()();
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  IntColumn get reviewsCount => integer().withDefault(const Constant(0))();
  IntColumn get stock => integer().withDefault(const Constant(10))();
  TextColumn get warranty =>
      text().withDefault(const Constant('12 oy kafolat'))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get specsJson => text().withDefault(const Constant('{}'))();
  TextColumn get emoji => text().withDefault(const Constant('\u{1F4E6}'))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get popularity => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get isTop => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Foydalanuvchilar (lokal, bitta faol profil).
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get avatarEmoji =>
      text().withDefault(const Constant('\u{1F464}'))();
  TextColumn get address => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Savat.
class CartItems extends Table {
  TextColumn get productId => text()();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  IntColumn get addedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}

/// Buyurtmalar.
class Orders extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  TextColumn get status => text().withDefault(const Constant('fresh'))();
  IntColumn get subtotal => integer()();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get deliveryFee => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get deliveryMethod =>
      text().withDefault(const Constant('standard'))();
  TextColumn get customerName => text().withDefault(const Constant(''))();
  TextColumn get customerPhone => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Buyurtma tarkibidagi mahsulotlar (snapshot — katalog o'zgarsa ham saqlanadi).
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text().withDefault(const Constant('\u{1F4E6}'))();
  IntColumn get price => integer()();
  IntColumn get qty => integer()();
}

/// Sevimlilar.
class Favorites extends Table {
  TextColumn get productId => text()();
  IntColumn get addedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}

/// Sharhlar.
class Reviews extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get userName => text()();
  RealColumn get rating => real()();
  TextColumn get reviewText => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Qidiruv tarixi.
@DataClassName('SearchHistoryEntry')
class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()();
  IntColumn get createdAt => integer()();
}

/// Yaqinda ko'rilgan mahsulotlar.
@DataClassName('RecentlyViewedEntry')
class RecentlyViewed extends Table {
  TextColumn get productId => text()();
  IntColumn get viewedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}

/// Saqlangan PC yig'ilishlar.
class PcBuilds extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  TextColumn get componentsJson =>
      text().withDefault(const Constant('{}'))();
  IntColumn get totalPrice => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Categories,
  Products,
  Users,
  CartItems,
  Orders,
  OrderItems,
  Favorites,
  Reviews,
  SearchHistory,
  RecentlyViewed,
  PcBuilds,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'texno_bozor'));

  /// Testlar uchun: xotiradagi (in-memory) baza bilan ishga tushirish.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Birinchi ishga tushirishda demo katalog bazaga yoziladi.
          await seedDatabase(this);
        },
      );
}
