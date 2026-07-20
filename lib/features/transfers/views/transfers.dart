import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/providers/transfer_filter_provider.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/features/transfers/widgets/transfer_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Transfers extends StatelessWidget {
  const Transfers({super.key});

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<TransferFilterProvider>();
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
            "/transfers/filter",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.search),
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/transfers/insights",
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
        Navigator.pushNamed(context, "/transfers/new");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transferProvider = context.watch<TransferProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Transfers", style: theme.textTheme.titleMedium),
        actions: actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: transferProvider.search(),
        builder: futureBuilder((context, snapshot) {
          final transfers = snapshot.data as List<Transfer>;

          return ListView.separated(
            itemCount: transfers.length,
            separatorBuilder: (_, __) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final Transfer transfer = transfers[index];
              return TransferTile(transfer);
            },
          );
        }),
      ),
    );
  }
}
