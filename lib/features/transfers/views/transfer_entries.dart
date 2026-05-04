import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/features/transfers/widgets/transfer_tile.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransferEntries extends StatelessWidget {
  final String id;
  const TransferEntries({super.key, required this.id});

  handleMenuTap(BuildContext context) {
    Navigator.of(context).pushNamed("/transfers/$id/menu");
  }

  transferBuilder(BuildContext context, Transfer transfer) {
    return TransferTile(transfer, readOnly: true);
  }

  appBarBuilder(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Transfer",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
      ),

      actions: [
        IconButton(
          onPressed: () {
            handleMenuTap(context);
          },
          icon: Icon(Icons.more_horiz),
        ),
      ],
      actionsPadding: EdgeInsets.all(8.0),
    );
  }

  entriesBuilder(BuildContext context, Transfer transfer) {
    final entryProvider = context.watch<EntryProvider>();

    return FutureBuilder(
      future: entryProvider.getByController(transfer),
      builder: futureBuilder<List<Entry>>((context, snapshot) {
        final entries = snapshot.data!;

        return Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              final Entry entry = entries[index];
              return EntryTile(entry, readOnly: true);
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.watch<TransferProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: transferProvider.get(id),
        builder: futureBuilder((context, snapshot) {
          final transfer = snapshot.data! as Transfer;

          return Column(
            children: [
              transferBuilder(context, transfer),
              Divider(height: 1),
              entriesBuilder(context, transfer),
            ],
          );
        }),
      ),
    );
  }
}
