import 'package:banda/features/tags/entities/label.dart';
import "package:banda/common/repositories/repository.dart";
import 'package:sqlite3/sqlite3.dart';

class LabelRepository extends Repository {
  LabelRepository(super.db);

  Future<Label> create({required String name}) async {
    try {
      final id = Repository.getId();
      final now = DateTime.now();
      final client = await getClient();

      client.execute(
        "INSERT INTO labels (id, name, readonly, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
        [id, name, false, now.toIso8601String(), now.toIso8601String()],
      );

      return Label(id: id, name: name, createdAt: now, updatedAt: now);
    } catch (error) {
      rethrow;
    }
  }

  Future<Label?> update({
    required String id,
    required String name,
  }) async {
    final now = DateTime.now();
    final client = await getClient();

    client.execute(
      "UPDATE labels SET name = ?, updated_at = ? WHERE id = ?",
      [name, now.toIso8601String(), id],
    );

    return get(id);
  }

  Future<Label> getByName(String name) async {
    final client = await getClient();
    final List<Map> rows = client.select(
      "SELECT * FROM labels WHERE name = ?",
      [name],
    );
    return rows.map((row) => Label.row(row)).first;
  }

  Future<Label?> get(String id) async {
    final client = await getClient();
    final List<Map> rows = client.select(
      "SELECT * FROM labels WHERE id = ?",
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }

    return Label.row(rows.first);
  }

  getByIds(List<String> ids) async {
    final client = await getClient();
    final List<Map> rows = client.select(
      "SELECT * FROM labels WHERE id IN (${ids.map((_) => "?").join(", ")})",
      ids,
    );
    return Label.rows(rows);
  }

  Future<List<Label>> search() async {
    final client = await getClient();
    final ResultSet rows = client.select(
      "SELECT * FROM labels WHERE readonly = 0 ORDER BY name ASC",
    );
    return rows.map((row) => Label.row(row)).toList();
  }

  Future<void> delete(String id) async {
    final client = await getClient();
    client.execute("DELETE FROM labels WHERE id = ?", [id]);
  }
}
