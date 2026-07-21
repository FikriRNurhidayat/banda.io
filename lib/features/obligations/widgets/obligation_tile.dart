import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/features/journals/widgets/journal_text.dart';
import 'package:bandha/common/widgets/date_time_text.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';

class ObligationTile extends StatelessWidget {
  final Obligation obligation;
  final bool readOnly;

  const ObligationTile(
    this.obligation, {
    super.key,
    this.readOnly = false,
  });

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      readOnly
          ? "/obligations/${obligation.id}/detail"
          : "/obligations/${obligation.id}/payments",
    );
  }

  handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmObligationDeletion(context, obligation);
    }

    Navigator.pushNamed(context, "/obligations/${obligation.id}/edit");
    return Future.value(false);
  }

  Widget statusBuilder(BuildContext context) {
    final theme = Theme.of(context);
    switch (obligation.status) {
      case ObligationStatus.active:
        return Icon(
          Icons.hourglass_empty,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case ObligationStatus.overdue:
        return Icon(
          Icons.hourglass_full,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case ObligationStatus.settled:
        return Icon(
          Icons.done_all,
          color: theme.colorScheme.primary,
          size: 8,
        );
    }
  }

  infoBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                obligation.category.name,
                style: theme.textTheme.titleSmall,
              ),
              if (obligation.hasLabels)
                labelsBuilder(
                  context,
                  obligation.labels,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              statusBuilder(context),
            ],
          ),
          DateTimeText(obligation.issuedAt),
          JournalText(obligation.journal),
          Text(obligation.party.name, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  progressBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyText(
              obligation.paid,
              useSymbol: false,
              style: theme.textTheme.bodySmall,
            ),
            Text("/"),
            MoneyText(
              obligation.amount,
              useSymbol: false,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        Badge(
          padding: EdgeInsets.all(0),
          label: Text(obligation.status.label),
          textColor: theme.colorScheme.onSurface,
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }

  progressBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      spacing: 8,
      children: [
        SizedBox(
          height: 8,
          child: LinearProgressIndicator(
            value: obligation.completion,
            backgroundColor: theme.colorScheme.surfaceContainer,
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "${(obligation.completion * 100).floor()}%",
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  obligationBuilder(BuildContext context) {
    return tileBuilder(
      context,
      onTap: () {
        handleTap(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [infoBuilder(context), progressBuilder(context)],
          ),
          if (readOnly) progressBarBuilder(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: obligation.id,
      child: obligationBuilder(context),
      dismissable: !readOnly,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
