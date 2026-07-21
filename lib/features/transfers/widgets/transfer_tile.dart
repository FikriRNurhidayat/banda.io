import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/money_helper.dart';
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

  journalBuilder(
    BuildContext context,
    String labelText,
    Journal journal,
  ) {
    final theme = Theme.of(context);
    return <Widget>[
      Text(
        labelText,
        style: theme.textTheme.titleSmall,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        journal.name,
        style: theme.textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        journal.holderName,
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
            MoneyHelper.normalize(transfer.creditAmount),
            style: theme.textTheme.bodySmall,
          ),
          Icon(
            Icons.arrow_drop_down,
            size: theme.textTheme.bodySmall?.fontSize,
          ),
          Text(
            MoneyHelper.normalize(transfer.debitAmount),
            style: theme.textTheme.bodySmall,
          ),
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
                  children: journalBuilder(
                    context,
                    "Credit",
                    transfer.creditJournal,
                  ),
                ),
              ),

              amountBuilder(context),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: journalBuilder(
                    context,
                    "Debit",
                    transfer.debitJournal,
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
      direction: readOnly
          ? DismissDirection.none
          : DismissDirection.horizontal,
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
