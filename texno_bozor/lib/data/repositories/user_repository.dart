import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Foydalanuvchi ombori (lokal). Server ulanganda OTP-auth implementatsiya
/// bilan almashtiriladi.
abstract class UserRepository {
  Future<User?> getFirst();
  Future<User> create({
    required String id,
    required String name,
    required String phone,
  });
  Future<void> update(User user);
  Future<void> deleteAll();
}

class DriftUserRepository implements UserRepository {
  DriftUserRepository(this.db);

  final AppDatabase db;

  @override
  Future<User?> getFirst() async {
    final users = await db.select(db.users).get();
    return users.isEmpty ? null : users.first;
  }

  @override
  Future<User> create({
    required String id,
    required String name,
    required String phone,
  }) async {
    final user = User(
      id: id,
      name: name,
      phone: phone,
      avatarEmoji: '\u{1F464}',
      address: '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await db.into(db.users).insert(user, mode: InsertMode.replace);
    return user;
  }

  @override
  Future<void> update(User user) async {
    await (db.update(db.users)..where((t) => t.id.equals(user.id)))
        .write(user);
  }

  @override
  Future<void> deleteAll() async {
    await db.delete(db.users).go();
  }
}
