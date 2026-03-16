import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/commitments/entities/commitment_payment.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/commitments/providers/commitment_payment_provider.dart';
import 'package:bandha/features/commitments/providers/commitment_provider.dart';
import 'package:bandha/features/commitments/widgets/payment_tile.dart';
import 'package:bandha/features/commitments/widgets/commitment_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommitmentEntries extends StatefulWidget {
  final String id;

  const CommitmentEntries({super.key, required this.id});

  @override
  State<CommitmentEntries> createState() => _CommitmentEntriesState();
}

class _CommitmentEntriesState extends State<CommitmentEntries>
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
    Navigator.of(context).pushNamed("/commitments/${widget.id}/menu");
  }

  fabBuilder(BuildContext context, Commitment commitment) {
    if (commitment.status.isSettled) return null;

    return FloatingActionButton(
      onPressed: () {
        Navigator.of(
          context,
        ).pushNamed("/commitments/${widget.id}/payments/new");
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
      title: Text("Commitment", style: theme.textTheme.titleLarge),
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

  tabBuilder(Commitment commitment) {
    final commitmentPaymentProvider = context.watch<CommitmentPaymentProvider>();
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
              future: commitmentPaymentProvider.search(widget.id),
              builder: futureBuilder((context, snapshot) {
                final payments = snapshot.data as List<CommitmentPayment>;

                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final payment = payments[index];
                    return PaymentTile(payment: payment, commitment: commitment);
                  },
                );
              }),
            ),
            FutureBuilder(
              future: entryProvider.getByController(commitment),
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
    final commitmentProvider = context.watch<CommitmentProvider>();

    return FutureBuilder(
      future: commitmentProvider.get(widget.id),
      builder: futureBuilder((context, snapshot) {
        final commitment = snapshot.data as Commitment;

        if (kDebugMode) {
          print("commitment.amount: ${commitment.amount}");
          print("commitment.remainder: ${commitment.remainder}");
        }

        return Scaffold(
          appBar: appBarBuilder(context),
          floatingActionButton: fabBuilder(context, commitment),
          body: Column(
            children: [
              CommitmentTile(commitment, readOnly: true),
              ...tabBuilder(commitment),
            ],
          ),
        );
      }),
    );
  }
}
