import 'package:banda/common/helpers/alert_helper.dart';
import 'package:banda/common/widgets/flash.dart';
import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/bills/entities/bill.dart';
import 'package:banda/features/bills/providers/bill_provider.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/loans/entities/loan.dart';
import 'package:banda/features/funds/entities/fund.dart';
import 'package:banda/features/loans/providers/loan_payment_provider.dart';
import 'package:banda/features/transfers/entities/transfer.dart';
import 'package:banda/features/transfers/providers/transfer_provider.dart';
import 'package:banda/features/accounts/providers/account_provider.dart';
import 'package:banda/features/entries/providers/entry_provider.dart';
import 'package:banda/features/loans/providers/loan_provider.dart';
import 'package:banda/features/funds/providers/fund_provider.dart';
import 'package:banda/common/widgets/verdict.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

navigateFlash(
  NavigatorState navigator, {
  required String title,
  required String content,
  required Future<void> Function(BuildContext context)? onTap,
}) async {
  onTap ??= (BuildContext context) async {};

  final reply = await navigator.push<bool>(
    MaterialPageRoute(
      builder: (context) =>
          Flash(title: title, content: content, onTap: onTap!),
      fullscreenDialog: true,
    ),
  );

  if (reply is bool) {
    return reply;
  }

  return false;
}

flash(
  BuildContext context, {
  required String title,
  required String content,
  required Future<void> Function(BuildContext context)? onTap,
}) async {
  final navigator = Navigator.of(context);
  return navigateFlash(
    navigator,
    title: title,
    content: content,
    onTap: onTap,
  );
}

Future<bool?> ask(
  BuildContext context, {
  required String title,
  required String content,
  required Future<void> Function(BuildContext context) onConfirm,
  Future<void> Function(BuildContext context)? onDeny,
}) async {
  final navigator = Navigator.of(context);
  onDeny ??= (BuildContext context) async {};

  final reply = await navigator.push<bool>(
    MaterialPageRoute(
      builder: (context) => Verdict(
        title: title,
        content: content,
        onConfirm: onConfirm,
        onDeny: onDeny!,
      ),
      fullscreenDialog: true,
    ),
  );

  if (reply is bool) {
    return reply;
  }

  return false;
}

Future<bool?> confirmFundTransactionDeletion(
  BuildContext context,
  Fund fund,
  Entry entry,
) async {
  return ask(
    context,
    title: "Delete fund entry",
    content:
        "You're about to delete this fund entry, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final fundProvider = context.read<FundProvider>();

      await fundProvider
          .deleteTransaction(fundId: fund.id, entryId: entry.id)
          .catchError((error) {
            alert(messenger, "Delete fund entry failed");
            throw error;
          });
    },
  );
}

Future<bool?> confirmFundDeletion(
  BuildContext context,
  Fund fund,
) async {
  return ask(
    context,
    title: "Delete fund",
    content:
        "You're about to delete this fund, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final fundProvider = context.read<FundProvider>();

      await fundProvider.delete(fund.id).catchError((error) {
        alert(messenger, "Delete fund failed");
        throw error;
      });
    },
  );
}

Future<bool?> confirmBillDeletion(
  BuildContext context,
  Bill bill,
) async {
  return ask(
    context,
    title: "Delete bill",
    content:
        "You're about to delete this bill, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final billProvider = context.read<BillProvider>();

      await billProvider.delete(bill.id).catchError((
        error,
        stackTrace,
      ) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Delete bill failed");
        throw error;
      });
    },
  );
}

Future<bool?> confirmLoanDeletion(
  BuildContext context,
  Loan loan,
) async {
  return ask(
    context,
    title: "Delete loan",
    content:
        "You're about to delete this loan, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final loanProvider = context.read<LoanProvider>();

      await loanProvider.delete(loan.id).catchError((
        error,
        stackTrace,
      ) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Delete loan failed");
        throw error;
      });
    },
  );
}

Future<bool?> confirmTransferDeletion(
  BuildContext context,
  Transfer transfer,
) async {
  return ask(
    context,
    title: "Delete transfer",
    content:
        "You're about to delete this transfer, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final transferProvider = context.read<TransferProvider>();

      await transferProvider.remove(transfer.id).catchError((
        error,
        stackTrace,
      ) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Delete transfer failed");
        throw error;
      });
    },
  );
}

Future<bool?> confirmAccountDeletion(
  BuildContext context,
  Account account,
) async {
  return ask(
    context,
    title: "Delete account",
    content:
        "You're about to delete this account, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final accountProvider = context.read<AccountProvider>();

      await accountProvider.delete(account.id).catchError((error) {
        alert(messenger, "Delete account failed");
        throw error;
      });
    },
  );
}

Future<bool?> confirmEntryDeletion(
  BuildContext context,
  Entry entry,
) async {
  return ask(
    context,
    title: "Delete entry",
    content:
        "You're about to delete this entry, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final entryProvider = context.read<EntryProvider>();

      await entryProvider.delete(entry.id).catchError((
        error,
        stackTrace,
      ) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Delete entry failed");
        throw error;
      });
    },
  );
}

Future<bool?> confirmLoanPaymentDeletion(
  BuildContext context,
  Loan loan,
  Entry entry,
) async {
  return ask(
    context,
    title: "Delete payment",
    content:
        "You're about to delete this payment, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final loanPaymentProvider = context.read<LoanPaymentProvider>();

      await loanPaymentProvider.delete(loan.id, entry.id).catchError((
        error,
        stackTrace,
      ) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Delete payment failed");
        throw error;
      });
    },
  );
}
