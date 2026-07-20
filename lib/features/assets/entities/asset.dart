import 'package:bandha/common/entities/entity.dart';

class Asset {
  final String id;
  final String name;
  final String code;
  final int decimals;
  final Liquidity liquidity;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;

  Asset({
    required this.id,
    required this.name,
    required this.code,
    required this.decimals,
    required this.liquidity,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
  });

  displayName() {
    return "$name ($code)";
  }

  static Asset? tryRow(Map? row) {
    if (row == null) return null;
    return Asset.row(row);
  }

  factory Asset.row(Map row) {
    return Asset(
      id: row["id"],
      name: row["name"],
      code: row["code"],
      decimals: row["decimals"],
      liquidity: Liquidity.parse(row["liquidity"]),
      total: row["total"] ?? 0,
      createdAt: DateTime.parse(row["created_at"]),
      updatedAt: DateTime.parse(row["updated_at"]),
    );
  }

  factory Asset.create({
    required String name,
    required String code,
    int decimals = 2,
    Liquidity liquidity = Liquidity.liquid,
    double total = 0,
  }) {
    final now = DateTime.now();
    return Asset(
      id: Entity.getId(),
      name: name,
      code: code,
      decimals: decimals,
      liquidity: liquidity,
      total: total,
      createdAt: now,
      updatedAt: now,
    );
  }

  copyWith({
    String? name,
    String? code,
    int? decimals,
    Liquidity? liquidity,
    double? total,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      decimals: decimals ?? this.decimals,
      liquidity: liquidity ?? this.liquidity,
      total: total ?? this.total,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  toMap() {
    return {
      "id": id,
      "name": name,
      "code": code,
      "decimals": decimals,
      "liquidity": liquidity.label,
      "total": total,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}

enum Liquidity {
  liquid('liquid'),
  semiLiquid('semi_liquid'),
  illiquid('illiquid');

  final String label;
  const Liquidity(this.label);

  static Liquidity parse(String value) {
    return Liquidity.values.firstWhere(
      (l) => l.label == value,
      orElse: () => Liquidity.liquid,
    );
  }
}
