import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/features/funds/providers/fund_provider.dart';
import 'package:bandha/features/funds/widgets/fund_tile.dart';
import 'package:bandha/features/funds/widgets/entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FundEntries extends StatelessWidget {
  final String fundId;
  const FundEntries({super.key, required this.fundId});

  handlePlus(BuildContext context) {
    Navigator.pushNamed(context, "/funds/$fundId/transactions/new");
  }

  handleMore(BuildContext context) {
    Navigator.of(context).pushNamed("/funds/$fundId/menu");
  }

  appBarBuilder(BuildContext context, Fund fund) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("Fund", style: theme.textTheme.titleLarge),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            handleMore(context);
          },
          icon: Icon(Icons.more_horiz),
        ),
      ],
      actionsPadding: EdgeInsets.all(8.0),
    );
  }

  fabBuilder(BuildContext context, Fund fund) {
    if (!fund.canGrow) return null;

    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        handlePlus(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fundProvider = context.watch<FundProvider>();

    return FutureBuilder(
      future: fundProvider.get(fundId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("...")));
        }

        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Icon(
                Icons.dashboard_customize_outlined,
                size: theme.textTheme.displayLarge!.fontSize,
              ),
            ),
          );
        }

        final fund = snapshot.data!;

        return Scaffold(
          appBar: appBarBuilder(context, fund),
          floatingActionButton: fabBuilder(context, fund),
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                FundTile(fund, readOnly: true),
                Divider(height: 1),
                FutureBuilder(
                  future: fundProvider.searchTransactions(fundId: fund.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("..."));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Expanded(
                        child: Center(
                          child: Icon(
                            Icons.dashboard_customize_outlined,
                            size: theme.textTheme.displayLarge!.fontSize,
                          ),
                        ),
                      );
                    }

                    final entries = snapshot.data!;

                    return Expanded(
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Entry entry = entries[index];
                          return EntryTile(fund, entry);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
