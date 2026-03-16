import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:bandha/features/schedules/repositories/schedule_repository.dart';
import 'package:bandha/features/schedules/services/schedule_service.dart';
import 'package:bandha/features/commitments/providers/commitment_payment_provider.dart';
import 'package:bandha/features/commitments/providers/commitment_tab_provider.dart';
import 'package:bandha/features/commitments/services/commitment_payment_service.dart';
import 'package:bandha/features/commitments/services/commitment_service.dart';
import 'package:bandha/features/main/providers/tool_provider.dart';
import 'package:bandha/features/main/services/tool_service.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/features/transfers/repositories/transfer_repository.dart';
import 'package:bandha/features/transfers/services/transfer_service.dart';
import 'package:bandha/features/commitments/repositories/commitment_payment_repository.dart';
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
import 'package:bandha/features/commitments/providers/commitment_filter_provider.dart';
import 'package:bandha/features/commitments/providers/commitment_provider.dart';
import 'package:bandha/features/commitments/repositories/commitment_repository.dart';
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
  final commitmentRepository = CommitmentRepository(dbManager);
  final commitmentPaymentRepository = CommitmentPaymentRepository(dbManager);
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
  final commitmentService = CommitmentService(
    vaultRepository: vaultRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    commitmentRepository: commitmentRepository,
    paymentRepository: commitmentPaymentRepository,
    partyRepository: partyRepository,
    notificationManager: notificationManager,
  );
  final poolService = PoolService(
    vaultRepository: vaultRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    poolRepository: poolRepository,
    labelRepository: labelRepository,
  );

  final scheduleService = ScheduleService(
    vaultRepository: vaultRepository,
    scheduleRepository: scheduleRepository,
    categoryRepository: categoryRepository,
    entryRepository: entryRepository,
    labelRepository: labelRepository,
  );

  final commitmentPaymentService = CommitmentPaymentService(
    vaultRepository: vaultRepository,
    entryRepository: entryRepository,
    categoryRepository: categoryRepository,
    commitmentRepository: commitmentRepository,
    commitmentPaymentRepository: commitmentPaymentRepository,
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
    ChangeNotifierProvider(create: (_) => PoolProvider(poolService)),
    ChangeNotifierProvider(create: (_) => CommitmentProvider(commitmentService)),
    ChangeNotifierProvider(
      create: (_) => CommitmentPaymentProvider(commitmentPaymentService),
    ),
    ChangeNotifierProvider(create: (_) => ScheduleProvider(scheduleService)),
    ChangeNotifierProvider(
      create: (_) => LabelProvider(labelRepository),
    ),
    ChangeNotifierProvider(
      create: (_) => PartyProvider(partyRepository),
    ),
    ChangeNotifierProvider(create: (_) => EntryFilterProvider()),
    ChangeNotifierProvider(create: (_) => CommitmentFilterProvider()),
    ChangeNotifierProvider(create: (_) => CommitmentTabProvider()),
    ChangeNotifierProvider(create: (_) => PoolFilterProvider()),
  ];

  return MultiProvider(providers: providers, child: child);
}
