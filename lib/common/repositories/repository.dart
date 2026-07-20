import 'package:bandha/common/helpers/type_helper.dart';
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

  populateEntries(List<Map> rows) async {
    final entryIds = rows
        .map(
          (row) => [
            row["entry_id"] as String,
            row["addition_id"] as String?,
          ],
        )
        .expand((id) => id)
        .whereType<String>()
        .toList();
    final entryRows = await getAnnotatedEntriesByIds(entryIds);
    return rows.map((row) {
      return {
        ...row,
        "entry": entryRows.firstWhere(
          (entryRow) => entryRow["id"] == row["entry_id"],
        ),
        "addition": !isNull(row["addition_id"])
            ? entryRows.firstWhere(
                (entryRow) => entryRow["id"] == row["addition_id"],
              )
            : null,
      };
    }).toList();
  }

  populateParty(List<Map> mainRows) async {
    final List<String> partyIds = mainRows
        .map((row) => row["party_id"] as String)
        .toList();
    final partyRows = await getPartyByIds(partyIds);

    return mainRows.map((mainRow) {
      return {
        ...mainRow,
        "party": partyRows.firstWhere(
          (partyRow) => mainRow["party_id"] == partyRow["id"],
        ),
      };
    }).toList();
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

  populateJournal(List<Map> rows) async {
    final List<String> journalIds = rows
        .map((row) => row["journal_id"] as String)
        .toList();
    final journalRows = await getJournalByIds(journalIds);

    return rows.map((mainRow) {
      return {
        ...mainRow,
        "journal": journalRows.firstWhere(
          (journalRow) => mainRow["journal_id"] == journalRow["id"],
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

  getObligationByIds(List<String> ids) async {
    final client = await getClient();
    return client.select(
      "SELECT * FROM obligations WHERE id IN (${ids.map((_) => "?").join(", ")})",
      ids,
    );
  }

  getJournalByIds(List<String> ids) async {
    final client = await getClient();
    return client.select(
      "SELECT * FROM journals WHERE id IN (${ids.map((_) => "?").join(", ")})",
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

  resetExactEntityLabels({
    required String entityId,
    required Iterable<String> labelIds,
    required String junctionTable,
    required String junctionKey,
  }) async {
    final client = await getClient();
    client.execute(
      "DELETE FROM $junctionTable WHERE $junctionTable.$junctionKey = ? AND label_id IN (${labelIds.map((_) => "?").join(",")})",
      [entityId, ...labelIds],
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

  Future<void> applyEntityLabels({
    required String entityId,
    required Iterable<(bool, String)> diffIds,
    required String junctionTable,
    required String junctionKey,
  }) async {
    await resetExactEntityLabels(
      entityId: entityId,
      labelIds: diffIds.map((i) => i.$2),
      junctionTable: junctionTable,
      junctionKey: junctionKey,
    );

    if (diffIds.isEmpty) {
      return;
    }

    final client = await getClient();

    final labelIds = diffIds
        .where((d) => d.$1)
        .map((d) => d.$2)
        .toSet();

    client.execute(
      "INSERT INTO $junctionTable ($junctionKey, label_id) VALUES ${labelIds.map((_) => "(?, ?)").join(", ")}",
      labelIds
          .map((labelId) => [entityId, labelId])
          .expand((a) => a)
          .toList(),
    );
  }

  Future<void> setEntityLabels({
    required String entityId,
    required Iterable<String>? labelIds,
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

    final uniqueLabelIds = labelIds.toSet();

    client.execute(
      "INSERT INTO $junctionTable ($junctionKey, label_id) VALUES ${uniqueLabelIds.map((_) => '(?, ?)').join(",")}",
      uniqueLabelIds
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
