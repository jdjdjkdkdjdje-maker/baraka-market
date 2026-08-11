import 'package:drift/native.dart';
import 'package:texno_bozor/data/database/app_database.dart';

/// Testlar uchun xotiradagi (in-memory) baza.
/// `onCreate` ichida seed ishlaydi, ya'ni demo katalog ham yuklanadi.
AppDatabase createTestDatabase() =>
    AppDatabase.withExecutor(NativeDatabase.memory());
