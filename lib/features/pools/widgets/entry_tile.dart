import 'package:bandha/common/widgets/date_time_text.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EntryTile extends StatelessWidget {
  final Pool pool;
  final Entry entry;
  final dateFormatter = DateFormat("yyyy/MM/dd");

  EntryTile(this.pool, this.entry, {super.key});

  headerBuilder(BuildContext context, Entry entry) {
    final theme = Theme.of(context);

    return Row(
      spacing: 8,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        labelsBuilder(
          context,
          entry.labels.where((label) => label.readOnly).toList(),
          style: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        labelsBuilder(
          context,
          entry.labels
              .where(
                (label) =>
                    !label.readOnly &&
                    !pool.labelIds.contains(label.id),
              )
              .toList(),
        ),
        if (pool.status.isReleased)
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
        children: [
          infoBuilder(context, entry),
          amountBuilder(context, entry),
        ],
      ),
    );
  }

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmPoolTransactionDeletion(context, pool, entry);
    }

    Navigator.pushNamed(
      context,
      "/pools/${pool.id}/transactions/${entry.id}/edit",
    );

    return false;
  }

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      "/pools/${pool.id}/transactions/${entry.id}/detail",
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: entry.id,
      child: entryBuilder(context, entry),
      dismissable: !pool.status.isReleased,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
