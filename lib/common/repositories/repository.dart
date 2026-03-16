import 'package:bandha/infra/db.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

typedef WithArgs = Set<String>;

class Repository {
  final DatabaseManager db;

  Repository(this.db);

  static String getId() {
    return Uuid().v4();
  }

  getClient() async {
    return db.current;
  }

  populateCategory(List<Map> mainRows) async {
    final List<String> categoryIds = mainRows
        .map((row) => row["category_id"] as String)
        .toList();
    final categoryRows = await getCategoryByIds(categoryIds);

    return mainRows.map((mainRow) {
      return {
        ...mainRow,
        "category": categoryRows.firstWhere(
          (categoryRow) => mainRow["category_id"] == categoryRow["id"],
        ),
      };
    }).toList();
  }

  populateVault(List<Map> rows) async {
    final List<String> vaultIds = rows
        .map((row) => row["vault_id"] as String)
        .toList();
    final vaultRows = await getVaultByIds(vaultIds);

    return rows.map((mainRow) {
      return {
        ...mainRow,
        "vault": vaultRows.firstWhere(
          (vaultRow) => mainRow["vault_id"] == vaultRow["id"],
        ),
      };
    }).toList();
  }

  populateEntityLabels(
    List<Map> rows,
    String junctionTable,
    String junctionKey,
  ) async {
    final List<String> ids = rows
        .map((row) => row["id"] as String)
        .toList();

    final labelRows = await getEntityLabels(
      entityIds: ids,
      junctionTable: junctionTable,
      junctionKey: junctionKey,
    );

    return rows.map((row) {
      return {
        ...row,
        "labels": labelRows
            .where((labelRow) => labelRow[junctionKey] == row["id"])
            .toList(),
      };
    }).toList();
  }

  getLoanByIds(List<String> ids) async {
    final client = await getClient();
    return client.select(
      "SELECT * FROM loans WHERE id IN (${ids.map((_) => "?").join(", ")})",
      ids,
    );
  }

  getVaultByIds(List<String> ids) async {
    final client = await getClient();
    return client.select(
      "SELECT * FROM vaults WHERE id IN (${ids.map((_) => "?").join(", ")})",
      ids,
    );
  }

  Future<ResultSet> getEntryByIds(List<String> ids) async {
    final client = await getClient();
    return client.select(
      "SELECT * FROM entries WHERE id IN (${ids.map((_) => "?").join(", ")})",
      ids,
    );
  }

  Future<ResultSet> getAnnotations(List<String> ids) async {
    final client = await getClient();
    return client.select(
      "SELECT * FROM entry_annotations WHERE entry_id IN (${ids.map((_) => "?").join(", ")})",
      ids,
    );
  }

  Future<Iterable<Map>> getAnnotatedEntriesByIds(
    List<String> ids,
  ) async {
    final entryRows = await getEntryByIds(ids);
    final annotationRows = await getAnnotations(ids);

    return entryRows.map((entry) {
      final annotations = <String, dynamic>{};
      for (var annotation in annotationRows.where(
        (annotation) => annotation["entry_id"] == entry["id"],
      )) {
        final key = annotation["name"] as String;
        final value = annotation["value"];
        annotations[key] = value;
      }

      return {...entry, "annotations": annotations};
    });
  }

  getPartyByIds(List<String> ids) async {
    final client = await getClient();
    return client.select(
      "SELECT * FROM parties WHERE id IN (${ids.map((_) => "?").join(", ")})",
      ids,
    );
  }

  getCategoryByIds(List<String> ids) async {
    final client = await getClient();
    return client.select(
      "SELECT * FROM categories WHERE id IN (${ids.map((_) => "?").join(", ")})",
      ids,
    );
  }

  resetEntityLabels({
    required String entityId,
    required String junctionTable,
    required String junctionKey,
  }) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM $junctionTable WHERE $junctionTable.$junctionKey = ?",
      [entityId],
    );
  }

  getEntityLabels({
    required List<String>? entityIds,
    required String junctionTable,
    required String junctionKey,
  }) async {
    if (entityIds == null || entityIds.isEmpty) {
      return ResultSet([], [], []);
    }

    final idsPlaceholder = entityIds.map((_) => "?").join(", ");
    final labelsQuery =
        """
      SELECT labels.*, $junctionTable.$junctionKey FROM labels
      INNER JOIN $junctionTable ON $junctionTable.label_id = labels.id
      WHERE $junctionTable.$junctionKey IN ($idsPlaceholder)
      ORDER BY labels.name ASC;
    """;

    final client = await getClient();
    final ResultSet rows = client.select(labelsQuery, entityIds);
    return rows;
  }

  Future<void> setEntityLabels({
    required String entityId,
    required List<String>? labelIds,
    required String junctionTable,
    required String junctionKey,
  }) async {
    await resetEntityLabels(
      entityId: entityId,
      junctionTable: junctionTable,
      junctionKey: junctionKey,
    );

    if (labelIds == null || labelIds.isEmpty) {
      return;
    }

    final client = await getClient();

    client.execute(
      "INSERT INTO $junctionTable ($junctionKey, label_id) VALUES ${labelIds.map((_) => '(?, ?)').join(",")}",
      labelIds
          .map((labelId) => [entityId, labelId])
          .expand((args) => args)
          .toList(),
    );
  }

  inExpr(List<String> value) {
    return value.map((_) => "?").join(",");
  }

  static begin() async {
    final connection = DatabaseManager();
    final client = await connection.current;
    client.execute("BEGIN TRANSACTION");
  }

  static commit() async {
    final connection = DatabaseManager.getSingleton();
    final client = await connection.current;
    client.execute("COMMIT");
  }

  static rollback() async {
    final connection = DatabaseManager.getSingleton();
    final client = await connection.current;
    client.execute("ROLLBACK");
  }

  static Future<T> work<T>(Future<T> Function() callback) async {
    try {
      begin();
      final result = await callback();
      commit();
      return result;
    } catch (error) {
      rollback();
      rethrow;
    }
  }
}
