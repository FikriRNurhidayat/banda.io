import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/common/helpers/dialog_helper.dart';
import 'package:banda/common/helpers/tile_helper.dart';
import 'package:banda/features/accounts/widgets/account_text.dart';
import 'package:banda/common/widgets/date_time_text.dart';
import 'package:banda/common/widgets/money_text.dart';
import 'package:flutter/material.dart';

class EntryTile extends StatelessWidget {
  final Entry entry;
  final bool readOnly;

  const EntryTile(this.entry, {super.key, this.readOnly = false});

  handleTap(BuildContext context, Entry entry) {
    Navigator.pushNamed(context, "/entries/${entry.id}/detail");
    return;
  }

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmEntryDeletion(context, entry);
    }

    Navigator.pushNamed(context, "/entries/${entry.id}/edit");
    return false;
  }

  Widget statusBuilder(BuildContext context) {
    final theme = Theme.of(context);
    switch (entry.status) {
      case EntryStatus.pending:
        return Icon(
          Icons.hourglass_empty,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case EntryStatus.done:
      default:
        return SizedBox(width: 8);
    }
  }

  infoBuilder(BuildContext context, Entry entry) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AccountText(entry.account),
        DateTimeText(entry.issuedAt),
        if (!isNull(entry.note) && entry.note!.isNotEmpty)
          Text(
            entry.note!,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        labelsBuilder(context, entry.labels),
      ],
    );
  }

  headerBuilder(BuildContext context, Entry entry) {
    final theme = Theme.of(context);

    return Row(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(entry.category.name, style: theme.textTheme.titleSmall),
        statusBuilder(context),
      ],
    );
  }

  entryBuilder(BuildContext context, Entry entry) {
    return tileBuilder(
      context,
      onTap: () {
        handleTap(context, entry);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerBuilder(context, entry),
                infoBuilder(context, entry),
              ],
            ),
          ),
          MoneyText(entry.amount),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: entry.id,
      dismissable: true,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
      child: entryBuilder(context, entry),
    );
  }
}
