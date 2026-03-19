import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/tags/entities/tagable.dart';

class Category extends Tagable {
  @override
  final String id;
  @override
  final String name;
  @override
  final bool readOnly;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Category({
    required this.id,
    required this.name,
    required this.readOnly,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  copyWith({String? name}) {
    return Category(
      id: id,
      name: name ?? this.name,
      readOnly: readOnly,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static tryRow(Map? row) {
    if (row == null) return null;
    return Category.row(row);
  }

  factory Category.create({required String name}) {
    final now = DateTime.now();

    return Category(
      id: Entity.getId(),
      name: name,
      readOnly: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Category.row(Map<dynamic, dynamic> row) {
    return Category(
      id: row["id"],
      name: row["name"],
      readOnly: row["readonly"] == 1,
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
      deletedAt: row["deleted_at"],
    );
  }
}
