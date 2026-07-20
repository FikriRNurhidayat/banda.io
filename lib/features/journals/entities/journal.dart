import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/entries/entities/entry.dart';

class Journal {
  final String id;
  final String name;
  final String holderName;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Journal({
    required this.id,
    required this.name,
    required this.holderName,
    required this.createdAt,
    required this.updatedAt,
    required this.balance,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Journal && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Journal copyWith({
    String? id,
    String? name,
    String? holderName,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Journal(
      id: id ?? this.id,
      name: name ?? this.name,
      holderName: holderName ?? this.holderName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balance: balance ?? this.balance,
    );
  }

  Journal applyAmount(double amount) {
    return copyWith(balance: balance + amount);
  }

  Journal applyDelta(EntryType type, double delta) {
    return copyWith(
      balance: type == EntryType.income
          ? balance + delta
          : balance - delta,
    );
  }

  Journal applyEntry(Entry entry) {
    return copyWith(balance: balance + entry.amount);
  }

  Journal applyEntries(Iterable<Entry?> entries) {
    double newBalance = balance;

    for (var entry in entries) {
      if (entry == null) continue;

      newBalance += entry.amount;
    }

    return copyWith(balance: newBalance);
  }

  Journal revokeEntries(Iterable<Entry?> entries) {
    double newBalance = balance;

    for (var entry in entries) {
      if (entry == null) continue;

      newBalance -= entry.amount;
    }

    return copyWith(balance: newBalance);
  }

  Journal revokeEntry(Entry entry) {
    return copyWith(balance: balance - entry.amount);
  }

  displayName() {
    return "$name — $holderName";
  }

  toMap() {
    return {
      "id": id,
      "name": name,
      "holderName": holderName,
      "balance": balance,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  static Journal? tryRow(Map<dynamic, dynamic>? row) {
    if (row == null) return null;
    return Journal.row(row);
  }

  factory Journal.row(Map<dynamic, dynamic> row) {
    return Journal(
      id: row["id"],
      name: row["name"],
      holderName: row["holder_name"],
      balance: row["balance"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }

  factory Journal.create({
    required String name,
    required String holderName,
    required double balance,
  }) {
    return Journal(
      id: Entity.getId(),
      name: name,
      holderName: holderName,
      balance: balance,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
