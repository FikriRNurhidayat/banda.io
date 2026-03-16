import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/common/widgets/flash.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/loans/entities/loan.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/features/loans/providers/loan_payment_provider.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/loans/providers/loan_provider.dart';
import 'package:bandha/features/funds/providers/fund_provider.dart';
import 'package:bandha/common/widgets/verdict.dart';
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

Future<bool?> confirmScheduleDeletion(
  BuildContext context,
  Schedule schedule,
) async {
  return ask(
    context,
    title: "Delete schedule",
    content:
        "You're about to delete this schedule, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final scheduleProvider = context.read<ScheduleProvider>();

      await scheduleProvider.delete(schedule.id).catchError((
        error,
        stackTrace,
      ) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Delete schedule failed");
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

Future<bool?> confirmVaultDeletion(
  BuildContext context,
  Vault vault,
) async {
  return ask(
    context,
    title: "Delete vault",
    content:
        "You're about to delete this vault, this action cannot be reversed. Are you sure?",
    onConfirm: (context) async {
      final messenger = ScaffoldMessenger.of(context);
      final vaultProvider = context.read<VaultProvider>();

      await vaultProvider.delete(vault.id).catchError((error) {
        alert(messenger, "Delete vault failed");
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
