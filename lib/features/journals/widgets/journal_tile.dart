import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';

class JournalTile extends StatelessWidget {
  final Journal journal;
  final bool readOnly;

  const JournalTile(this.journal, {super.key, this.readOnly = false});

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmJournalDeletion(context, journal);
    }

    Navigator.pushNamed(context, "/journals/${journal.id}/edit");
    return false;
  }

  handleTap(BuildContext context, Journal journal) {
    Navigator.pushNamed(
      context,
      readOnly
          ? "/journals/${journal.id}/detail"
          : "/journals/${journal.id}/entries",
    );
  }

  tileBuilder(BuildContext context, Journal journal) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          handleTap(context, journal);
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
                    Text(journal.name, style: theme.textTheme.titleSmall),
                    Text(
                      journal.holderName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              MoneyText(journal.balance, useSymbol: false),
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
      key: journal.id,
      child: tileBuilder(context, journal),
      dismissable: true,
      confirmDismiss: (DismissDirection direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
