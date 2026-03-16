import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/common/widgets/date_time_text.dart';
import 'package:bandha/features/loans/entities/loan.dart';
import 'package:bandha/features/loans/entities/loan_payment.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentTile extends StatelessWidget {
  final Loan loan;
  final LoanPayment payment;
  final dateFormatter = DateFormat("yyyy/MM/dd");

  PaymentTile({super.key, required this.payment, required this.loan});

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return await confirmLoanPaymentDeletion(
        context,
        loan,
        payment.entry,
      );
    }

    Navigator.pushNamed(
      context,
      "/loans/${loan.id}/payments/${payment.entry.id}/edit",
    );

    return false;
  }

  handleTap(BuildContext context, LoanPayment payment) {
    Navigator.pushNamed(
      context,
      "/loans/${loan.id}/payments/${payment.entry.id}/detail",
    );
  }

  infoBuilder(BuildContext context, LoanPayment payment) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          payment.entry.account.displayName(),
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        DateTimeText(payment.issuedAt),
        if (!isNull(payment.entry.note))
          Text(
            payment.entry.note!,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  amountBuilder(BuildContext context, LoanPayment payment) {
    return MoneyText(payment.amount.abs(), useSymbol: false);
  }

  headerBuilder(BuildContext context, LoanPayment payment) {
    final theme = Theme.of(context);

    return Row(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          payment.entry.category.name,
          style: theme.textTheme.titleSmall,
        ),
        if (loan.status.isSettled)
          Icon(Icons.lock, size: 8, color: theme.colorScheme.primary),
      ],
    );
  }

  paymentBuilder(BuildContext context, LoanPayment payment) {
    return tileBuilder(
      context,
      onTap: () {
        handleTap(context, payment);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerBuilder(context, payment),
              infoBuilder(context, payment),
            ],
          ),
          amountBuilder(context, payment),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dismissibleBuilder(
      context,
      key: payment.entry.id,
      dismissable: !loan.status.isSettled,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
      child: paymentBuilder(context, payment),
    );
  }
}
