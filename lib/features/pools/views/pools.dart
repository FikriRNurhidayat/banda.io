import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/features/pools/providers/pool_filter_provider.dart';
import 'package:bandha/features/pools/providers/pool_provider.dart';
import 'package:bandha/features/pools/widgets/pool_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Pools extends StatelessWidget {
  const Pools({super.key});

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<PoolFilterProvider>();
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
            "/pools/filter",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.search),
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/pools/insights",
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
    final poolProvider = context.watch<PoolProvider>();
    final filterProvider = context.watch<PoolFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Pools", style: theme.textTheme.titleMedium),
        actions: actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: poolProvider.search(filterProvider.get()),
        builder: futureBuilder((context, snapshot) {
          final pools = snapshot.data as List<Pool>;

          return SafeArea(
            child: ListView.builder(
              itemCount: pools.length,
              itemBuilder: (BuildContext context, int index) {
                final Pool pool = pools[index];
                return PoolTile(pool);
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
        Navigator.pushNamed(context, "/pools/new");
      },
    );
  }
}
