import 'package:bandha/features/vaults/views/vault_editor.dart';
import 'package:bandha/features/vaults/views/vault_entries.dart';
import 'package:bandha/features/vaults/views/vault_menu.dart';
import 'package:bandha/features/vaults/views/vaults.dart';
import 'package:bandha/features/schedules/views/schedule_editor.dart';
import 'package:bandha/features/schedules/views/schedule_history.dart';
import 'package:bandha/features/schedules/views/schedule_menu.dart';
import 'package:bandha/features/schedules/views/schedules.dart';
import 'package:bandha/features/entries/views/entries.dart';
import 'package:bandha/features/entries/views/entry_editor.dart';
import 'package:bandha/features/entries/views/entry_filter.dart';
import 'package:bandha/features/entries/views/entry_menu.dart';
import 'package:bandha/features/pools/views/pool_editor.dart';
import 'package:bandha/features/pools/views/pool_entries.dart';
import 'package:bandha/features/pools/views/pool_entry_editor.dart';
import 'package:bandha/features/pools/views/pool_filter.dart';
import 'package:bandha/features/pools/views/pool_menu.dart';
import 'package:bandha/features/pools/views/pools.dart';
import 'package:bandha/features/tags/views/party_selector.dart';
import 'package:bandha/features/transfers/views/transfer_editor.dart';
import 'package:bandha/features/transfers/views/transfer_entries.dart';
import 'package:bandha/features/transfers/views/transfer_menu.dart';
import 'package:bandha/features/transfers/views/transfers.dart';
import 'package:bandha/features/tags/views/category_selector.dart';
import 'package:bandha/features/main/views/information.dart';
import 'package:bandha/features/tags/views/label_selector.dart';
import 'package:bandha/features/loans/views/loan_editor.dart';
import 'package:bandha/features/loans/views/loan_filter.dart';
import 'package:bandha/features/loans/views/loan_menu.dart';
import 'package:bandha/features/loans/views/loan_entry_editor.dart';
import 'package:bandha/features/loans/views/loan_entries.dart';
import 'package:bandha/features/loans/views/loans.dart';
import 'package:bandha/features/main/views/main_menu.dart';
import 'package:bandha/features/main/views/tools.dart';
import 'package:flutter/material.dart';

class Routes {
  static Route<dynamic>? makeRoutes(RouteSettings settings) {
    switch (settings.name!) {
      case '/':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => MainMenu(),
        );
      case '/entries':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Entries(),
        );
      case '/entries/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => EntryEditor(),
        );
      case '/entries/filter':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => EntryFilter(),
        );
      case '/schedules':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Schedules(),
        );
      case '/schedules/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ScheduleEditor(),
        );
      case '/schedules/filter':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => LoanFilter(),
        );
      case '/loans':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Loans(),
        );
      case '/loans/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => LoanEditor(),
        );
      case '/loans/filter':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => LoanFilter(),
        );
      case '/pools':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Pools(),
        );
      case '/pools/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => PoolEditor(),
        );
      case '/pools/filter':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => PoolFilter(),
        );
      case '/vaults':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Vaults(),
        );
      case '/vaults/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => VaultEditor(),
        );
      case '/transfers':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Transfers(),
        );
      case '/transfers/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => TransferEditor(),
        );
      case '/parties/edit':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => PartySelector(),
        );
      case '/categories/edit':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => CategorySelector(),
        );
      case '/labels/edit':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => LabelSelector(),
        );
      case '/tools':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Tools(),
        );
      case '/info':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Information(),
        );
    }

    final uri = Uri.parse(settings.name!);
    if (uri.pathSegments.length == 3 && uri.pathSegments.last == "edit") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'schedules':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ScheduleEditor(id: id),
          );
        case 'entries':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => EntryEditor(id: id),
          );
        case 'loans':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => LoanEditor(id: id),
          );
        case 'vaults':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => VaultEditor(id: id),
          );
        case 'transfers':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => TransferEditor(id: id),
          );
        case 'pools':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => PoolEditor(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 && uri.pathSegments.last == "menu") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'entries':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => EntryMenu(id: id),
          );
        case 'vaults':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => VaultMenu(id: id),
          );
        case 'loans':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => LoanMenu(id: id),
          );
        case 'schedules':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ScheduleMenu(id: id),
          );
        case 'transfers':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => TransferMenu(id: id),
          );
        case 'pools':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => PoolMenu(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 && uri.pathSegments.last == "payments") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'loans':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => LoanEntries(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments.last == "transactions") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'pools':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => PoolEntries(poolId: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 && uri.pathSegments.last == "history") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'schedules':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ScheduleHistory(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 && uri.pathSegments.last == "entries") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'pools':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => PoolEntries(poolId: id),
          );
        case 'vaults':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => VaultEntries(id: id),
          );
        case 'transfers':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => TransferEntries(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 && uri.pathSegments.last == "detail") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'schedules':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ScheduleEditor(id: id, readOnly: true),
          );
        case 'entries':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => EntryEditor(id: id, readOnly: true),
          );
        case 'loans':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => LoanEditor(id: id, readOnly: true),
          );
        case 'vaults':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => VaultEditor(id: id, readOnly: true),
          );
        case 'transfers':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => TransferEditor(id: id, readOnly: true),
          );
        case 'pools':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => PoolEditor(id: id, readOnly: true),
          );
      }
    }

    if (uri.pathSegments.length == 4) {
      if (uri.pathSegments.first == "pools" &&
          uri.pathSegments[2] == "transactions" &&
          uri.pathSegments[3] == "new") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => PoolEntryEditor(poolId: uri.pathSegments[1]),
        );
      }
    }

    if (uri.pathSegments.length == 4) {
      if (uri.pathSegments.first == "loans" &&
          uri.pathSegments[2] == "payments" &&
          uri.pathSegments[3] == "new") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => LoanEntryEditor(loanId: uri.pathSegments[1]),
        );
      }
    }

    if (uri.pathSegments.length == 5) {
      if (uri.pathSegments.first == "loans" &&
          uri.pathSegments[2] == "payments" &&
          uri.pathSegments.last == "edit") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => LoanEntryEditor(
            loanId: uri.pathSegments[1],
            entryId: uri.pathSegments[3],
            readOnly: false,
          ),
        );
      }

      if (uri.pathSegments.first == "loans" &&
          uri.pathSegments[2] == "payments" &&
          uri.pathSegments.last == "detail") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => LoanEntryEditor(
            loanId: uri.pathSegments[1],
            entryId: uri.pathSegments[3],
            readOnly: true,
          ),
        );
      }
    }

    if (uri.pathSegments.length == 5) {
      if (uri.pathSegments.first == "pools" &&
          uri.pathSegments[2] == "transactions" &&
          uri.pathSegments.last == "edit") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => PoolEntryEditor(
            poolId: uri.pathSegments[1],
            entryId: uri.pathSegments[3],
          ),
        );
      }

      if (uri.pathSegments.first == "pools" &&
          uri.pathSegments[2] == "transactions" &&
          uri.pathSegments.last == "detail") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => PoolEntryEditor(
            poolId: uri.pathSegments[1],
            entryId: uri.pathSegments[3],
            readOnly: true,
          ),
        );
      }
    }

    return null;
  }
}
