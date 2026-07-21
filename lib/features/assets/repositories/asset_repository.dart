import 'package:bandha/features/assets/entities/asset.dart';
import "package:bandha/common/repositories/repository.dart";
import 'package:sqlite3/sqlite3.dart';

class AssetRepository extends Repository {
  AssetRepository(super.db);

  save(Asset asset) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO assets (id, name, code, total, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET name = excluded.name, code = excluded.code, total = excluded.total, updated_at = excluded.updated_at",
      [
        asset.id,
        asset.name,
        asset.code,
        asset.total,
        asset.createdAt.toIso8601String(),
        asset.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<List<Asset>> search() async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM assets ORDER BY assets.name ASC",
    );
    return rows.map((row) => Asset.row(row)).toList();
  }

  Future<Asset> get(String id) async {
    final client = await getClient();
    final rows = client.select("SELECT * FROM assets WHERE id = ?", [
      id,
    ]);
    return Asset.row(rows.first);
  }

  delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM assets WHERE id = ?", [id]);
  }
}
