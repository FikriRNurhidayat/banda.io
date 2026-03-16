import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/features/transfers/widgets/transfer_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Transfers extends StatefulWidget {
  const Transfers({super.key});

  @override
  State<StatefulWidget> createState() => _TransfersState();

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/transfers/new");
      },
    );
  }
}

class _TransfersState extends State<Transfers> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transferProvider = context.watch<TransferProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Transfers",
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actionsPadding: EdgeInsets.all(8),
      ),
      floatingActionButton: widget.fabBuilder(context),
      body: FutureBuilder(
        future: transferProvider.search(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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

          return ListView.separated(
            itemCount: snapshot.data?.length ?? 0,
            separatorBuilder: (_, __) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final Transfer transfer = snapshot.data![index];
              return TransferTile(transfer);
            },
          );
        },
      ),
    );
  }
}
