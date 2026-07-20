import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/features/obligations/entities/obligation_payment.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/obligations/providers/obligation_payment_provider.dart';
import 'package:bandha/features/obligations/providers/obligation_provider.dart';
import 'package:bandha/features/obligations/widgets/payment_tile.dart';
import 'package:bandha/features/obligations/widgets/obligation_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ObligationEntries extends StatefulWidget {
  final String id;

  const ObligationEntries({super.key, required this.id});

  @override
  State<ObligationEntries> createState() => _ObligationEntriesState();
}

class _ObligationEntriesState extends State<ObligationEntries>
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
    Navigator.of(context).pushNamed("/obligations/${widget.id}/menu");
  }

  fabBuilder(BuildContext context, Obligation obligation) {
    if (obligation.status.isSettled) return null;

    return FloatingActionButton(
      onPressed: () {
        Navigator.of(
          context,
        ).pushNamed("/obligations/${widget.id}/payments/new");
      },
      child: Icon(Icons.add),
    );
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text("Obligation", style: theme.textTheme.titleMedium),
      automaticallyImplyLeading: false,
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

  tabBuilder(Obligation obligation) {
    final obligationPaymentProvider = context
        .watch<ObligationPaymentProvider>();
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
              future: obligationPaymentProvider.search(widget.id),
              builder: futureBuilder((context, snapshot) {
                final payments =
                    snapshot.data as List<ObligationPayment>;

                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final payment = payments[index];
                    return PaymentTile(
                      payment: payment,
                      obligation: obligation,
                    );
                  },
                );
              }),
            ),
            FutureBuilder(
              future: entryProvider.getByController(obligation),
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
    final obligationProvider = context.watch<ObligationProvider>();

    return FutureBuilder(
      future: obligationProvider.get(widget.id),
      builder: futureBuilder((context, snapshot) {
        final obligation = snapshot.data as Obligation;

        return Scaffold(
          appBar: appBarBuilder(context),
          floatingActionButton: fabBuilder(context, obligation),
          body: Column(
            children: [
              ObligationTile(obligation, readOnly: true),
              ...tabBuilder(obligation),
            ],
          ),
        );
      }),
    );
  }
}
