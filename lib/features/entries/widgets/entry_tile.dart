import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/common/helpers/date_helper.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/common/types/controller_type.dart';
import 'package:bandha/features/vaults/widgets/vault_text.dart';
import 'package:bandha/common/widgets/date_time_text.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EntryTile extends StatelessWidget {
  final Entry entry;
  final bool readOnly;

  final dateFormatter = DateFormat("yyyy/MM/dd");

  EntryTile(this.entry, {super.key, this.readOnly = false});

  String getDate() {
    return DateHelper.formatSimpleDate(entry.issuedAt);
  }

  String getTime() {
    return DateHelper.formatTime(
      TimeOfDay.fromDateTime(entry.issuedAt),
    );
  }

  handleLongPress(BuildContext context, Entry entry) {
    Navigator.pushNamed(context, "/entries/${entry.id}/detail");
    return;
  }

  handleTap(BuildContext context, Entry entry) {
    if (readOnly) {
      Navigator.pushNamed(context, "/entries/${entry.id}/detail");
      return;
    }

    switch (entry.controller?.type) {
      case ControllerType.pool:
        Navigator.pushNamed(
          context,
          "/pools/${entry.controller!.id}/entries",
        );
        break;
      case ControllerType.transfer:
        Navigator.pushNamed(
          context,
          "/transfers/${entry.controller!.id}/entries",
        );
        break;
      case ControllerType.schedule:
        Navigator.pushNamed(
          context,
          "/schedules/${entry.controller!.id}/history",
        );
        break;
      case ControllerType.settlement:
        Navigator.pushNamed(
          context,
          "/settlements/${entry.controller!.id}/payments",
        );
        break;
      default:
        Navigator.pushNamed(context, "/entries/${entry.id}/detail");
    }
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
        DateTimeText(entry.issuedAt),
        VaultText(entry.vault),
        if (!isNull(entry.controller?.id))
          Text(
            entry.controller!.id.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        if (entry.hasWritableLabels)
          labelsBuilder(
            context,
            entry.labels.where((label) => !label.readOnly).toList(),
          ),
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
        if (entry.hasReadOnlyLabels)
          labelsBuilder(
            context,
            entry.labels.where((label) => label.readOnly).toList(),
          ),
        if (entry.readonly)
          Icon(Icons.lock, size: 8, color: theme.colorScheme.primary),
        statusBuilder(context),
      ],
    );
  }

  entryBuilder(BuildContext context, Entry entry) {
    return tileBuilder(
      context,
      onLongPress: () {
        handleLongPress(context, entry);
      },
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
      dismissable: !entry.readonly && !readOnly,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
      child: entryBuilder(context, entry),
    );
  }
}
