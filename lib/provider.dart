import 'package:bandha/features/schedules/providers/schedule_filter_provider.dart';
import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:bandha/features/schedules/repositories/schedule_repository.dart';
import 'package:bandha/features/schedules/services/schedule_service.dart';
import 'package:bandha/features/obligations/providers/obligation_payment_provider.dart';
import 'package:bandha/features/obligations/providers/obligation_tab_provider.dart';
import 'package:bandha/features/obligations/services/obligation_payment_service.dart';
import 'package:bandha/features/obligations/services/obligation_service.dart';
import 'package:bandha/features/main/providers/tool_provider.dart';
import 'package:bandha/features/main/services/tool_service.dart';
import 'package:bandha/features/transfers/providers/transfer_filter_provider.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/features/transfers/repositories/transfer_repository.dart';
import 'package:bandha/features/transfers/services/transfer_service.dart';
import 'package:bandha/features/obligations/repositories/obligation_payment_repository.dart';
import 'package:bandha/features/journals/providers/journal_filter_provider.dart';
import 'package:bandha/infra/db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import "package:bandha/features/tags/repositories/category_repository.dart";
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/journals/repositories/journal_repository.dart';
import 'package:bandha/features/journals/services/journal_service.dart';
import 'package:bandha/features/entries/providers/entry_filter_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:bandha/features/entries/services/entry_service.dart';
import 'package:bandha/features/funds/providers/fund_provider.dart';
import 'package:bandha/features/funds/repositories/fund_repository.dart';
import 'package:bandha/features/funds/services/fund_service.dart';
import 'package:bandha/features/obligations/providers/obligation_filter_provider.dart';
import 'package:bandha/features/obligations/providers/obligation_provider.dart';
import 'package:bandha/features/obligations/repositories/obligation_repository.dart';
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
  final journalRepository = JournalRepository(dbManager);
  final transferRepository = TransferRepository(dbManager);
  final obligationRepository = ObligationRepository(dbManager);
  final obligationPaymentRepository = ObligationPaymentRepository(
    dbManager,
  );
  final labelRepository = LabelRepository(dbManager);
  final partyRepository = PartyRepository(dbManager);
  final fundRepository = FundRepository(dbManager);
  final scheduleRepository = ScheduleRepository(dbManager);

  final notificationManager = NotificationManager(
    notificationRepository: notificationRepository,
  );

  final entryService = EntryService(
    entryRepository: entryRepository,
    journalRepository: journalRepository,
    labelRepository: labelRepository,
    categoryRepository: categoryRepository,
    notificationManager: notificationManager,
  );
  final journalService = JournalService(
    journalRepository: journalRepository,
    entryRepository: entryRepository,
    categoryRepository: categoryRepository,
  );
  final transferService = TransferService(
    journalRepository: journalRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
    transferRepository: transferRepository,
  );
  final obligationService = ObligationService(
    journalRepository: journalRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    obligationRepository: obligationRepository,
    paymentRepository: obligationPaymentRepository,
    partyRepository: partyRepository,
    notificationManager: notificationManager,
    labelRepository: labelRepository,
  );
  final fundService = FundService(
    journalRepository: journalRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    fundRepository: fundRepository,
    labelRepository: labelRepository,
  );

  final scheduleService = ScheduleService(
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
    scheduleRepository: scheduleRepository,
    journalRepository: journalRepository,
  );

  final obligationPaymentService = ObligationPaymentService(
    categoryRepository: categoryRepository,
    obligationPaymentRepository: obligationPaymentRepository,
    obligationRepository: obligationRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
    notificationManager: notificationManager,
    partyRepository: partyRepository,
    journalRepository: journalRepository,
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
    ChangeNotifierProvider(create: (_) => JournalProvider(journalService)),
    ChangeNotifierProvider(create: (_) => EntryProvider(entryService)),
    ChangeNotifierProvider(
      create: (_) => TransferProvider(transferService),
    ),
    ChangeNotifierProvider(create: (_) => FundProvider(fundService)),
    ChangeNotifierProvider(
      create: (_) => ObligationProvider(obligationService),
    ),
    ChangeNotifierProvider(
      create: (_) =>
          ObligationPaymentProvider(obligationPaymentService),
    ),
    ChangeNotifierProvider(
      create: (_) => ScheduleProvider(scheduleService),
    ),
    ChangeNotifierProvider(
      create: (_) => LabelProvider(labelRepository),
    ),
    ChangeNotifierProvider(
      create: (_) => PartyProvider(partyRepository),
    ),
    ChangeNotifierProvider(create: (_) => EntryFilterProvider()),
    ChangeNotifierProvider(create: (_) => ObligationFilterProvider()),
    ChangeNotifierProvider(create: (_) => ObligationTabProvider()),
    ChangeNotifierProvider(create: (_) => FundFilterProvider()),
    ChangeNotifierProvider(create: (_) => ScheduleFilterProvider()),
    ChangeNotifierProvider(create: (_) => TransferFilterProvider()),
    ChangeNotifierProvider(create: (_) => JournalFilterProvider()),
  ];

  return MultiProvider(providers: providers, child: child);
}
