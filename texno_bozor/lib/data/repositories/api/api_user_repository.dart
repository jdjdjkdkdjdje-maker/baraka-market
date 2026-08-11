import 'package:drift/drift.dart';

import '../../../core/utils/async_utils.dart';
import '../../database/app_database.dart';
import '../../remote/api_client.dart';
import '../../remote/api_mappers.dart';
import '../user_repository.dart';

/// Foydalanuvchi ombori — REST API implementatsiyasi.
///
/// Profil har doim lokal saqlanadi (ilova internetsiz ochilishi kerak),
/// server esa fon rejimida yangilanadi.
///
/// Kutilayotgan endpointlar:
///   GET   /users/me      -> {id, name, phone, address, avatarEmoji}
///   POST  /users         {id, name, phone}
///   PATCH /users/me      {name, phone, address, avatarEmoji}
///   DELETE /users/me
class ApiUserRepository implements UserRepository {
  ApiUserRepository(this.api, this.db, {UserRepository? local})
      : local = local ?? DriftUserRepository(db);

  final ApiClient api;
  final AppDatabase db;
  final UserRepository local;

  @override
  Future<User?> getFirst() async {
    final cached = await local.getFirst();
    if (cached != null) {
      // Fon rejimida serverdagi profilni yangilash.
      fireAndForget(() async {
        final data = await api.get('/users/me');
        final json = ApiMappers.objectOf(data);
        if (json == null || json['id'] == null) return;
        await db.into(db.users).insertOnConflictUpdate(ApiMappers.user(json));
      });
      return cached;
    }

    try {
      final data = await api.get('/users/me');
      final json = ApiMappers.objectOf(data);
      if (json == null || json['id'] == null) return null;
      final user = ApiMappers.user(json);
      await db.into(db.users).insert(user, mode: InsertMode.replace);
      return user;
    } on ApiException {
      return null;
    }
  }

  @override
  Future<User> create({
    required String id,
    required String name,
    required String phone,
  }) async {
    final user = await local.create(id: id, name: name, phone: phone);
    fireAndForget(() => api.post('/users', body: ApiMappers.userToJson(user)));
    return user;
  }

  @override
  Future<void> update(User user) async {
    await local.update(user);
    fireAndForget(() => api.patch('/users/me', body: ApiMappers.userToJson(user)));
  }

  @override
  Future<void> deleteAll() async {
    await local.deleteAll();
    fireAndForget(() => api.delete('/users/me'));
  }
}
