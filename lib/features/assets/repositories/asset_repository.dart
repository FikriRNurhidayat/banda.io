import 'package:bandha/features/assets/entities/asset.dart';
import "package:bandha/common/repositories/repository.dart";

class AssetRepository extends Repository {
  AssetRepository(super.db);
  save(Asset asset) async {
    final client = await getClient();
    client.execute(
      "INSERT INTO assets (id, name, code, decimals, liquidity, total, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO UPDATE SET name = excluded.name, code = excluded.code, decimals = excluded.decimals, liquidity = excluded.liquidity, total = excluded.total, updated_at = excluded.updated_at",
      [
        asset.id,
        asset.name,
        asset.code,
        asset.decimals,
        asset.liquidity.label,
        asset.total,
        asset.createdAt.toIso8601String(),
        asset.updatedAt.toIso8601String(),
      ],
    );
  }

  Future<List<Asset>> search() async {
    final client = await getClient();
    final rows = client.select(
      "SELECT * FROM assets ORDER BY assets.name ASC",
    );
    return rows.map((row) => Asset.row(row)).toList();
  }

  Future<Asset> get(String id) async {
    final client = await getClient();
    final rows = client.select(
      "SELECT * FROM assets WHERE id = ?",
      [id],
    );
    return Asset.row(rows.first);
  }
}
