import 'package:bandha/features/assets/entities/asset.dart';
import 'package:bandha/features/assets/services/asset_service.dart';
import 'package:flutter/material.dart';

class AssetProvider extends ChangeNotifier {
  final AssetService assetService;

  AssetProvider(this.assetService);

  Future<List<Asset>> search() async {
    return assetService.search();
  }

  Future<Asset?> get(String id) async {
    return assetService.get(id);
  }

  Future<void> create({
    required String name,
    required String code,
  }) async {
    await assetService.create(name: name, code: code);
    notifyListeners();
  }

  Future<void> update(
    String id, {
    required String name,
    required String code,
  }) async {
    await assetService.update(id, name: name, code: code);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await assetService.delete(id);
    notifyListeners();
  }
}
