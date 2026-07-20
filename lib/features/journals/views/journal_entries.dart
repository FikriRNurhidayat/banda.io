import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/journals/widgets/journal_tile.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JournalEntries extends StatelessWidget {
  final String id;
  const JournalEntries({super.key, required this.id});

  handleMenuTap(BuildContext context) {
    Navigator.of(context).pushNamed("/journals/$id/menu");
  }

  handleTap(BuildContext context) {
    Navigator.of(context).pushNamed("/journals/$id/detail");
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text("Journal", style: theme.textTheme.titleMedium),
      automaticallyImplyLeading: false,
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

  entriesBuilder(BuildContext context, Journal journal) {
    final entryProvider = context.watch<EntryProvider>();
    return Expanded(
      child: FutureBuilder(
        future: entryProvider.search(
          specification: {
            "journal_in": [journal.id],
          },
        ),
        builder: futureBuilder<List<Entry>>((context, snapshot) {
          final entries = snapshot.data!;

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              final Entry entry = entries[index];
              return EntryTile(entry);
            },
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journalProvider = context.watch<JournalProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: journalProvider.get(id),
        builder: futureBuilder((context, snapshot) {
          final journal = snapshot.data! as Journal;

          return Column(
            children: [
              JournalTile(journal, readOnly: true),
              Divider(height: 1),
              entriesBuilder(context, journal),
            ],
          );
        }),
      ),
    );
  }
}
