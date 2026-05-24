import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/features/pools/providers/pool_provider.dart';
import 'package:bandha/features/pools/widgets/pool_tile.dart';
import 'package:bandha/features/pools/widgets/entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PoolEntries extends StatelessWidget {
  final String poolId;
  const PoolEntries({super.key, required this.poolId});

  handlePlus(BuildContext context) {
    Navigator.pushNamed(context, "/pools/$poolId/transactions/new");
  }

  handleMore(BuildContext context) {
    Navigator.of(context).pushNamed("/pools/$poolId/menu");
  }

  appBarBuilder(BuildContext context, Pool pool) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text("Pool", style: theme.textTheme.titleMedium),
      actions: [
        IconButton(
          onPressed: () {
            handleMore(context);
          },
          icon: Icon(Icons.more_horiz),
        ),
      ],
      actionsPadding: EdgeInsets.all(8.0),
      automaticallyImplyLeading: false,
    );
  }

  fabBuilder(BuildContext context, Pool pool) {
    if (!pool.canGrow) return null;

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
    final poolProvider = context.watch<PoolProvider>();

    return FutureBuilder(
      future: poolProvider.get(poolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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

        final pool = snapshot.data!;

        return Scaffold(
          appBar: appBarBuilder(context, pool),
          floatingActionButton: fabBuilder(context, pool),
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                PoolTile(pool, readOnly: true),
                Divider(height: 1),
                FutureBuilder(
                  future: poolProvider.searchTransactions(
                    poolId: pool.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
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
                            size:
                                theme.textTheme.displayLarge!.fontSize,
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
                          return EntryTile(pool, entry);
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
