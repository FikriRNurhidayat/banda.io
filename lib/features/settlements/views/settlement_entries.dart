import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:bandha/features/settlements/entities/settlement.dart';
import 'package:bandha/features/settlements/entities/settlement_payment.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/settlements/providers/settlement_payment_provider.dart';
import 'package:bandha/features/settlements/providers/settlement_provider.dart';
import 'package:bandha/features/settlements/widgets/payment_tile.dart';
import 'package:bandha/features/settlements/widgets/settlement_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettlementEntries extends StatefulWidget {
  final String id;

  const SettlementEntries({super.key, required this.id});

  @override
  State<SettlementEntries> createState() => _SettlementEntriesState();
}

class _SettlementEntriesState extends State<SettlementEntries>
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
    Navigator.of(context).pushNamed("/settlements/${widget.id}/menu");
  }

  fabBuilder(BuildContext context, Settlement settlement) {
    if (settlement.status.isSettled) return null;

    return FloatingActionButton(
      onPressed: () {
        Navigator.of(
          context,
        ).pushNamed("/settlements/${widget.id}/payments/new");
      },
      child: Icon(Icons.add),
    );
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text("Settlement", style: theme.textTheme.titleMedium),
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

  tabBuilder(Settlement settlement) {
    final settlementPaymentProvider = context
        .watch<SettlementPaymentProvider>();
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
              future: settlementPaymentProvider.search(widget.id),
              builder: futureBuilder((context, snapshot) {
                final payments =
                    snapshot.data as List<SettlementPayment>;

                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final payment = payments[index];
                    return PaymentTile(
                      payment: payment,
                      settlement: settlement,
                    );
                  },
                );
              }),
            ),
            FutureBuilder(
              future: entryProvider.getByController(settlement),
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
    final settlementProvider = context.watch<SettlementProvider>();

    return FutureBuilder(
      future: settlementProvider.get(widget.id),
      builder: futureBuilder((context, snapshot) {
        final settlement = snapshot.data as Settlement;

        return Scaffold(
          appBar: appBarBuilder(context),
          floatingActionButton: fabBuilder(context, settlement),
          body: Column(
            children: [
              SettlementTile(settlement, readOnly: true),
              ...tabBuilder(settlement),
            ],
          ),
        );
      }),
    );
  }
}
