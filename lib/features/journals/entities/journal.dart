import 'package:bandha/common/entities/entity.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/assets/entities/asset.dart';

class Journal {
  final String id;
  final String name;
  final String holderName;
  final double balance;
  final String assetId;
  final DateTime createdAt;
  final DateTime updatedAt;

  late Asset asset;

  Journal({
    required this.id,
    required this.name,
    required this.holderName,
    required this.createdAt,
    required this.updatedAt,
    required this.balance,
    required this.assetId,
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
    String? assetId,
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
      assetId: assetId ?? this.assetId,
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

  Journal withAsset(Asset? value) {
    if (value != null) asset = value;
    return this;
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
      "assetId": assetId,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  static Journal? tryRow(Map<dynamic, dynamic>? row) {
    if (row == null) return null;
    return Journal.row(row);
  }

  factory Journal.row(Map<dynamic, dynamic> row) {
    final journal = Journal(
      id: row["id"],
      name: row["name"],
      holderName: row["holder_name"],
      balance: row["balance"],
      assetId: row["asset_id"] ?? "",
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
    final asset = Asset.tryRow(row["asset"]);
    if (asset != null) journal.asset = asset;
    return journal;
  }

  factory Journal.create({
    required String name,
    required String holderName,
    required double balance,
    required String assetId,
  }) {
    return Journal(
      id: Entity.getId(),
      name: name,
      holderName: holderName,
      balance: balance,
      assetId: assetId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
