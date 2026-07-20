import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/features/obligations/providers/obligation_filter_provider.dart';
import 'package:bandha/features/obligations/providers/obligation_provider.dart';
import 'package:bandha/features/obligations/widgets/obligation_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Obligations extends StatefulWidget {
  const Obligations({super.key});

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<ObligationFilterProvider>();
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
            "/obligations/filter",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.search),
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/obligations/insights",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.insights),
      ),
    ];
  }

  @override
  State<StatefulWidget> createState() => _ObligationsState();

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/obligations/new");
      },
    );
  }
}

class _ObligationsState extends State<Obligations> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final obligationProvider = context.watch<ObligationProvider>();
    final filterProvider = context.watch<ObligationFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Obligations", style: theme.textTheme.titleMedium),
        actions: widget.actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: widget.fabBuilder(context),
      body: FutureBuilder(
        future: obligationProvider.search(filterProvider.get()),
        builder: futureBuilder((context, snapshot) {
          final obligations = snapshot.data as List<Obligation>;

          return SafeArea(
            child: ListView.builder(
              itemCount: obligations.length,
              itemBuilder: (BuildContext context, int index) {
                final Obligation obligation = obligations[index];
                return ObligationTile(obligation);
              },
            ),
          );
        }),
      ),
    );
  }
}
