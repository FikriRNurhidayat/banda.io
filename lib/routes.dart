import 'package:bandha/features/entries/views/entries_insights.dart';
import 'package:bandha/features/journals/views/journal_editor.dart';
import 'package:bandha/features/journals/views/journal_entries.dart';
import 'package:bandha/features/journals/views/journal_menu.dart';
import 'package:bandha/features/journals/views/journals.dart';
import 'package:bandha/features/schedules/views/schedule_editor.dart';
import 'package:bandha/features/schedules/views/schedule_history.dart';
import 'package:bandha/features/schedules/views/schedule_menu.dart';
import 'package:bandha/features/schedules/views/schedules.dart';
import 'package:bandha/features/entries/views/entries.dart';
import 'package:bandha/features/entries/views/entry_editor.dart';
import 'package:bandha/features/entries/views/entry_filter.dart';
import 'package:bandha/features/entries/views/entry_menu.dart';
import 'package:bandha/features/funds/views/fund_editor.dart';
import 'package:bandha/features/funds/views/fund_entries.dart';
import 'package:bandha/features/funds/views/fund_entry_editor.dart';
import 'package:bandha/features/funds/views/fund_filter.dart';
import 'package:bandha/features/funds/views/fund_menu.dart';
import 'package:bandha/features/funds/views/funds.dart';
import 'package:bandha/features/tags/views/party_selector.dart';
import 'package:bandha/features/transfers/views/transfer_editor.dart';
import 'package:bandha/features/transfers/views/transfer_entries.dart';
import 'package:bandha/features/transfers/views/transfer_menu.dart';
import 'package:bandha/features/transfers/views/transfers.dart';
import 'package:bandha/features/tags/views/category_selector.dart';
import 'package:bandha/features/tags/views/label_selector.dart';
import 'package:bandha/features/obligations/views/obligation_editor.dart';
import 'package:bandha/features/obligations/views/obligation_filter.dart';
import 'package:bandha/features/obligations/views/obligation_menu.dart';
import 'package:bandha/features/obligations/views/obligation_entry_editor.dart';
import 'package:bandha/features/obligations/views/obligation_entries.dart';
import 'package:bandha/features/obligations/views/obligations.dart';
import 'package:bandha/features/main/views/main_menu.dart';
import 'package:bandha/features/main/views/tools.dart';
import 'package:bandha/features/assets/views/assets.dart';
import 'package:bandha/features/assets/views/asset_editor.dart';
import 'package:bandha/features/assets/views/asset_menu.dart';
import 'package:bandha/features/assets/views/asset_entries.dart';
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
      case '/entries/insights':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => EntriesInsights(),
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
          builder: (context) => ObligationFilter(),
        );
      case '/obligations':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Obligations(),
        );
      case '/obligations/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ObligationEditor(),
        );
      case '/obligations/filter':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ObligationFilter(),
        );
      case '/funds':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Funds(),
        );
      case '/funds/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => FundEditor(),
        );
      case '/funds/filter':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => FundFilter(),
        );
      case '/journals':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Journals(),
        );
      case '/journals/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => JournalEditor(),
        );
      case '/assets':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Assets(),
        );
      case '/assets/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => AssetEditor(),
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
    }

    final uri = Uri.parse(settings.name!);
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments.last == "edit") {
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
        case 'obligations':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ObligationEditor(id: id),
          );
        case 'journals':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => JournalEditor(id: id),
          );
        case 'transfers':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => TransferEditor(id: id),
          );
        case 'funds':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FundEditor(id: id),
          );
        case 'assets':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => AssetEditor(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments.last == "menu") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'entries':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => EntryMenu(id: id),
          );
        case 'journals':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => JournalMenu(id: id),
          );
        case 'obligations':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ObligationMenu(id: id),
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
        case 'funds':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FundMenu(id: id),
          );
        case 'assets':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => AssetMenu(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments.last == "payments") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'obligations':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ObligationEntries(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments.last == "transactions") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'funds':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FundEntries(fundId: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments.last == "history") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'schedules':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ScheduleHistory(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments.last == "entries") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'funds':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FundEntries(fundId: id),
          );
        case 'journals':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => JournalEntries(id: id),
          );
        case 'transfers':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => TransferEntries(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments.last == "detail") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'schedules':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) =>
                ScheduleEditor(id: id, readOnly: true),
          );
        case 'entries':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => EntryEditor(id: id, readOnly: true),
          );
        case 'obligations':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) =>
                ObligationEditor(id: id, readOnly: true),
          );
        case 'journals':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => JournalEditor(id: id, readOnly: true),
          );
        case 'transfers':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) =>
                TransferEditor(id: id, readOnly: true),
          );
        case 'funds':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FundEditor(id: id, readOnly: true),
          );
        case 'assets':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => AssetEntries(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 4) {
      if (uri.pathSegments.first == "funds" &&
          uri.pathSegments[2] == "transactions" &&
          uri.pathSegments[3] == "new") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              FundEntryEditor(fundId: uri.pathSegments[1]),
        );
      }
    }

    if (uri.pathSegments.length == 4) {
      if (uri.pathSegments.first == "obligations" &&
          uri.pathSegments[2] == "payments" &&
          uri.pathSegments[3] == "new") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              ObligationEntryEditor(obligationId: uri.pathSegments[1]),
        );
      }
    }

    if (uri.pathSegments.length == 5) {
      if (uri.pathSegments.first == "obligations" &&
          uri.pathSegments[2] == "payments" &&
          uri.pathSegments.last == "edit") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ObligationEntryEditor(
            obligationId: uri.pathSegments[1],
            entryId: uri.pathSegments[3],
            readOnly: false,
          ),
        );
      }

      if (uri.pathSegments.first == "obligations" &&
          uri.pathSegments[2] == "payments" &&
          uri.pathSegments.last == "detail") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ObligationEntryEditor(
            obligationId: uri.pathSegments[1],
            entryId: uri.pathSegments[3],
            readOnly: true,
          ),
        );
      }
    }

    if (uri.pathSegments.length == 5) {
      if (uri.pathSegments.first == "funds" &&
          uri.pathSegments[2] == "transactions" &&
          uri.pathSegments.last == "edit") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => FundEntryEditor(
            fundId: uri.pathSegments[1],
            entryId: uri.pathSegments[3],
          ),
        );
      }

      if (uri.pathSegments.first == "funds" &&
          uri.pathSegments[2] == "transactions" &&
          uri.pathSegments.last == "detail") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => FundEntryEditor(
            fundId: uri.pathSegments[1],
            entryId: uri.pathSegments[3],
            readOnly: true,
          ),
        );
      }
    }

    return null;
  }
}
