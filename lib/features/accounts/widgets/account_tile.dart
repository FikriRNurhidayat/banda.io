import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';

class AccountTile extends StatelessWidget {
  final Account account;
  final bool readOnly;

  const AccountTile(this.account, {super.key, this.readOnly = false});

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmAccountDeletion(context, account);
    }

    Navigator.pushNamed(context, "/accounts/${account.id}/edit");
    return false;
  }

  handleTap(BuildContext context, Account account) {
    Navigator.pushNamed(
      context,
      readOnly
          ? "/accounts/${account.id}/detail"
          : "/accounts/${account.id}/entries",
    );
  }

  tileBuilder(BuildContext context, Account account) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          handleTap(context, account);
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
                      account.name,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      account.holderName,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (account.kind?.label != null)
                      Text(
                        account.kind!.label,
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
              MoneyText(account.balance, useSymbol: false),
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
      key: account.id,
      child: tileBuilder(context, account),
      dismissable: true,
      confirmDismiss: (DismissDirection direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
