import 'package:bandha/features/tags/entities/party.dart';
import "package:bandha/common/repositories/repository.dart";
import 'package:sqlite3/sqlite3.dart';

class PartyRepository extends Repository {
  PartyRepository(super.db);

  Future<Party> create({required String name}) async {
    try {
      final id = Repository.getId();
      final now = DateTime.now();
      final client = await getClient();

      client.execute(
        "INSERT INTO parties (id, name, created_at, updated_at) VALUES (?, ?, ?, ?)",
        [id, name, now.toIso8601String(), now.toIso8601String()],
      );

      return Party(id: id, name: name, createdAt: now, updatedAt: now);
    } catch (error) {
      rethrow;
    }
  }

  Future<Party?> update({
    required String id,
    required String name,
  }) async {
    final now = DateTime.now();
    final client = await getClient();

    client.execute(
      "UPDATE parties SET name = ?, updated_at = ? WHERE id = ?",
      [name, now.toIso8601String(), id],
    );

    return get(id);
  }

  Future<Party> get(String id) async {
    final client = await getClient();
    final List<Map> rows = client.select(
      "SELECT * FROM parties WHERE id = ?",
      [id],
    );

    return Party.row(rows.first);
  }

  Future<List<Party>> search() async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM parties ORDER BY name ASC",
    );
    return rows.map((row) => Party.row(row)).toList();
  }

  Future<void> delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM parties WHERE id = ?", [id]);
  }
}
