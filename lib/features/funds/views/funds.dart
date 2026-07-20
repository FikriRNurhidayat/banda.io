import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/features/funds/providers/fund_filter_provider.dart';
import 'package:bandha/features/funds/providers/fund_provider.dart';
import 'package:bandha/features/funds/widgets/fund_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Funds extends StatelessWidget {
  const Funds({super.key});

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<FundFilterProvider>();
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
            "/funds/filter",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.search),
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/funds/insights",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.insights),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fundProvider = context.watch<FundProvider>();
    final filterProvider = context.watch<FundFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Funds", style: theme.textTheme.titleMedium),
        actions: actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: fundProvider.search(filterProvider.get()),
        builder: futureBuilder((context, snapshot) {
          final funds = snapshot.data as List<Fund>;

          return SafeArea(
            child: ListView.builder(
              itemCount: funds.length,
              itemBuilder: (BuildContext context, int index) {
                final Fund fund = funds[index];
                return FundTile(fund);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/funds/new");
      },
    );
  }
}
