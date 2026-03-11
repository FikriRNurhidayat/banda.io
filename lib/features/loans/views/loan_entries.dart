import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/entries/providers/entry_provider.dart';
import 'package:banda/features/entries/widgets/entry_tile.dart';
import 'package:banda/features/loans/entities/loan.dart';
import 'package:banda/features/loans/entities/loan_payment.dart';
import 'package:banda/common/helpers/future_helper.dart';
import 'package:banda/features/loans/providers/loan_payment_provider.dart';
import 'package:banda/features/loans/providers/loan_provider.dart';
import 'package:banda/features/loans/widgets/payment_tile.dart';
import 'package:banda/features/loans/widgets/loan_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoanEntries extends StatefulWidget {
  final String id;

  const LoanEntries({super.key, required this.id});

  @override
  State<LoanEntries> createState() => _LoanEntriesState();
}

class _LoanEntriesState extends State<LoanEntries>
    with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
  }

  handleMore(BuildContext context) {
    Navigator.of(context).pushNamed("/loans/${widget.id}/menu");
  }

  fabBuilder(BuildContext context, Loan loan) {
    if (loan.status.isSettled) return null;

    return FloatingActionButton(
      onPressed: () {
        Navigator.of(
          context,
        ).pushNamed("/loans/${widget.id}/payments/new");
      },
      child: Icon(Icons.add),
    );
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("Loan", style: theme.textTheme.titleLarge),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            handleMore(context);
          },
          icon: Icon(Icons.more_horiz),
        ),
      ],
      actionsPadding: EdgeInsets.all(8),
    );
  }

  tabBuilder(Loan loan) {
    final loanPaymentProvider = context.watch<LoanPaymentProvider>();
    final entryProvider = context.watch<EntryProvider>();

    return [
      TabBar(
        controller: tabController,
        tabs: [
          Tab(text: "Payments"),
          Tab(text: "Entries"),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: tabController,
          children: [
            FutureBuilder(
              future: loanPaymentProvider.search(widget.id),
              builder: futureBuilder((context, snapshot) {
                final payments = snapshot.data as List<LoanPayment>;

                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final payment = payments[index];
                    return PaymentTile(payment: payment, loan: loan);
                  },
                );
              }),
            ),
            FutureBuilder(
              future: entryProvider.getByController(loan),
              builder: futureBuilder((context, snapshot) {
                final entries = snapshot.data as List<Entry>;

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (BuildContext context, int index) {
                    final entry = entries[index];
                    return EntryTile(entry, readOnly: true);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = context.watch<LoanProvider>();

    return FutureBuilder(
      future: loanProvider.get(widget.id),
      builder: futureBuilder((context, snapshot) {
        final loan = snapshot.data as Loan;

        return Scaffold(
          appBar: appBarBuilder(context),
          floatingActionButton: fabBuilder(context, loan),
          body: Column(
            children: [
              LoanTile(loan, readOnly: true),
              ...tabBuilder(loan),
            ],
          ),
        );
      }),
    );
  }
}
