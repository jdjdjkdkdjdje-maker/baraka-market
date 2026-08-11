import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:texno_bozor/data/local/app_database.dart';

/// Testlar uchun xotiradagi (in-memory) SQLite bazasi.
///
/// Har bir test toza baza oladi — seed katalog avtomatik yoziladi.
Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  return AppDatabase.openWith(databaseFactoryFfi);
}
