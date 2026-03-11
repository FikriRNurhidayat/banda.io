import 'package:banda/common/helpers/future_helper.dart';
import 'package:banda/features/bills/entities/bill.dart';
import 'package:banda/features/bills/providers/bill_provider.dart';
import 'package:banda/features/bills/widgets/bill_tile.dart';
import 'package:banda/features/bills/widgets/entry_tile.dart';
import 'package:banda/features/entries/entities/entry.dart';
import 'package:banda/features/entries/providers/entry_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BillHistory extends StatelessWidget {
  final String id;

  const BillHistory({super.key, required this.id});

  handleMore(BuildContext context) {
    Navigator.pushNamed(context, "/bills/$id/menu");
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("Bill History", style: theme.textTheme.titleLarge),
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

  entriesBuilder(BuildContext context, Bill bill) {
    final entryProvider = context.watch<EntryProvider>();

    return Expanded(
      child: FutureBuilder(
        future: entryProvider.getByController(bill),
        builder: futureBuilder((context, snapshot) {
          final entries = snapshot.data! as List<Entry>;

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return EntryTile(entry, readOnly: true);
            },
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: billProvider.get(id),
        builder: futureBuilder((context, snapshot) {
          final bill = snapshot.data! as Bill;

          return Column(
            children: [
              BillTile(bill, readOnly: true),
              Divider(height: 1),
              entriesBuilder(context, bill),
            ],
          );
        }),
      ),
    );
  }
}
