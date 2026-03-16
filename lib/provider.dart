import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:bandha/features/schedules/repositories/schedule_repository.dart';
import 'package:bandha/features/schedules/services/schedule_service.dart';
import 'package:bandha/features/loans/providers/loan_payment_provider.dart';
import 'package:bandha/features/loans/providers/loan_tab_provider.dart';
import 'package:bandha/features/loans/services/loan_payment_service.dart';
import 'package:bandha/features/loans/services/loan_service.dart';
import 'package:bandha/features/main/providers/tool_provider.dart';
import 'package:bandha/features/main/services/tool_service.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/features/transfers/repositories/transfer_repository.dart';
import 'package:bandha/features/transfers/services/transfer_service.dart';
import 'package:bandha/features/loans/repositories/loan_payment_repository.dart';
import 'package:bandha/infra/db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import "package:bandha/features/tags/repositories/category_repository.dart";
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/vaults/repositories/vault_repository.dart';
import 'package:bandha/features/vaults/services/vault_service.dart';
import 'package:bandha/features/entries/providers/entry_filter_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/entries/services/entry_service.dart';
import 'package:bandha/features/funds/providers/fund_provider.dart';
import 'package:bandha/features/funds/repositories/fund_repository.dart';
import 'package:bandha/features/funds/services/fund_service.dart';
import 'package:bandha/features/loans/providers/loan_filter_provider.dart';
import 'package:bandha/features/loans/providers/loan_provider.dart';
import 'package:bandha/features/loans/repositories/loan_repository.dart';
import 'package:bandha/features/tags/providers/category_provider.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:bandha/features/tags/providers/party_provider.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/features/main/handlers/notification_handler.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/notification.dart';
import 'package:bandha/features/funds/providers/fund_filter_provider.dart';
import 'package:bandha/features/notifications/repositories/notification_repository.dart';

makeProvider({
  required Widget child,
  required NotificationHandler notificationHandler,
}) async {
  final dbManager = DatabaseManager();

  final notificationRepository = NotificationRepository(dbManager);
  final categoryRepository = CategoryRepository(dbManager);
  final entryRepository = EntryRepository(dbManager);
  final vaultRepository = VaultRepository(dbManager);
  final transferRepository = TransferRepository(dbManager);
  final loanRepository = LoanRepository(dbManager);
  final loanPaymentRepository = LoanPaymentRepository(dbManager);
  final labelRepository = LabelRepository(dbManager);
  final partyRepository = PartyRepository(dbManager);
  final fundRepository = FundRepository(dbManager);
  final scheduleRepository = ScheduleRepository(dbManager);

  final notificationManager = NotificationManager(
    notificationRepository: notificationRepository,
  );

  final entryService = EntryService(
    entryRepository: entryRepository,
    vaultRepository: vaultRepository,
    labelRepository: labelRepository,
    categoryRepository: categoryRepository,
    notificationManager: notificationManager,
  );
  final vaultService = VaultService(
    vaultRepository: vaultRepository,
    entryRepository: entryRepository,
    categoryRepository: categoryRepository,
  );
  final transferService = TransferService(
    vaultRepository: vaultRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
    transferRepository: transferRepository,
  );
  final loanService = LoanService(
    vaultRepository: vaultRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    loanRepository: loanRepository,
    paymentRepository: loanPaymentRepository,
    partyRepository: partyRepository,
    notificationManager: notificationManager,
  );
  final fundService = FundService(
    vaultRepository: vaultRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    fundRepository: fundRepository,
    labelRepository: labelRepository,
  );

  final scheduleService = ScheduleService(
    vaultRepository: vaultRepository,
    scheduleRepository: scheduleRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
  );

  final loanPaymentService = LoanPaymentService(
    vaultRepository: vaultRepository,
    entryRepository: entryRepository,
    categoryRepository: categoryRepository,
    loanRepository: loanRepository,
    loanPaymentRepository: loanPaymentRepository,
    partyRepository: partyRepository,
    notificationManager: notificationManager,
  );

  final toolService = ToolService(dbManager);

  await notificationManager.init(
    notificationHandler,
    didReceiveBackgroundNotificationResponseCallback,
  );

  final providers = [
    ChangeNotifierProvider(create: (_) => ToolProvider(toolService)),
    ChangeNotifierProvider(
      create: (_) => CategoryProvider(categoryRepository),
    ),
    ChangeNotifierProvider(
      create: (_) => VaultProvider(vaultService),
    ),
    ChangeNotifierProvider(create: (_) => EntryProvider(entryService)),
    ChangeNotifierProvider(
      create: (_) => TransferProvider(transferService),
    ),
    ChangeNotifierProvider(create: (_) => FundProvider(fundService)),
    ChangeNotifierProvider(create: (_) => LoanProvider(loanService)),
    ChangeNotifierProvider(
      create: (_) => LoanPaymentProvider(loanPaymentService),
    ),
    ChangeNotifierProvider(create: (_) => ScheduleProvider(scheduleService)),
    ChangeNotifierProvider(
      create: (_) => LabelProvider(labelRepository),
    ),
    ChangeNotifierProvider(
      create: (_) => PartyProvider(partyRepository),
    ),
    ChangeNotifierProvider(create: (_) => EntryFilterProvider()),
    ChangeNotifierProvider(create: (_) => LoanFilterProvider()),
    ChangeNotifierProvider(create: (_) => LoanTabProvider()),
    ChangeNotifierProvider(create: (_) => FundFilterProvider()),
  ];

  return MultiProvider(providers: providers, child: child);
}
