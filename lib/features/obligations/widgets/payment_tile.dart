import 'package:bandha/common/widgets/date_time_text.dart';
import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/features/obligations/entities/obligation_payment.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/common/helpers/tile_helper.dart';
import 'package:bandha/common/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentTile extends StatelessWidget {
  final Obligation obligation;
  final ObligationPayment payment;
  final dateFormatter = DateFormat("yyyy/MM/dd");

  PaymentTile({
    super.key,
    required this.payment,
    required this.obligation,
  });

  Future<bool?> handleDismiss(
    BuildContext context,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      return await confirmObligationPaymentDeletion(
        context,
        obligation,
        payment.entry,
      );
    }

    Navigator.pushNamed(
      context,
      "/obligations/${obligation.id}/payments/${payment.entry.id}/edit",
    );

    return false;
  }

  handleTap(BuildContext context, ObligationPayment payment) {
    Navigator.pushNamed(
      context,
      "/obligations/${obligation.id}/payments/${payment.entry.id}/detail",
    );
  }

  infoBuilder(BuildContext context, ObligationPayment payment) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          payment.entry.journal.displayName(),
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        DateTimeText(payment.issuedAt),
      ],
    );
  }

  amountBuilder(BuildContext context, ObligationPayment payment) {
    return MoneyText(payment.amount.abs(), useSymbol: false);
  }

  paymentBuilder(BuildContext context, ObligationPayment payment) {
    return tileBuilder(
      context,
      onTap: () {
        handleTap(context, payment);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          infoBuilder(context, payment),
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
      dismissable: !obligation.status.isSettled,
      confirmDismiss: (direction) {
        return handleDismiss(context, direction);
      },
      child: paymentBuilder(context, payment),
    );
  }
}
