import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/entries/entities/entry.dart';

class Vault {
  final String id;
  final String name;
  final String holderName;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vault({
    required this.id,
    required this.name,
    required this.holderName,
    required this.createdAt,
    required this.updatedAt,
    required this.balance,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Vault && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Vault copyWith({
    String? id,
    String? name,
    String? holderName,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vault(
      id: id ?? this.id,
      name: name ?? this.name,
      holderName: holderName ?? this.holderName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balance: balance ?? this.balance,
    );
  }

  Vault applyAmount(double amount) {
    return copyWith(balance: balance + amount);
  }

  Vault applyDelta(EntryType type, double delta) {
    return copyWith(
      balance: type == EntryType.income
          ? balance + delta
          : balance - delta,
    );
  }

  Vault applyEntry(Entry entry) {
    return copyWith(balance: balance + entry.amount);
  }

  Vault applyEntries(Iterable<Entry?> entries) {
    double newBalance = balance;

    for (var entry in entries) {
      if (entry == null) continue;

      newBalance += entry.amount;
    }

    return copyWith(balance: newBalance);
  }

  Vault revokeEntries(Iterable<Entry?> entries) {
    double newBalance = balance;

    for (var entry in entries) {
      if (entry == null) continue;

      newBalance -= entry.amount;
    }

    return copyWith(balance: newBalance);
  }

  Vault revokeEntry(Entry entry) {
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

  static Vault? tryRow(Map<dynamic, dynamic>? row) {
    if (row == null) return null;
    return Vault.row(row);
  }

  factory Vault.row(Map<dynamic, dynamic> row) {
    return Vault(
      id: row["id"],
      name: row["name"],
      holderName: row["holder_name"],
      balance: row["balance"],
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }

  factory Vault.create({
    required String name,
    required String holderName,
    required double balance,
  }) {
    return Vault(
      id: Entity.getId(),
      name: name,
      holderName: holderName,
      balance: balance,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
