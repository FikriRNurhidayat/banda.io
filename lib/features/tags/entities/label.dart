import 'package:bandha/features/tags/entities/tagable.dart';

class Label extends Tagable {
  @override
  final String id;
  @override
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  @override
  bool readonly = false;

  Label({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  static tryRow(Map? row) {
    if (row == null) return null;
    return Label.row(row);
  }

  factory Label.row(Map row) {
    return Label(
      id: row["id"],
      name: row["name"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }

  static List<Label>? tryRows(List<Map<dynamic, dynamic>>? rows) {
    if (rows == null) return null;
    return Label.rows(rows);
  }

  static List<Label> rows(List<Map<dynamic, dynamic>> rows) {
    return rows.map((row) => Label.row(row)).toList();
  }
}
