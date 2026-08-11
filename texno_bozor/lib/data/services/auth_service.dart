import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../repositories/user_repository.dart';

/// Autentifikatsiya abstraksiyasi.
///
/// Hozircha LOCAL implementatsiya: foydalanuvchi ism + telefon raqamini
/// kiritadi va profil shu qurilmada yaratiladi. Keyinchalik server
/// ulanganda bu interfeysning OTP/SMS implementatsiyasi yoziladi —
/// qolgan kod o'zgarmaydi.
abstract class AuthService {
  Future<User?> currentUser();
  Future<User> login({required String name, required String phone});
  Future<void> logout();
}

class LocalAuthService implements AuthService {
  LocalAuthService(this.users);

  final UserRepository users;

  @override
  Future<User?> currentUser() => users.getFirst();

  @override
  Future<User> login({required String name, required String phone}) async {
    // Bir xil telefon raqami bo'lsa, o'sha profil yangilanadi.
    final existing = await users.getFirst();
    if (existing != null) {
      final updated = existing.copyWith(name: name, phone: phone);
      await users.update(updated);
      return updated;
    }
    return users.create(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
    );
  }

  @override
  Future<void> logout() => users.deleteAll();
}

/// Ilova holati: ishga tushishda foydalanuvchini yuklaydi, login/logout
/// oqimlarini boshqaradi. Router shu notifier'ni tinglaydi.
class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier(this._auth, this._users);

  final AuthService _auth;
  final UserRepository _users;

  bool initialized = false;
  User? currentUser;

  Future<void> init() async {
    currentUser = await _auth.currentUser();
    initialized = true;
    notifyListeners();
  }

  /// null qaytsa — muvaffaqiyatli; aks holda xato xabari.
  Future<String?> login({required String name, required String phone}) async {
    try {
      currentUser = await _auth.login(name: name, phone: phone);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Profil yaratishda xatolik yuz berdi';
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? avatarEmoji,
  }) async {
    final user = currentUser;
    if (user == null) return;
    final updated = user.copyWith(
      name: name ?? user.name,
      phone: phone ?? user.phone,
      address: address ?? user.address,
      avatarEmoji: avatarEmoji ?? user.avatarEmoji,
    );
    await _users.update(updated);
    currentUser = updated;
    notifyListeners();
  }
}
