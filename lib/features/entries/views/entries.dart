import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/entries/providers/entry_filter_provider.dart';
import 'package:bandha/features/entries/widgets/entry_tile.dart';
import 'package:flutter/material.dart';
import "package:provider/provider.dart";

class Entries extends StatelessWidget {
  const Entries({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryProvider = context.watch<EntryProvider>();
    final filterProvider = context.watch<EntryFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Entries", style: theme.textTheme.titleLarge),
        actions: actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: entryProvider.search(
          specification: filterProvider.get(),
        ),
        builder: futureBuilder((context, snapshot) {
          final entries = snapshot.data as List<Entry>;

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

  static String title = "Entries";
  static IconData icon = Icons.book;

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<EntryFilterProvider>();
    final filter = filterProvider.get();

    return [
      if (filter != null)
        IconButton(
          onPressed: () {
            filterProvider.reset();
          },
          icon: Icon(Icons.close),
        ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/entries/filter",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.search),
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/entries/insights",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.insights),
      ),
    ];
  }

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/entries/new");
      },
    );
  }
}
