import 'package:bandha/features/assets/entities/asset.dart';
import 'package:bandha/features/assets/providers/asset_provider.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetMenu extends StatelessWidget {
  final String id;

  const AssetMenu({super.key, required this.id});

  Map<String, GestureTapCallback> menuBuilder(
    BuildContext context,
    Asset asset,
  ) {
    final navigator = Navigator.of(context);

    final menu = {
      "Edit": () async {
        navigator.pushReplacementNamed("/assets/${asset.id}/edit");
      },
      "Delete": () async {
        final confirmed = await confirmAssetDeletion(context, asset);
        if (confirmed == true) {
          navigator.pop();
        }
      },
      "Back": () {
        navigator.pop();
      },
    };

    return menu;
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.read<AssetProvider>();

    return Scaffold(
      body: FutureBuilder(
        future: assetProvider.get(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("..."));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final asset = snapshot.data!;
          final menu = menuBuilder(context, asset);

          return Center(
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final callback = menu.entries.elementAt(index);
                return ListTile(
                  title: Text(
                    callback.key,
                    textAlign: TextAlign.center,
                  ),
                  onTap: callback.value,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
