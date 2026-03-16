import 'package:bandha/common/widgets/date_time_text.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/common/types/transaction_type.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EntryTile extends StatelessWidget {
  final Fund fund;
  final Entry entry;
  final dateFormatter = DateFormat("yyyy/MM/dd");

  EntryTile(this.fund, this.entry, {super.key});

  typeBuilder(BuildContext context, Entry entry) {
    final theme = Theme.of(context);
    return Text(
      (entry.amount >= 0 ? TransactionType.withdrawal : TransactionType.deposit)
          .label,
      style: theme.textTheme.titleSmall,
    );
  }

  headerBuilder(BuildContext context, Entry entry) {
    final theme = Theme.of(context);

    return Row(
      spacing: 8,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        typeBuilder(context, entry),
        if (fund.status.isReleased)
          Icon(Icons.lock, size: 8, color: theme.colorScheme.primary),
      ],
    );
  }

  amountBuilder(BuildContext context, Entry entry) {
    return MoneyText(entry.amount * -1);
  }

  infoBuilder(BuildContext context, Entry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        headerBuilder(context, entry),
        DateTimeText(entry.issuedAt),
        labelsBuilder(context, entry.labels),
      ],
    );
  }

  entryBuilder(BuildContext context, Entry entry) {
    return tileBuilder(
      context,
      onTap: () {
        handleTap(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [infoBuilder(context, entry), amountBuilder(context, entry)],
      ),
    );
  }

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmFundTransactionDeletion(context, fund, entry);
    }

    Navigator.pushNamed(
      context,
      "/funds/${fund.id}/transactions/${entry.id}/edit",
    );

    return false;
  }

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      "/funds/${fund.id}/transactions/${entry.id}/detail",
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: entry.id,
      child: entryBuilder(context, entry),
      dismissable: !fund.status.isReleased,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
