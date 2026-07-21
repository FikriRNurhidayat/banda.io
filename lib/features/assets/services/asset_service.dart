import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/assets/entities/asset.dart';
import 'package:bandha/features/assets/repositories/asset_repository.dart';

class AssetService extends Service {
  final AssetRepository assetRepository;

  AssetService({
    required this.assetRepository,
  });

  search() {
    return assetRepository.search();
  }

  get(String id) {
    return assetRepository.get(id);
  }

  Future<Asset> create({
    required String name,
    required String code,
  }) async {
    return work<Asset>(() async {
      final asset = Asset.create(name: name, code: code);
      await assetRepository.save(asset);
      return asset;
    });
  }

  update(
    String id, {
    required String name,
    required String code,
  }) {
    return work(() async {
      final asset = await assetRepository.get(id);
      await assetRepository.save(
        asset.copyWith(name: name, code: code),
      );
    });
  }

  delete(String id) {
    return work(() async {
      await assetRepository.delete(id);
    });
  }
}
