import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/features/pools/views/pool_filter.dart';
import 'package:bandha/features/pools/providers/pool_filter_provider.dart';
import 'package:bandha/features/pools/providers/pool_provider.dart';
import 'package:bandha/features/pools/widgets/pool_tile.dart';
import 'package:flutter/foundation.dart';
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PoolFilter(specs: filterProvider.get()),
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
    final poolProvider = context.watch<PoolProvider>();
    final filterProvider = context.watch<PoolFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pools",
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: poolProvider.search(filterProvider.get()),
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
                final Pool pool = snapshot.data![index];
                return PoolTile(pool);
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
        Navigator.pushNamed(context, "/pools/new");
      },
    );
  }
}
