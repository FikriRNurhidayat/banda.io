import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';

class VaultTile extends StatelessWidget {
  final Vault vault;
  final bool readOnly;

  const VaultTile(this.vault, {super.key, this.readOnly = false});

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmVaultDeletion(context, vault);
    }

    Navigator.pushNamed(context, "/vaults/${vault.id}/edit");
    return false;
  }

  handleTap(BuildContext context, Vault vault) {
    Navigator.pushNamed(
      context,
      readOnly
          ? "/vaults/${vault.id}/detail"
          : "/vaults/${vault.id}/entries",
    );
  }

  tileBuilder(BuildContext context, Vault vault) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          handleTap(context, vault);
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
                    Text(
                      vault.name,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      vault.holderName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              MoneyText(vault.balance, useSymbol: false),
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
      key: vault.id,
      child: tileBuilder(context, vault),
      dismissable: true,
      confirmDismiss: (DismissDirection direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
