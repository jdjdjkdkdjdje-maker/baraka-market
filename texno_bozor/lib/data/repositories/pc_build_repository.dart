import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Saqlangan PC yig'ilishlar ombori.
abstract class PcBuildRepository {
  Stream<List<PcBuild>> watchAll();
  Future<void> save({
    required String id,
    required String name,
    required String componentsJson,
    required int totalPrice,
  });
  Future<void> delete(String id);
}

class DriftPcBuildRepository implements PcBuildRepository {
  DriftPcBuildRepository(this.db);

  final AppDatabase db;

  @override
  Stream<List<PcBuild>> watchAll() {
    final query = db.select(db.pcBuilds)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  @override
  Future<void> save({
    required String id,
    required String name,
    required String componentsJson,
    required int totalPrice,
  }) async {
    await db.into(db.pcBuilds).insert(
          PcBuildsCompanion.insert(
            id: id,
            name: name,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            componentsJson: Value(componentsJson),
            totalPrice: Value(totalPrice),
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await (db.delete(db.pcBuilds)..where((t) => t.id.equals(id))).go();
  }
}
