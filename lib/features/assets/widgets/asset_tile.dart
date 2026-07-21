import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/features/assets/entities/asset.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';

class AssetTile extends StatelessWidget {
  final Asset asset;
  final bool readOnly;

  const AssetTile(this.asset, {super.key, this.readOnly = false});

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmAssetDeletion(context, asset);
    }

    Navigator.pushNamed(context, "/assets/${asset.id}/edit");
    return false;
  }

  handleTap(BuildContext context, Asset asset) {
    Navigator.pushNamed(context, "/assets/${asset.id}/detail");
  }

  tileBuilder(BuildContext context, Asset asset) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          handleTap(context, asset);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(asset.name, style: theme.textTheme.titleSmall),
                    Text(asset.code, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [MoneyText(asset.total, useSymbol: false)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: asset.id,
      child: tileBuilder(context, asset),
      dismissable: true,
      confirmDismiss: (DismissDirection direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
