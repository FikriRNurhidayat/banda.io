import 'package:bandha/features/accounts/entities/account.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/money_helper.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransferTile extends StatelessWidget {
  final bool readOnly;
  final Transfer transfer;
  final DateFormat dateFormat = DateFormat("yyyy/MM/dd");

  TransferTile(this.transfer, {super.key, this.readOnly = false});

  handleDismiss(BuildContext context, DismissDirection direction) {
    if (direction == DismissDirection.startToEnd) {
      return confirmTransferDeletion(context, transfer);
    }

    Navigator.pushNamed(context, "/transfers/${transfer.id}/edit");
    return Future.value(false);
  }

  handleTap(BuildContext context) {
    Navigator.of(context).pushNamed(
      readOnly
          ? "/transfers/${transfer.id}/detail"
          : "/transfers/${transfer.id}/entries",
    );
  }

  accountBuilder(BuildContext context, String labelText, Account account) {
    final theme = Theme.of(context);
    return <Widget>[
      Text(
        labelText,
        style: theme.textTheme.titleSmall,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        account.name,
        style: theme.textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        account.holderName,
        style: theme.textTheme.labelSmall,
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }

  amountBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Text(
            MoneyHelper.normalize(transfer.amount),
            style: theme.textTheme.bodyMedium,
          ),
          if (!isZero(transfer.fee)) ...[
            Icon(
              Icons.sync_alt_outlined,
              size: theme.textTheme.bodySmall?.fontSize,
            ),
            Text(
              MoneyHelper.normalize(transfer.fee!),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  tileBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          handleTap(context);
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
                  children: accountBuilder(
                    context,
                    "Credit",
                    transfer.creditAccount,
                  ),
                ),
              ),

              amountBuilder(context),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: accountBuilder(
                    context,
                    "Debit",
                    transfer.debitAccount,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(transfer.id),
      direction: readOnly ? DismissDirection.none : DismissDirection.horizontal,
      background: Container(
        color: theme.colorScheme.surfaceContainer,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
      secondaryBackground: Container(
        color: theme.colorScheme.surfaceContainer,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
      child: tileBuilder(context),
    );
  }
}
