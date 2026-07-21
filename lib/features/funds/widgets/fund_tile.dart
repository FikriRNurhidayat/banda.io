import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/money_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/features/journals/widgets/journal_text.dart';
import 'package:flutter/material.dart';

class FundTile extends StatelessWidget {
  final Fund fund;
  final bool readOnly;

  const FundTile(this.fund, {super.key, this.readOnly = false});

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      readOnly
          ? "/funds/${fund.id}/detail"
          : "/funds/${fund.id}/transactions",
    );
  }

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmFundDeletion(context, fund);
    }

    Navigator.pushNamed(context, "/funds/${fund.id}/edit");
    return false;
  }

  statusBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return [
      if (fund.status == FundStatus.released)
        Icon(Icons.lock, size: 8, color: theme.colorScheme.primary),
      if (fund.status != FundStatus.released &&
          fund.balance == fund.amount)
        Icon(Icons.done_all, size: 8, color: theme.colorScheme.primary),
    ];
  }

  infoBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JournalText(fund.journal),
        Row(
          spacing: 8,
          children: [
            if (fund.labels.isNotEmpty)
              labelsBuilder(
                context,
                fund.labels,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ...statusBuilder(context),
          ],
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
            value: fund.progress,
            backgroundColor: theme.colorScheme.surfaceContainer,
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              fund.category.name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              "${(fund.completion * 100).floor()}%",
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  progressBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              MoneyHelper.normalize(fund.balance),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            Text("/", style: theme.textTheme.bodySmall),
            Text(
              MoneyHelper.normalize(fund.amount),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        Text(fund.status.label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  fundBuilder(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: infoBuilder(context)),
              progressBuilder(context),
            ],
          ),
          progressBarBuilder(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: fund.id,
      dismissable: !readOnly,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
      child: fundBuilder(context),
    );
  }
}
