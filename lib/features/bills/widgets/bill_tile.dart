import 'package:banda/common/helpers/dialog_helper.dart';
import 'package:banda/common/helpers/tile_helper.dart';
import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/common/widgets/date_time_text.dart';
import 'package:banda/common/widgets/money_text.dart';
import 'package:banda/features/accounts/widgets/account_text.dart';
import 'package:banda/features/bills/entities/bill.dart';
import 'package:flutter/material.dart';

class BillTile extends StatelessWidget {
  final Bill bill;
  final bool readOnly;

  const BillTile(this.bill, {super.key, this.readOnly = false});

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmBillDeletion(context, bill);
    }

    Navigator.pushNamed(context, "/bills/${bill.id}/edit");
    return false;
  }

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      readOnly ? "/bills/${bill.id}/detail" : "/bills/${bill.id}/history",
    );
  }

  Widget statusBuilder(BuildContext context) {
    final theme = Theme.of(context);
    switch (bill.status) {
      case BillStatus.pending:
        return Icon(
          Icons.hourglass_empty,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case BillStatus.overdue:
        return Icon(Icons.warning, color: theme.colorScheme.primary, size: 8);
      default:
        return SizedBox(width: 8);
    }
  }

  infoBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AccountText(bill.account),
        DateTimeText(bill.dueAt),
        if (!isNull(bill.note) && bill.note!.isNotEmpty)
          Text(
            bill.note!,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        labelsBuilder(context, bill.labels),
      ],
    );
  }

  headerBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        Text(bill.category.name, style: theme.textTheme.titleSmall),
        Text(bill.cycle.label, style: theme.textTheme.labelSmall),
        Text("x${bill.iteration.toString()}", style: theme.textTheme.labelSmall),
        statusBuilder(context),
      ],
    );
  }

  billBuilder(BuildContext context) {
    return tileBuilder(
      context,
      onTap: () {
        handleTap(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [headerBuilder(context), infoBuilder(context)],
            ),
          ),
          MoneyText(bill.amount, useSymbol: false),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: bill.id,
      child: billBuilder(context),
      dismissable: !readOnly,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
