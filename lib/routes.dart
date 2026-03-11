import 'package:banda/features/accounts/views/account_editor.dart';
import 'package:banda/features/accounts/views/account_entries.dart';
import 'package:banda/features/accounts/views/account_menu.dart';
import 'package:banda/features/accounts/views/accounts.dart';
import 'package:banda/features/bills/views/bill_editor.dart';
import 'package:banda/features/bills/views/bill_history.dart';
import 'package:banda/features/bills/views/bill_menu.dart';
import 'package:banda/features/bills/views/bills.dart';
import 'package:banda/features/entries/views/entries.dart';
import 'package:banda/features/entries/views/entry_editor.dart';
import 'package:banda/features/entries/views/entry_filter.dart';
import 'package:banda/features/entries/views/entry_menu.dart';
import 'package:banda/features/funds/views/fund_editor.dart';
import 'package:banda/features/funds/views/fund_entries.dart';
import 'package:banda/features/funds/views/fund_entry_editor.dart';
import 'package:banda/features/funds/views/fund_filter.dart';
import 'package:banda/features/funds/views/fund_menu.dart';
import 'package:banda/features/funds/views/funds.dart';
import 'package:banda/features/tags/views/party_selector.dart';
import 'package:banda/features/transfers/views/transfer_editor.dart';
import 'package:banda/features/transfers/views/transfer_entries.dart';
import 'package:banda/features/transfers/views/transfer_menu.dart';
import 'package:banda/features/transfers/views/transfers.dart';
import 'package:banda/features/tags/views/category_selector.dart';
import 'package:banda/features/main/views/information.dart';
import 'package:banda/features/tags/views/label_selector.dart';
import 'package:banda/features/loans/views/loan_editor.dart';
import 'package:banda/features/loans/views/loan_filter.dart';
import 'package:banda/features/loans/views/loan_menu.dart';
import 'package:banda/features/loans/views/loan_entry_editor.dart';
import 'package:banda/features/loans/views/loan_entries.dart';
import 'package:banda/features/loans/views/loans.dart';
import 'package:banda/features/main/views/main_menu.dart';
import 'package:banda/features/main/views/tools.dart';
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
      case '/bills':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Bills(),
        );
      case '/bills/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => BillEditor(),
        );
      case '/bills/filter':
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
      case '/accounts':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Accounts(),
        );
      case '/accounts/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => AccountEditor(),
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
        case 'bills':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => BillEditor(id: id),
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
        case 'accounts':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => AccountEditor(id: id),
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
        case 'accounts':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => AccountMenu(id: id),
          );
        case 'loans':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => LoanMenu(id: id),
          );
        case 'bills':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => BillMenu(id: id),
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
        case 'funds':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FundEntries(fundId: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 && uri.pathSegments.last == "history") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'bills':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => BillHistory(id: id),
          );
      }
    }

    if (uri.pathSegments.length == 3 && uri.pathSegments.last == "entries") {
      final id = uri.pathSegments[1];

      switch (uri.pathSegments.first) {
        case 'funds':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FundEntries(fundId: id),
          );
        case 'accounts':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => AccountEntries(id: id),
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
        case 'bills':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => BillEditor(id: id, readOnly: true),
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
        case 'accounts':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => AccountEditor(id: id, readOnly: true),
          );
        case 'transfers':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => TransferEditor(id: id, readOnly: true),
          );
        case 'funds':
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FundEditor(id: id, readOnly: true),
          );
      }
    }

    if (uri.pathSegments.length == 4) {
      if (uri.pathSegments.first == "funds" &&
          uri.pathSegments[2] == "transactions" &&
          uri.pathSegments[3] == "new") {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => FundEntryEditor(fundId: uri.pathSegments[1]),
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
