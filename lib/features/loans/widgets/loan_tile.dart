import 'package:banda/features/loans/entities/loan.dart';
import 'package:banda/common/helpers/dialog_helper.dart';
import 'package:banda/common/helpers/tile_helper.dart';
import 'package:banda/features/accounts/widgets/account_text.dart';
import 'package:banda/common/widgets/date_time_text.dart';
import 'package:banda/common/widgets/money_text.dart';
import 'package:flutter/material.dart';

class LoanTile extends StatelessWidget {
  final Loan loan;
  final bool readOnly;

  const LoanTile(this.loan, {super.key, this.readOnly = false});

  handleTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      readOnly
          ? "/loans/${loan.id}/detail"
          : "/loans/${loan.id}/payments",
    );
  }

  handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return confirmLoanDeletion(context, loan);
    }

    Navigator.pushNamed(context, "/loans/${loan.id}/edit");
    return Future.value(false);
  }

  Widget statusBuilder(BuildContext context) {
    final theme = Theme.of(context);
    switch (loan.status) {
      case LoanStatus.active:
        return Icon(
          Icons.hourglass_empty,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case LoanStatus.overdue:
        return Icon(
          Icons.hourglass_full,
          color: theme.colorScheme.primary,
          size: 8,
        );
      case LoanStatus.settled:
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
              Text(loan.type.label, style: theme.textTheme.titleSmall),
              statusBuilder(context),
            ],
          ),
          DateTimeText(loan.issuedAt),
          AccountText(loan.account),
          Text(loan.party.name, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  progressBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
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
                loan.paid,
                useSymbol: false,
                style: theme.textTheme.bodySmall,
              ),
              Text("/"),
              MoneyText(
                loan.amount,
                useSymbol: false,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          Badge(
            padding: EdgeInsets.all(0),
            label: Text(loan.status.label),
            textColor: theme.colorScheme.onSurface,
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
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
            value: loan.completion,
            backgroundColor: theme.colorScheme.surfaceContainer,
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MoneyText(
              loan.paid,
              useSymbol: false,
              style: theme.textTheme.labelSmall,
            ),
            MoneyText(
              loan.amount,
              useSymbol: false,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  loanBuilder(BuildContext context) {
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
      key: loan.id,
      child: loanBuilder(context),
      dismissable: !readOnly,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
    );
  }
}
