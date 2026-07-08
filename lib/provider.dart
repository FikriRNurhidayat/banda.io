import 'package:bandha/features/schedules/providers/schedule_filter_provider.dart';
import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:bandha/features/schedules/repositories/schedule_repository.dart';
import 'package:bandha/features/schedules/services/schedule_service.dart';
import 'package:bandha/features/settlements/providers/settlement_payment_provider.dart';
import 'package:bandha/features/settlements/providers/settlement_tab_provider.dart';
import 'package:bandha/features/settlements/services/settlement_payment_service.dart';
import 'package:bandha/features/settlements/services/settlement_service.dart';
import 'package:bandha/features/main/providers/tool_provider.dart';
import 'package:bandha/features/main/services/tool_service.dart';
import 'package:bandha/features/transfers/providers/transfer_filter_provider.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/features/transfers/repositories/transfer_repository.dart';
import 'package:bandha/features/transfers/services/transfer_service.dart';
import 'package:bandha/features/settlements/repositories/settlement_payment_repository.dart';
import 'package:bandha/features/vaults/providers/vault_filter_provider.dart';
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
import 'package:bandha/features/pools/providers/pool_provider.dart';
import 'package:bandha/features/pools/repositories/pool_repository.dart';
import 'package:bandha/features/pools/services/pool_service.dart';
import 'package:bandha/features/settlements/providers/settlement_filter_provider.dart';
import 'package:bandha/features/settlements/providers/settlement_provider.dart';
import 'package:bandha/features/settlements/repositories/settlement_repository.dart';
import 'package:bandha/features/tags/providers/category_provider.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:bandha/features/tags/providers/party_provider.dart';
import 'package:bandha/features/tags/repositories/label_repository.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';
import 'package:bandha/features/main/handlers/notification_handler.dart';
import 'package:bandha/features/notifications/managers/notification_manager.dart';
import 'package:bandha/notification.dart';
import 'package:bandha/features/pools/providers/pool_filter_provider.dart';
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
  final settlementRepository = SettlementRepository(dbManager);
  final settlementPaymentRepository = SettlementPaymentRepository(
    dbManager,
  );
  final labelRepository = LabelRepository(dbManager);
  final partyRepository = PartyRepository(dbManager);
  final poolRepository = PoolRepository(dbManager);
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
  final settlementService = SettlementService(
    vaultRepository: vaultRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    settlementRepository: settlementRepository,
    paymentRepository: settlementPaymentRepository,
    partyRepository: partyRepository,
    notificationManager: notificationManager,
    labelRepository: labelRepository,
  );
  final poolService = PoolService(
    vaultRepository: vaultRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    poolRepository: poolRepository,
    labelRepository: labelRepository,
  );

  final scheduleService = ScheduleService(
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
    scheduleRepository: scheduleRepository,
    vaultRepository: vaultRepository,
  );

  final settlementPaymentService = SettlementPaymentService(
    categoryRepository: categoryRepository,
    settlementPaymentRepository: settlementPaymentRepository,
    settlementRepository: settlementRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
    notificationManager: notificationManager,
    partyRepository: partyRepository,
    vaultRepository: vaultRepository,
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
    ChangeNotifierProvider(create: (_) => VaultProvider(vaultService)),
    ChangeNotifierProvider(create: (_) => EntryProvider(entryService)),
    ChangeNotifierProvider(
      create: (_) => TransferProvider(transferService),
    ),
    ChangeNotifierProvider(create: (_) => PoolProvider(poolService)),
    ChangeNotifierProvider(
      create: (_) => SettlementProvider(settlementService),
    ),
    ChangeNotifierProvider(
      create: (_) =>
          SettlementPaymentProvider(settlementPaymentService),
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
    ChangeNotifierProvider(create: (_) => SettlementFilterProvider()),
    ChangeNotifierProvider(create: (_) => SettlementTabProvider()),
    ChangeNotifierProvider(create: (_) => PoolFilterProvider()),
    ChangeNotifierProvider(create: (_) => ScheduleFilterProvider()),
    ChangeNotifierProvider(create: (_) => TransferFilterProvider()),
    ChangeNotifierProvider(create: (_) => VaultFilterProvider()),
  ];

  return MultiProvider(providers: providers, child: child);
}
