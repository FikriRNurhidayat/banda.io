import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/settlements/entities/settlement.dart';
import 'package:bandha/features/settlements/providers/settlement_filter_provider.dart';
import 'package:bandha/features/settlements/providers/settlement_provider.dart';
import 'package:bandha/features/settlements/widgets/settlement_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settlements extends StatefulWidget {
  const Settlements({super.key});

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<SettlementFilterProvider>();
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
            "/settlements/filter",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.search),
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/settlements/insights",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.insights),
      ),
    ];
  }

  @override
  State<StatefulWidget> createState() => _SettlementsState();

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/settlements/new");
      },
    );
  }
}

class _SettlementsState extends State<Settlements> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settlementProvider = context.watch<SettlementProvider>();
    final filterProvider = context.watch<SettlementFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Settlements", style: theme.textTheme.titleMedium),
        actions: widget.actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: widget.fabBuilder(context),
      body: FutureBuilder(
        future: settlementProvider.search(filterProvider.get()),
        builder: futureBuilder((context, snapshot) {
          final settlements = snapshot.data as List<Settlement>;

          return SafeArea(
            child: ListView.builder(
              itemCount: settlements.length,
              itemBuilder: (BuildContext context, int index) {
                final Settlement settlement = settlements[index];
                return SettlementTile(settlement);
              },
            ),
          );
        }),
      ),
    );
  }
}
