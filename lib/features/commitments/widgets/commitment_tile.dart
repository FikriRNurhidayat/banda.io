import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/features/vaults/widgets/vault_text.dart';
import 'package:bandha/common/widgets/date_time_text.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';

class CommitmentTile extends StatelessWidget {
  final Commitment commitment;
  final bool readOnly;

  const CommitmentTile(
    this.commitment, {
    super.key,
    this.readOnly = false,
  });

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      readOnly
          ? "/commitments/${commitment.id}/detail"
          : "/commitments/${commitment.id}/payments",
    );
  }

  handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmCommitmentDeletion(context, commitment);
    }

    Navigator.pushNamed(context, "/commitments/${commitment.id}/edit");
    return Future.value(false);
  }

  Widget statusBuilder(BuildContext context) {
    final theme = Theme.of(context);
    switch (commitment.status) {
      case CommitmentStatus.active:
        return Icon(
          Icons.hourglass_empty,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case CommitmentStatus.overdue:
        return Icon(
          Icons.hourglass_full,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case CommitmentStatus.settled:
        return Icon(
          Icons.check,
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
                commitment.category.name,
                style: theme.textTheme.titleSmall,
              ),
              statusBuilder(context),
              if (commitment.hasLabels)
                labelsBuilder(
                  context,
                  commitment.labels,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          DateTimeText(commitment.issuedAt),
          VaultText(commitment.vault),
          Text(commitment.party.name, style: theme.textTheme.bodySmall),
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
              commitment.paid,
              useSymbol: false,
              style: theme.textTheme.bodySmall,
            ),
            Text("/"),
            MoneyText(
              commitment.amount,
              useSymbol: false,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        Badge(
          padding: EdgeInsets.all(0),
          label: Text(commitment.status.label),
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
            value: commitment.completion,
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
              "${(commitment.completion * 100).floor()}%",
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  commitmentBuilder(BuildContext context) {
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
      key: commitment.id,
      child: commitmentBuilder(context),
      dismissable: !readOnly,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
