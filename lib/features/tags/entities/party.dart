import 'package:bandha/features/tags/entities/tagable.dart';

class Party extends Tagable {
  @override
  final String id;
  @override
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  @override
  final readonly = false;

  Party({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  
  static Party? tryRow(Map<dynamic, dynamic>? row) {
    if (row == null) return null;
    return Party.row(row);
  }

  factory Party.row(Map<dynamic, dynamic> row) {
    return Party(
      id: row["id"],
      name: row["name"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }
}
