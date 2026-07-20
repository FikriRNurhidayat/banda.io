import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/journals/providers/journal_filter_provider.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/journals/widgets/journal_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Journals extends StatelessWidget {
  const Journals({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journalProvider = context.watch<JournalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Journals", style: theme.textTheme.titleMedium),
        actionsPadding: EdgeInsets.all(8),
        actions: actionsBuilder(context),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: journalProvider.search(),
        builder: futureBuilder((context, snapshot) {
          final journals = snapshot.data as List<Journal>;
          return ListView.builder(
            itemCount: journals.length,
            itemBuilder: (BuildContext context, int index) {
              final Journal journal = journals[index];
              return JournalTile(journal);
            },
          );
        }),
      ),
    );
  }

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<JournalFilterProvider>();
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
            "/journals/filter",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.search),
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/journals/insights",
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
        Navigator.pushNamed(context, "/journals/new");
      },
    );
  }
}
