import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/assets/entities/asset.dart';
import 'package:bandha/features/assets/providers/asset_provider.dart';
import 'package:bandha/features/assets/widgets/asset_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Assets extends StatelessWidget {
  const Assets({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetProvider = context.watch<AssetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Assets", style: theme.textTheme.titleMedium),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, "/assets/new");
        },
      ),
      body: FutureBuilder(
        future: assetProvider.search(),
        builder: futureBuilder((context, snapshot) {
          final assets = snapshot.data as List<Asset>;
          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (BuildContext context, int index) {
              final Asset asset = assets[index];
              return AssetTile(asset);
            },
          );
        }),
      ),
    );
  }
}
