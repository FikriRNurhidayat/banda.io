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
    int decimals = 2,
    Liquidity liquidity = Liquidity.liquid,
  }) async {
    return work<Asset>(() async {
      final asset = Asset.create(
        name: name,
        code: code,
        decimals: decimals,
        liquidity: liquidity,
      );
      await assetRepository.save(asset);
      return asset;
    });
  }
}
