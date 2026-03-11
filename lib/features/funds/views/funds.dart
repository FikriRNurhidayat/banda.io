import 'package:banda/features/funds/entities/fund.dart';
import 'package:banda/features/funds/views/fund_filter.dart';
import 'package:banda/features/funds/providers/fund_filter_provider.dart';
import 'package:banda/features/funds/providers/fund_provider.dart';
import 'package:banda/features/funds/widgets/fund_tile.dart';
import 'package:flutter/foundation.dart';
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FundFilter(specs: filterProvider.get()),
            ),
          );
        },
        icon: Icon(Icons.search),
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
        title: Text(
          "Funds",
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: fundProvider.search(filterProvider.get()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (kDebugMode) {
              print(snapshot.error);
              print(snapshot.stackTrace);
            }

            return Center(child: Text("..."));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Icon(
                Icons.dashboard_customize_outlined,
                size: theme.textTheme.displayLarge!.fontSize,
              ),
            );
          }

          return SafeArea(
            child: ListView.builder(
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final Fund fund = snapshot.data![index];
                return FundTile(fund);
              },
            ),
          );
        },
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
