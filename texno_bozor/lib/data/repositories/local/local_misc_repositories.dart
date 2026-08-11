import 'package:sqflite/sqflite.dart';

import '../../local/app_database.dart';
import '../../models/models.dart';
import '../repositories.dart';

/// Foydalanuvchi ombori — lokal SQLite implementatsiyasi.
///
/// Ilova bitta qurilma egasiga mo'ljallangan, shuning uchun profil
/// `me` identifikatori bilan saqlanadi (ro'yxatdan o'tish shart emas).
class LocalUserRepository implements UserRepository {
  LocalUserRepository(this.appDb);

  final AppDatabase appDb;

  Database get _db => appDb.db;

  @override
  Future<AppUser> getCurrent() async {
    final rows = await _db.query('users',
        where: 'id = ?', whereArgs: [AppUser.localId], limit: 1);
    if (rows.isEmpty) return const AppUser(id: AppUser.localId);
    return AppUser.fromMap(rows.first);
  }

  @override
  Future<void> save(AppUser user) async {
    await _db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> getSetting(String key) async {
    final rows = await _db
        .query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return '${rows.first['value']}';
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await _db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// Sevimlilar ombori — lokal SQLite implementatsiyasi.
class LocalFavoritesRepository implements FavoritesRepository {
  LocalFavoritesRepository(this.appDb);

  final AppDatabase appDb;

  Database get _db => appDb.db;

  @override
  Future<List<String>> ids() async {
    final rows = await _db.query('favorites', orderBy: 'added_at DESC');
    return rows.map((r) => '${r['product_id']}').toList();
  }

  @override
  Future<bool> contains(String productId) async {
    final rows = await _db.query('favorites',
        where: 'product_id = ?', whereArgs: [productId], limit: 1);
    return rows.isNotEmpty;
  }

  @override
  Future<bool> toggle(String productId) async {
    if (await contains(productId)) {
      await _db.delete('favorites',
          where: 'product_id = ?', whereArgs: [productId]);
      return false;
    }
    await _db.insert('favorites', {
      'product_id': productId,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  @override
  Future<void> clear() async {
    await _db.delete('favorites');
  }
}

/// Sharhlar ombori — lokal SQLite implementatsiyasi.
class LocalReviewRepository implements ReviewRepository {
  LocalReviewRepository(this.appDb);

  final AppDatabase appDb;

  Database get _db => appDb.db;

  @override
  Future<List<Review>> forProduct(String productId) async {
    final rows = await _db.query('reviews',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'created_at DESC');
    return rows.map(Review.fromMap).toList();
  }

  @override
  Future<void> add(Review review) async {
    await _db.insert(
      'reviews',
      review.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// Qidiruv tarixi va ko'rilgan mahsulotlar — lokal implementatsiya.
class LocalHistoryRepository implements HistoryRepository {
  LocalHistoryRepository(this.appDb);

  final AppDatabase appDb;

  Database get _db => appDb.db;

  @override
  Future<List<String>> recentSearches({int limit = 10}) async {
    final rows = await _db.query('search_history',
        orderBy: 'created_at DESC', limit: limit);
    return rows.map((r) => '${r['query']}').toList();
  }

  @override
  Future<void> addSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await _db.insert(
      'search_history',
      {'query': q, 'created_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearSearches() async {
    await _db.delete('search_history');
  }

  @override
  Future<List<String>> recentlyViewed({int limit = 10}) async {
    final rows = await _db.query('viewed_products',
        orderBy: 'viewed_at DESC', limit: limit);
    return rows.map((r) => '${r['product_id']}').toList();
  }

  @override
  Future<void> addViewed(String productId) async {
    await _db.insert(
      'viewed_products',
      {
        'product_id': productId,
        'viewed_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// Kompyuter yig'ilmalari ombori — lokal implementatsiya.
class LocalPcBuildRepository implements PcBuildRepository {
  LocalPcBuildRepository(this.appDb);

  final AppDatabase appDb;

  Database get _db => appDb.db;

  @override
  Future<List<PcBuild>> getAll() async {
    final rows = await _db.query('pc_builds', orderBy: 'created_at DESC');
    return rows.map(PcBuild.fromMap).toList();
  }

  @override
  Future<void> save(PcBuild build) async {
    await _db.insert(
      'pc_builds',
      build.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete('pc_builds', where: 'id = ?', whereArgs: [id]);
  }
}

/// TEXNO AI suhbat tarixi — lokal implementatsiya.
class LocalChatRepository implements ChatRepository {
  LocalChatRepository(this.appDb);

  final AppDatabase appDb;

  Database get _db => appDb.db;

  @override
  Future<List<ChatMessage>> history({int limit = 100}) async {
    final rows = await _db.query('chat_messages',
        orderBy: 'id DESC', limit: limit);
    return rows.reversed.map(ChatMessage.fromMap).toList();
  }

  @override
  Future<ChatMessage> add(ChatMessage message) async {
    final id = await _db.insert('chat_messages', message.toMap());
    return ChatMessage(
      id: id,
      role: message.role,
      text: message.text,
      createdAt: message.createdAt,
      productIds: message.productIds,
    );
  }

  @override
  Future<void> clear() async {
    await _db.delete('chat_messages');
  }
}
